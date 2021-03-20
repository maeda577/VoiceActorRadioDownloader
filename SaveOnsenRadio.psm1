$postHeaders = @{
    'Access-Control-Allow-Origin' = '*';
    'Content-Type' = 'application/json; charset=utf-8';
    'X-Client' = 'onsen-web';
}

function Connect-OnsenPremium {
    param (
        [Parameter(mandatory = $true)]
        [String]
        $Email,

        [Parameter(mandatory = $true)]
        [String]
        $Password
    )
    $postData = @{"session" = @{ "email" = $Email; "password" = $Password }} | ConvertTo-Json -Compress
    $postDataUtf8 = [System.Text.Encoding]::UTF8.GetBytes($postData)
    $response = Invoke-RestMethod -Method Post -Uri "https://www.onsen.ag/web_api/signin" -Headers $postHeaders -Body $postDataUtf8 -SessionVariable session
    if ($response.error) {
        Write-Error $response.error
        return $null
    }elseif (!$response.premium) {
        Write-Error "Onsen premium is not subscribed."
        return $null
    }
    return $session
}

function Disconnect-OnsenPremium {
    param (
        [Parameter(Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session
    )
    Invoke-RestMethod -Method Post -Uri "https://www.onsen.ag/web_api/signout" -Headers $postHeaders -WebSession $Session
}

function Get-OnsenProgram {
    Param(
        [Parameter(mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $OnsenDirectoryName,

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session
    )
    process {
        $url = "https://www.onsen.ag/web_api/programs/$OnsenDirectoryName"
        return Invoke-RestMethod -Method Get -Uri $url -WebSession $Session
    }
}

function Save-OnsenRadio {
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [String]
        $OnsenDirectoryName,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
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
        $program = Get-OnsenProgram -OnsenDirectoryName $OnsenDirectoryName -Session $Session

        # サブディレクトリを切る
        $output_sub_dir = Join-Path -Path $destinationPath -ChildPath $OnsenDirectoryName
        if (!(Test-Path $output_sub_dir)) {
            New-Item -Path $output_sub_dir -ItemType "Directory"
        }

        # 最新放送日時
        $culture = [System.Globalization.CultureInfo]::GetCultureInfo("ja-jp")
        $date = [System.DateTimeOffset]::ParseExact($program.current_episode.delivery_date + "+00:00", "yyyy年M月d日(ddd)zzz", $culture)
        # 出演者
        $performers = $program.performers | Select-Object -ExpandProperty "name"
        # 視聴できる放送
        $contents = $program.contents | Where-Object -Property streaming_url -NE $null

        # 放送でループ
        foreach ($content in $contents) {
            # 第〇〇回、の数字部分
            $track = (Select-String -InputObject $content.title -Pattern "[0-9]+").Matches[0].Value

            # 最新放送分にはタグを入れる
            if ($content.delivery_date -eq "$($date.Month)/$($date.Day)") {
                $year = $date.Year
                $creation_time = $date.ToString('u')
                $comment = ($program.current_episode.comments | ForEach-Object { $_.caption + $_.body }) -join "`r`n"
            }else {
                $year = $null
                $creation_time = $null
                $comment = $null
            }

            # streamのURLの後ろから2つ目のセグメントがファイル名になっている
            $url_segment = $content.streaming_url -split "/"
            $filename = $url_segment[$url_segment.Length - 2]
            # 音声のみの場合は拡張子をm4aにする(.mp4のままだとAppleのPodcastアプリが動画だと解釈してしまう)
            if ($content.media_type -eq "sound") {
                $filename = $filename.Split(".")[0] + ".m4a"
            }
            # ffmpegの引数
            $ffmepg_arg = @(
                "-i", "`"$($content.streaming_url)`""     #input file url
                "-n",                       #Do not overwrite output files, and exit immediately if a specified output file already exists.
                "-loglevel", "error",       #Show all errors, including ones which can be recovered from.
                "-acodec", "copy",          #Set the audio codec.
                "-vcodec", "copy",          #Set the video codec.
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
                "`"$(Join-Path -Path $output_sub_dir -ChildPath $filename)`""   # 出力ファイルのフルパス
            )

            # ダウンロード実行
            Start-Process -FilePath $ffmpegPath -ArgumentList $ffmepg_arg -Wait
        }

        # ダウンロードがコケて0byteのデータが残っていたら消す
        Get-ChildItem -Path $output_sub_dir -File | Where-Object { $_.Length -eq 0 } | Remove-Item    
    }
}