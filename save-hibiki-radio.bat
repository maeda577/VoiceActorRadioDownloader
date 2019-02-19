@powershell/c '#'+(gc \"%~f0\"-ra)^|iex&exit/b
############################################################################
$access_ids = @"
ccsakura
imas_cg
"@ -split "\s+"
$output_dir = "$HOME\Music\records\"
$ffmpeg = "C:\Program_Free\ffmpeg\bin\ffmpeg.exe"
############################################################################
$useragent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0'
$headers = @{
    'X-Requested-With' = 'XMLHttpRequest';
    'Origin'           = 'https://hibiki-radio.jp'
}
function get-program-detail {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $access_id = 'ccsakura'
    )
    process {
        $url = "https://vcms-api.hibiki-radio.jp/api/v1/programs/$access_id"
        Invoke-RestMethod -Method Get -Uri $url -UserAgent $useragent -Headers $headers
    }
}
function get-playlist-url-by-id {
    Param(
        [Parameter(mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $video_id
    )
    process {
        $url = "https://vcms-api.hibiki-radio.jp/api/v1/videos/play_check?video_id=$video_id"
        (Invoke-RestMethod -Method Get -Uri $url -UserAgent $useragent -Headers $headers).playlist_url
    }
}
function save-hibiki-radio {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $access_id = 'ccsakura'
    )
    process {
        $program = get-program-detail $access_id
        if (!$program.episode.video.id) {
            "No episodes in $access_id"
            return
        }
        $date = $program.episode.updated_at -split "[^\d]"
        $year = $date[0]
        $date = "$($date[0].Substring($date[0].Length - 2, 2)).$($date[1]).$($date[2])"
        $track = [regex]::replace($program.episode.name, "[０-９]", { $args.value[0] - 65248 -as "char" }) -replace "[^\d]", ""
        $filename = "$output_dir$($program.episode.program_name)" + $(if ($track) {"_#$track"}) + "_($date).m4a"
        if (Test-Path $filename) {
            "File already exists: $filename"
            return
        }
        $playlist_url = get-playlist-url-by-id $program.episode.video.id
        $ffmepg_arg = @('-i' , "`"$playlist_url`"", "-vn" , "-acodec", "copy" , "-bsf:a" , "aac_adtstoasc",
            "-metadata", ("title=`"$($program.episode.program_name)" + $(if ($track) {" #$track"}) + " ($date)`""),
            "-metadata", "artist=`"$($program.cast)`"",
            "-metadata", "album=`"$($program.episode.program_name)`"",
            "-metadata", "comment=`"$($program.description -replace '\s+',' ')`"",
            "-metadata", "genre=`"Web Radio`"",
            "-metadata", "year=`"$year`"",
            "-metadata", "date=`"$year`"",
            "-metadata", "track=`"$track`"",
            "`"$filename`"")
        & $ffmpeg $ffmepg_arg
    }   
}


$access_ids|save-hibiki-radio