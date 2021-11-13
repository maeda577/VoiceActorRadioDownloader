Import-Module -Force -Name $PSScriptRoot/Common.psm1

function Get-EpisodeInfoFromPlaylist {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ProgramId,
        [Parameter(Mandatory = $true)]
        [String]
        $EpisodeId,
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    # 一旦プレイリストに入れてから一覧を取得し外す(プレイリスト経由だと得られる情報がちょっと増えるため)
    $postPlaylist = @{ "program_id" = $ProgramId; "episode_id" = $EpisodeId }
    $response = Invoke-RestMethod -Method Post -Uri "https://agonp.jp/api/v2/playlists/add_episode/0.json" -Body $postPlaylist -WebSession $WebSession
    if ([System.String]::IsNullOrWhiteSpace($response.data.error) -eq $false ) {
        Write-Error -Message $response.data.error
    }
    $playlists = Invoke-RestMethod -Uri "https://agonp.jp/api/v2/episodes/others.json?in_playlist=1" -WebSession $WebSession
    $response = Invoke-RestMethod -Method Post -Uri "https://agonp.jp/api/v2/playlists/remove_episode/0.json" -Body $postPlaylist -WebSession $WebSession
    if ([System.String]::IsNullOrWhiteSpace($response.data.error) -eq $false ) {
        Write-Error -Message $response.data.error
    }
    return $playlists.data.episodes | Where-Object -Property id -EQ $EpisodeId
}

function Get-EpisodeIds {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ProgramId,
        [Parameter()]
        [int]
        $Page = 1
    )
    # 番組情報ページ
    $programPage = Invoke-WebRequest -Uri "https://agonp.jp/programs/view/$($Program.ProgramId)?page=$Page" -UseBasicParsing

    # 番組内の各放送ID
    $episodeIds = $programPage.Links |
        Where-Object -FilterScript { $null -ne $_.href -and $_.href.StartsWith("/play/") } |
        ForEach-Object -Process { $_.href -split '/' | Select-Object -Last 1 } |
        Sort-Object -Descending -Unique

    # 次のページへのリンクがあるか
    $nextPage = $programPage.Links |
        Where-Object -FilterScript { $null -ne $_.href -and $_.href.StartsWith("/programs/view/$($Program.ProgramId)?page=") } |
        ForEach-Object -Process { $_.href -split '=' | Select-Object -Last 1 } |
        Where-Object -FilterScript { $_ -gt $Page } |
        Sort-Object |
        Select-Object -First 1

    # 次のページがあれば再帰呼び出しする
    if ($null -ne $nextPage) {
        return $episodeIds + (Get-EpisodeIds -ProgramId $ProgramId -Page $nextPage)
    }
    else {
        return $episodeIds
    }
}

function Invoke-DownloadAgonp {
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'Password')]
    Param(
        # ダウンロードする放送情報
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $Program,
        # ローカル側の保存先ルートディレクトリ
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $DestinationPath,
        # ログインIDのメールアドレス
        [Parameter(mandatory = $true)]
        [String]
        $Email,
        # ログインパスワード
        [Parameter(mandatory = $true)]
        [String]
        $Password,
        # ローカル側の保存先サブディレクトリにつけるプレフィクス
        [Parameter()]
        [String]
        $DirectoryPrefix = "agonp_",
        # ffmpegのパス
        [Parameter()]
        [String]
        $FfmpegPath = "ffmpeg"
    )
    begin{
        # ログイン処理
        # デフォルトのUserAgentだとmp4のダウンロードで失敗する(CloudFront側でエラー返される)のでChromeを明示する
        $postBody = @{ "email" = $Email; "password" = $Password }
        $response = Invoke-WebRequest -Method Post -Uri "https://agonp.jp/auth/login" -Body $postBody -SessionVariable webSession -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)
        if ($response.StatusCode -ne 200) {
            Write-Error -Message $response.StatusDescription
        }
    }
    process {
        # サブディレクトリを切る
        $outputSubDir = New-DirectoryIfNotExists -ParentDirectory $DestinationPath -DirectoryName ($DirectoryPrefix + $Program.ProgramId) -WhatIf:$WhatIfPreference
        # 各回放送のID
        $episodeIds = Get-EpisodeIds -ProgramId $Program.ProgramId

        foreach ($episodeId in $episodeIds) {
            # 放送情報
            $episodeInfo = Invoke-RestMethod -Uri "https://agonp.jp/api/v2/episodes/info/$episodeId.json"
            # MP4のURL
            $mediaInfo = Invoke-RestMethod -Uri "https://agonp.jp/api/v2/media/info.json?id=$($episodeInfo.data.episode.video_id)&size=$($Program.Size)&type=$($Program.Type)" -WebSession $webSession

            # オーディオファイルのファイル名とフルパス
            $audioFileName = [System.IO.Path]::GetFileName($mediaInfo.data.url)
            $audioFileFullPath = Join-Path -Path $outputSubDir.FullName -ChildPath $audioFileName
            # ファイルが無ければダウンロード
            $isAudioDownloaded = Invoke-DownloadItemIfNotExists -Uri $mediaInfo.data.url -OutFile $audioFileFullPath -WebSession $webSession -WhatIf:$WhatIfPreference

            # タグ付与
            if ($isAudioDownloaded) {
                # プレイリスト経由で放送の追加情報を取得
                $episodeInfoPL = Get-EpisodeInfoFromPlaylist -ProgramId $Program.ProgramId -EpisodeId $episodeId -WebSession $webSession

                # 公開日(UTCとJST)
                $publishDateUTC = [System.DateTimeOffset]::FromUnixTimeSeconds($episodeInfoPL.will_published_from)
                $publishDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($publishDateUTC, "Asia/Tokyo")

                # タグ書き込み後のオーディオファイルを置く一時ファイル
                $tempAudioFileFullPath = Join-Path -Path $outputSubDir.FullName -ChildPath "temp_$audioFileName"
                # ffmpegの引数
                $ffmepgArgs = @(
                    "-i", $audioFileFullPath, #input file url
                    "-loglevel", "error", #Show all errors, including ones which can be recovered from.
                    "-c", "copy",
                    "-metadata", "artist=`"$($episodeInfo.data.episode.participant_names)`"",
                    "-metadata", "album=`"$($episodeInfoPL.program_title)`"",
                    "-metadata", "genre=`"Web Radio`"",
                    "-metadata", "date=`"$($publishDate.Year)`"",
                    "-metadata", "creation_time=`"$($publishDate.ToString('u'))`"",
                    "-metadata", "comment=`"$($episodeInfo.data.episode.description)`"",
                    "-metadata", "title=`"$($episodeInfo.data.episode.title)`"",
                    "`"$tempAudioFileFullPath`""   # 出力ファイルのフルパス
                )
                if ($PSCmdlet.ShouldProcess($audioFileFullPath, "Update")) {
                    # ffmpeg実行
                    Start-Process -FilePath $ffmpegPath -ArgumentList $ffmepgArgs -Wait
                    # タグ付きファイルを元ファイルに上書きする
                    Move-Item -Path $tempAudioFileFullPath -Destination $audioFileFullPath -Force
                }
            }
            # 画像ファイルのファイル名とフルパス
            $imageFileName = [System.IO.Path]::GetFileNameWithoutExtension($mediaInfo.data.url) + [System.IO.Path]::GetExtension($episodeInfo.data.episode.main_image_url)
            $imageFileFullPath = Join-Path -Path $outputSubDir.FullName -ChildPath $imageFileName
            # ファイルが無ければダウンロード
            $null = Invoke-DownloadItemIfNotExists -Uri $episodeInfo.data.episode.main_image_url -OutFile $imageFileFullPath -WhatIf:$WhatIfPreference
        }

        # 最新話の画像をカバー画像として使う
        $latestEpisodeId = ($episodeIds | Measure-Object -Maximum).Maximum
        $latestEpisodeInfoPL = Get-EpisodeInfoFromPlaylist -ProgramId $Program.ProgramId -EpisodeId $latestEpisodeId -WebSession $webSession
        $coverImageFileName = [System.IO.Path]::GetFileName($latestEpisodeInfoPL.program_main_image_url)
        $coverImageFileFullPath = Join-Path -Path $outputSubDir.FullName -ChildPath $coverImageFileName
        $null = Invoke-DownloadItemIfNotExists -Uri $latestEpisodeInfoPL.program_main_image_url -OutFile $coverImageFileFullPath -WhatIf:$WhatIfPreference

        # 放送情報を保存
        Set-PodcastInfoFile -DestinationDirectory $outputSubDir.FullName `
            -Title $latestEpisodeInfoPL.program_title `
            -ImageFileName $coverImageFileName `
            -SiteUri "https://agonp.jp/programs/view/$($Program.ProgramId)"
    }
    end {
        # 終わったら一応ログアウトしておく
        $response = Invoke-WebRequest -Method Get -Uri "https://agonp.jp/auth/logout" -WebSession $webSession
        if ($response.StatusCode -ne 200) {
            Write-Warning -Message $response.StatusDescription
        }
    }
}
