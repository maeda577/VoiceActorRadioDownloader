@powershell/c '#'+(gc \"%~f0\"-ra)^|iex&pause&exit/b
############################################################################
$DEFO_access_ids = @"
ccsakura
hanaso
priconne_re
"@ -split "\s+"
$DEFO_output_dir = "$HOME\Music\records\"
$DEFO_ffmpeg = "C:\Program_Free\ffmpeg\bin\ffmpeg.exe"#pathが通っているなら書く必要はない
############################################################################
if (!$access_ids) {
    $access_ids = $DEFO_access_ids
}
if (!$ffmpeg) {
    if (!!(Get-Command ffmpeg 2>$null)) {
        $ffmpeg = (Get-Command ffmpeg).Definition
    }
    else {
        $ffmpeg = $DEFO_ffmpeg
    }
}
if (!$output_dir) {
    $output_dir = $DEFO_output_dir
}
if (!(Test-Path $output_dir)) {
    mkdir $output_dir
}
$useragent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0'
$headers = @{
    'X-Requested-With' = 'XMLHttpRequest';
    'Origin'           = 'https://hibiki-radio.jp'
}

# 禁止文字(半角記号)
$CannotUsedFileName = "\/:*?`"><|"
# 禁止文字(全角記号)
$UsedFileName = "￥／：＊？`”＞＜｜"
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
    begin {
        $succeeded = @()
        $failed = @()
    }
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
        $filename = $program.episode.program_name + $(if ($track) { "_#$track" }) + "_($date).m4a"
        $filename = [regex]::Replace($filename, "[$CannotUsedFileName]", { $UsedFileName[$CannotUsedFileName.IndexOf($args.value[0])] })
        $filename = $output_dir + $filename
        if (Test-Path $filename) {
            "File already exists: $filename"
            return
        }
        $playlist_url = get-playlist-url-by-id $program.episode.video.id
        $ffmepg_arg = @('-i' , "`"$playlist_url`"", "-vn" , "-acodec", "copy" , "-bsf:a" , "aac_adtstoasc",
            "-metadata", ("title=`"$($program.episode.program_name)" + $(if ($track) { " #$track" }) + " ($date)`""),
            "-metadata", "artist=`"$($program.cast)`"",
            "-metadata", "album=`"$($program.episode.program_name)`"",
            "-metadata", "comment=`"$($program.description -replace '\s+',' ')`"",
            "-metadata", "genre=`"Web Radio`"",
            "-metadata", "year=`"$year`"",
            "-metadata", "date=`"$year`"",
            "-metadata", "track=`"$track`"",
            "`"$filename`"")
        & $ffmpeg $ffmepg_arg
        if (Test-Path $filename) {
            $succeeded += $filename
        }
        else {
            $failed += $filename
        }
    }
    end {
        if ($succeeded) {
            "Succeeded: $succeeded"
        }
        if ($failed) {
            "Failed: $failed"
        }
    }
}

$access_ids | save-hibiki-radio
