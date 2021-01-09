$headers = @{
    'X-Requested-With' = 'XMLHttpRequest';
}
$bonus_part_name = '楽屋裏'

function Get-HibikiProgram {
    Param(
        [Parameter(mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $HibikiAccessId
    )
    process {
        $url = "https://vcms-api.hibiki-radio.jp/api/v1/programs/$HibikiAccessId"
        return Invoke-RestMethod -Method Get -Uri $url -Headers $headers
    }
}

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
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [String]
        $HibikiAccessId,

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
        $program = Get-HibikiProgram -HibikiAccessId $HibikiAccessId
        if (!$program.episode.video.id) {
            Write-Error "No episodes in $HibikiAccessId"
            return
        }

        # サブディレクトリを切る
        $output_sub_dir = Join-Path -Path $destinationPath -ChildPath $HibikiAccessId
        if (!(Test-Path $output_sub_dir)) {
            New-Item -Path $output_sub_dir -ItemType "Directory" > $null
        }

        # ffmpegの引数(共通部)を作る
        $date = [System.DateTimeOffset]::Parse($program.episode.updated_at + " +0900")
        $track = (Select-String -InputObject $program.episode.name -Pattern "[0-9]+").Matches[0].Value

        $ffmepg_arg_base = @(
            "-n",                       #Do not overwrite output files, and exit immediately if a specified output file already exists.
            "-loglevel", "error",       #Show all errors, including ones which can be recovered from.
            "-acodec", "copy",          #Set the audio codec.
            "-bsf:a" , "aac_adtstoasc", #Set bitstream filters for matching streams.
            "-vn",                      #As an input option, blocks all video streams of a file from being filtered or being automatically selected or mapped for any output.
            "-metadata", "artist=`"$($program.cast)`"",
            "-metadata", "album=`"$($program.episode.program_name)`"",
            "-metadata", "track=`"$track`"",
            "-metadata", "genre=`"Web Radio`"",
            "-metadata", "date=`"$($date.Year)`"",
            "-metadata", "creation_time=`"$($date.ToString('u'))`"",
            "-metadata", "description=`"$($program.description.Trim())`"",
            "-metadata", "comment=`"$($program.episode.episode_parts[0].description.Trim())`"",
            "-metadata", "copyright=`"$($program.copyright)`""
        )

        # ffmpegの引数(本編)を作る
        $filename = "$HibikiAccessId-$($date.ToString("yyyyMMdd"))-$($program.episode.video.id).mp4"
        $ffmepg_arg_input = @(
            "-i", "`"$(Get-PlaylistUrl $program.episode.video.id)`""     #input file url
        )
        $ffmepg_arg_output = @(
            "-metadata", "title=`"$($program.episode.program_name) $($program.episode.name)`"", # タイトル
            "`"$(Join-Path -Path $output_sub_dir -ChildPath $filename)`""   # 出力ファイルのフルパス
        )

        # ダウンロード実行
        Start-Process -FilePath $ffmpegPath -ArgumentList ($ffmepg_arg_input + $ffmepg_arg_base + $ffmepg_arg_output) -Wait

        # 楽屋裏パートがあるか
        if (!$program.additional_video_flg) {
            return
        }
 
        # ffmpegの引数(楽屋裏)を作る
        $filename = "$HibikiAccessId-$($date.ToString("yyyyMMdd"))-$($program.episode.additional_video.id).mp4"
        $ffmepg_arg_input = @(
            "-i", "`"$(Get-PlaylistUrl $program.episode.additional_video.id)`""     #input file url
        )
        $ffmepg_arg_output = @(
            "-metadata", "title=`"$($program.episode.program_name) $($program.episode.name) $bonus_part_name`"", # タイトル
            "`"$(Join-Path -Path $output_sub_dir -ChildPath $filename)`""   # 出力ファイルのフルパス
        )

        # ダウンロード実行
        Start-Process -FilePath $ffmpegPath -ArgumentList ($ffmepg_arg_input + $ffmepg_arg_base + $ffmepg_arg_output) -Wait
    }
}
