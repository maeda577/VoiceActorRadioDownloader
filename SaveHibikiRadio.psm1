$headers = @{
    'X-Requested-With' = 'XMLHttpRequest';
}
$bonus_part_name = '楽屋裏'

$culture = [System.Globalization.CultureInfo]::GetCultureInfo("ja-jp")

function Get-PlaylistUrl {
    Param(
        [Parameter(mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $VideoId
    )
    process {
        $url = "https://vcms-api.hibiki-radio.jp/api/v1/videos/play_check?video_id=$VideoId"
        (Invoke-RestMethod -Method Get -Uri $url -Headers $headers).playlist_url
    }
}

function Save-HibikiRadio {
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $HibikiAccessId,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $DestinationPath,

        [Parameter()]
        [String]
        $FfmpegPath = "ffmpeg"
    )
    process {
        # 放送の詳細情報を取得
        $programUrl = "https://vcms-api.hibiki-radio.jp/api/v1/programs/$HibikiAccessId"
        $program = Invoke-RestMethod -Method Get -Uri $programUrl -Headers $headers
        if (!$program.episode.video.id) {
            Write-Error "No episodes in $HibikiAccessId"
            return
        }

        # サブディレクトリを切る
        $output_sub_dir = Join-Path -Path $DestinationPath -ChildPath $HibikiAccessId
        if ((Test-Path $output_sub_dir) -eq $false) {
            New-Item -Path $output_sub_dir -ItemType "Directory" > $null
        }

        # ダウンロード実行
        Save-HibikiRadioEpisode -Program $program -EpisodeDestinationPath $output_sub_dir -FfmpegPath $FfmpegPath

        # 楽屋裏パートがあればダウンロード
        if ($program.additional_video_flg) {
            Save-HibikiRadioEpisode -Program $program -EpisodeDestinationPath $output_sub_dir -FfmpegPath $FfmpegPath -IsBonus
        }

        # ダウンロードがコケて0byteのデータが残っていたら消す
        Get-ChildItem -Path $output_sub_dir -File | Where-Object { $_.Length -eq 0 } | Remove-Item

        # 放送情報をファイルに書き出す
        Update-HibikiProgramInfo -Program $program -EpisodeDestinationPath $output_sub_dir
    }
}

function Save-HibikiRadioEpisode {
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]
        $Program,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $EpisodeDestinationPath,

        [Parameter()]
        [String]
        $FfmpegPath = "ffmpeg",

        [switch]
        $IsBonus
    )
    process {
        # 公開日
        $publishDate = [System.DateTimeOffset]::ParseExact($Program.episode.updated_at, "yyyy/MM/dd HH:mm:ss", $culture)

        if ($IsBonus) {
            # ファイル名(拡張子無し)
            $filenameBase = "$HibikiAccessId-$($publishDate.ToString("yyyyMMdd"))-$($Program.episode.additional_video.id)"
            # URL
            $playlistUrl = Get-PlaylistUrl $Program.episode.additional_video.id
            # タグに書き込むタイトル
            $title = "$($Program.episode.program_name) $($Program.episode.name) $bonus_part_name"
        }
        else {
            $filenameBase = "$HibikiAccessId-$($publishDate.ToString("yyyyMMdd"))-$($Program.episode.video.id)"
            $playlistUrl = Get-PlaylistUrl $Program.episode.video.id
            $title = "$($Program.episode.program_name) $($Program.episode.name)"
        }

        # 画像があればダウンロード
        if ($Program.episode.episode_parts[0].pc_image_url) {
            $extension = [IO.Path]::GetExtension($Program.episode.episode_parts[0].pc_image_url)
            $imageFullPath = Join-Path -Path $EpisodeDestinationPath -ChildPath ($filenameBase + $extension)
            if ((Test-Path -Path $imageFullPath) -eq $false) {
                Invoke-WebRequest -Method Get -Uri $Program.episode.episode_parts[0].pc_image_url -OutFile $imageFullPath -UseBasicParsing > $null
            }
        }

        # 第何回放送か
        $track = (Select-String -InputObject $Program.episode.name -Pattern "[0-9]+").Matches[0].Value

        # 出力ファイルのフルパス
        $fileFullPath = Join-Path -Path $EpisodeDestinationPath -ChildPath ($filenameBase + ".m4a")

        # ffmpegの引数を作る
        $ffmepg_arg = @(
            "-i", "`"$playlistUrl`"",     #input file url
            "-loglevel", "error", #Show all errors, including ones which can be recovered from.
            "-acodec", "copy", #Set the audio codec.
            "-bsf:a" , "aac_adtstoasc", #Set bitstream filters for matching streams.
            "-vn", #As an input option, blocks all video streams of a file from being filtered or being automatically selected or mapped for any output.
            "-metadata", "artist=`"$($Program.cast)`"",
            "-metadata", "album=`"$($Program.episode.program_name)`"",
            "-metadata", "track=`"$track`"",
            "-metadata", "genre=`"Web Radio`"",
            "-metadata", "date=`"$($publishDate.Year)`"",
            "-metadata", "creation_time=`"$($publishDate.ToString('u'))`"",
            "-metadata", "description=`"$($Program.description)`"",
            "-metadata", "comment=`"$($Program.episode.episode_parts[0].description)`"",
            "-metadata", "copyright=`"$($Program.copyright)`""
            "-metadata", "title=`"$title`"", # タイトル
            "`"$fileFullPath`""   # 出力ファイルのフルパス
        )

        # ダウンロード実行
        if ((Test-Path -Path $fileFullPath) -eq $false) {
            Start-Process -FilePath $FfmpegPath -ArgumentList $ffmepg_arg -Wait
        }
    }
}

function Update-HibikiProgramInfo {
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
        $imageFileName = [IO.Path]::GetFileName($Program.pc_image_url)

        # カバー画像がなければダウンロード
        $imageFullPath = Join-Path -Path $EpisodeDestinationPath -ChildPath $imageFileName
        if ((Test-Path $imageFullPath) -eq $false) {
            Invoke-WebRequest -Uri $Program.pc_image_url -OutFile $imageFullPath > $null
        }

        $infoFullPath = Join-Path -Path $EpisodeDestinationPath -ChildPath "info.json"

        @{
            "title" = $Program.episode.program_name;
            "description" = $Program.description;
            "image" = $imageFileName;
            "link" = "https://hibiki-radio.jp/description/$($Program.access_id)/detail";
            "copyright" = $Program.copyright;
        } | ConvertTo-Json | Out-File -FilePath $infoFullPath -Encoding UTF8
    }
}
