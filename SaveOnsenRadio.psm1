function Get-OnsenProgram {
    Param(
        [Parameter(mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $OnsenDirectoryName
    )
    process {
        $url = "https://www.onsen.ag/web_api/programs/$OnsenDirectoryName"
        return Invoke-RestMethod -Method Get -Uri $url
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
        $FfmpegPath = "ffmpeg"
    )
    process {
        # 放送の詳細情報を取得
        $program = Get-OnsenProgram -OnsenDirectoryName $OnsenDirectoryName

        # サブディレクトリを切る
        $output_sub_dir = Join-Path -Path $destinationPath -ChildPath $OnsenDirectoryName
        if (!(Test-Path $output_sub_dir)) {
            New-Item -Path $output_sub_dir -ItemType "Directory"
        }

        # 最新コメント部分
        $comment = ($program.current_episode.comments | ForEach-Object { $_.caption + $_.body }) -join "`r`n"
        # 最新放送日時
        $culture = [System.Globalization.CultureInfo]::GetCultureInfo("ja-jp")
        $date = [System.DateTimeOffset]::ParseExact($program.current_episode.delivery_date + "+00:00", "yyyy年M月d日(ddd)zzz", $culture)
        $year = $date.Year
        $creation_time = $date.ToString('u')
        # 無料で視聴できる放送
        $contents = $program.contents | Where-Object -Property streaming_url -NE $null

        # 放送でループ
        foreach ($content in $contents) {
            $track = (Select-String -InputObject $content.title -Pattern "[0-9]+").Matches[0].Value

            # streamのURLの後ろから2つ目のセグメントがファイル名になっている
            $url_segment = $content.streaming_url -split "/"
            $filename = $url_segment[$url_segment.Length - 2]
            # 音声のみの場合は拡張子をm4aにする(.mp4のままだとAppleのPodcastアプリが動画だと解釈してしまう)
            if ($content.media_type -eq "sound") {
                $filename = $filename.Split(".")[0] + ".m4a"
            }
            # 出演者
            $performers = $program.performers | Select-Object -ExpandProperty "name"
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

            # コメントと日付は最新の放送のみセット
            $comment = $null
            $year = $null
            $creation_time = $null
        }
    }
}