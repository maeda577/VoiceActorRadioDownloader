Import-Module -Force -Name $PSScriptRoot/Common.psm1
$postHeaders = @{
    'Access-Control-Allow-Origin' = '*';
    'Content-Type'                = 'application/json; charset=utf-8';
    'X-Client'                    = 'onsen-web';
}

$culture = [System.Globalization.CultureInfo]::GetCultureInfo("ja-jp")

function Connect-OnsenPremium {
    param (
        [Parameter(mandatory = $true)]
        [String]
        $Email,

        [Parameter(mandatory = $true)]
        [String]
        $Password
    )
    process {
        $postData = @{"session" = @{ "email" = $Email; "password" = $Password } } | ConvertTo-Json -Compress
        $postDataUtf8 = [System.Text.Encoding]::UTF8.GetBytes($postData)
        $response = Invoke-RestMethod -Method Post -Uri "https://www.onsen.ag/web_api/signin" -Headers $postHeaders -Body $postDataUtf8 -SessionVariable session
        if ($response.error) {
            Write-Error $response.error
            return $null
        }
        elseif (!$response.premium) {
            Write-Error "Onsen premium is not subscribed."
            return $null
        }
        return $session
    }
}

function Disconnect-OnsenPremium {
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session
    )
    process {
        Invoke-RestMethod -Method Post -Uri "https://www.onsen.ag/web_api/signout" -Headers $postHeaders -WebSession $Session
    }
}

function Save-OnsenRadio {
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $OnsenDirectoryName,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $DestinationPath,

        [Parameter()]
        [String]
        $FfmpegPath = "ffmpeg",

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session
    )
    process {
        # 放送の詳細情報を取得
        $programUrl = "https://www.onsen.ag/web_api/programs/$OnsenDirectoryName"
        $program = Invoke-RestMethod -Method Get -Uri $programUrl -WebSession $Session

        # サブディレクトリを切る
        $output_sub_dir = Join-Path -Path $destinationPath -ChildPath $OnsenDirectoryName
        if ((Test-Path $output_sub_dir) -eq $false) {
            New-Item -Path $output_sub_dir -ItemType "Directory" > $null
        }

        # 視聴できる放送
        $contents = $program.contents | Where-Object -Property streaming_url -NE $null

        # 放送でループ
        foreach ($content in $contents) {
            Save-OnsenRadioEpisode -Content $content -EpisodeDestinationPath $output_sub_dir -FfmpegPath $FfmpegPath
        }

        # ダウンロードがコケて0byteのデータが残っていたら消す
        Get-ChildItem -Path $output_sub_dir -File | Where-Object { $_.Length -eq 0 } | Remove-Item

        # 放送情報をファイルに書き出す
        Update-OnsenProgramInfo -Program $program -EpisodeDestinationPath $output_sub_dir
    }
}

function Save-OnsenRadioEpisode {
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]
        $Content,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $EpisodeDestinationPath,

        [Parameter()]
        [String]
        $FfmpegPath = "ffmpeg"
    )
    process {
        # 最新放送日時
        $latestPublishDate = [System.DateTimeOffset]::ParseExact($program.current_episode.delivery_date + "+00:00", "yyyy年M月d日(ddd)zzz", $culture)
        # 出演者
        $performers = $program.performers | Select-Object -ExpandProperty "name"

        # 第〇〇回、の数字部分
        $track = (Select-String -InputObject $content.title -Pattern "[0-9]+").Matches[0].Value

        # streamのURLの後ろから2つ目のセグメントがファイル名になっている
        $url_segment = $content.streaming_url -split "/"
        $filename = $url_segment[$url_segment.Length - 2]

        # 最新放送分にはタグを入れる
        if ($content.delivery_date -eq "$($latestPublishDate.Month)/$($latestPublishDate.Day)") {
            $year = $latestPublishDate.Year
            $creation_time = $latestPublishDate.ToString('u') # UTC
            $comment = ($program.current_episode.comments | ForEach-Object { $_.caption + $_.body }) -join "`r`n"
            # 画像もダウンロード
            if ($program.current_episode.update_images[0].image.url) {
                $imagePath = Join-Path -Path $output_sub_dir -ChildPath ($filename.Split(".")[0] + ".png")
                if ((Test-Path $imagePath) -eq $false) {
                    Invoke-WebRequest -Method Get -Uri $program.current_episode.update_images[0].image.url -OutFile $imagePath -UseBasicParsing > $null
                }
            }
        }
        else {
            $year = $null
            $creation_time = $null
            $comment = $null
        }

        # 音声のみの場合は拡張子をm4aにする(.mp4のままだとAppleのPodcastアプリが動画だと解釈してしまう)
        if ($content.media_type -eq "sound") {
            $filename = $filename.Split(".")[0] + ".m4a"
        }

        # 出力ファイルのフルパス
        $fileFullPath = Join-Path -Path $output_sub_dir -ChildPath $filename

        # ffmpegの引数
        $ffmepg_arg = @(
            "-i", "`"$($content.streaming_url)`""     #input file url
            "-loglevel", "error", #Show all errors, including ones which can be recovered from.
            "-acodec", "copy", #Set the audio codec.
            "-vcodec", "copy", #Set the video codec.
            "-bsf:a" , "aac_adtstoasc", #Set bitstream filters for matching streams.
            "-metadata", "artist=`"$(($performers + $content.guests) -join ",")`"",
            "-metadata", "album=`"$($program.program_info.title)`"",
            "-metadata", "track=`"$track`"",
            "-metadata", "genre=`"Web Radio`"",
            "-metadata", "date=`"$year`"",
            "-metadata", "creation_time=`"$creation_time`"",
            "-metadata", "description=`"$($program.program_info.description)`"",
            "-metadata", "comment=`"$comment`"",
            "-metadata", "copyright=`"$($program.program_info.copyright)`"",
            "-metadata", "title=`"$($program.program_info.title) $($content.title)`"", # タイトル
            "`"$fileFullPath`""   # 出力ファイルのフルパス
        )

        # ダウンロード実行
        if ((Test-Path -Path $fileFullPath) -eq $false) {
            Start-Process -FilePath $ffmpegPath -ArgumentList $ffmepg_arg -Wait
        }
    }
}

function Update-OnsenProgramInfo {
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]
        $Program,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $EpisodeDestinationPath
    )
    process {
        # カバー画像のファイル名
        $imageFileName = ($Program.program_info.image.url.Split("=") | Select-Object -Last 1) + ".webp"

        # カバー画像がなければダウンロード
        $imageFullPath = Join-Path -Path $EpisodeDestinationPath -ChildPath $imageFileName
        if ((Test-Path $imageFullPath) -eq $false) {
            Invoke-WebRequest -Uri $Program.program_info.image.url -OutFile $imageFullPath > $null
        }

        $infoFullPath = Join-Path -Path $EpisodeDestinationPath -ChildPath "info.json"

        @{
            "title" = $Program.program_info.title;
            "description" = $Program.program_info.description;
            "image" = $imageFileName;
            "link" = "https://www.onsen.ag/program/$($Program.directory_name)";
            "copyright" = $Program.program_info.copyright;
        } | ConvertTo-Json | Out-File -FilePath $infoFullPath -Encoding UTF8
    }
}
