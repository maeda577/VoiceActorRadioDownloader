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

        # コメント部分
        $comment = ($program.current_episode.comments | ForEach-Object { $_.caption + $_.body }) -join "`r`n"
        # 無料で視聴できる放送
        $contents = $program.contents | Where-Object -Property streaming_url -NE $null

        # 放送でループ
        foreach ($content in $contents) {
            $track = (Select-String -InputObject $content.title -Pattern "[0-9]+").Matches[0].Value

            # streamのURLの後ろから2つ目のセグメントがファイル名になっている
            $url_segment = $content.streaming_url -split "/"
            $filename = $url_segment[$url_segment.Length - 2]

            # ffmpegの引数
            $ffmepg_arg = @(
                "-i", "`"$($content.streaming_url)`""     #input file url
                "-n",                       #Do not overwrite output files, and exit immediately if a specified output file already exists.
                "-loglevel", "error",       #Show all errors, including ones which can be recovered from.
                "-acodec", "copy",          #Set the audio codec.
                "-vcodec", "copy",          #Set the video codec.
                "-bsf:a" , "aac_adtstoasc", #Set bitstream filters for matching streams.
                "-metadata", "artist=`"$(($program.performers + $content.guests) -join ",")`"",
                "-metadata", "album=`"$($program.program_info.title)`"",
                "-metadata", "track=`"$track`"",
                "-metadata", "genre=`"Web Radio`"",
                "-metadata", "description=`"$($program.program_info.description)`"",
                "-metadata", "comment=`"$comment`"",
                "-metadata", "copyright=`"$($program.program_info.copyright)`"",
                "-metadata", "title=`"$($program.program_info.title) $($content.title)`"", # タイトル
                "`"$(Join-Path -Path $output_sub_dir -ChildPath $filename)`""   # 出力ファイルのフルパス
            )

            # ダウンロード実行
            Start-Process -FilePath $ffmpegPath -ArgumentList $ffmepg_arg -Wait

            # コメントは最新の放送のみセット
            $comment = $null
        }
    }
}