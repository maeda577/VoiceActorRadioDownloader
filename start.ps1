[CmdletBinding()]
param (
    [Parameter()]
    [String[]]
    $HibikiAccessIds = @(),

    [Parameter()]
    [String[]]
    $OnsenDirectoryNames = @(),

    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [String]
    $DestinationPath,

    [Parameter()]
    [String]
    $PodcastBaseUrl = "http://localhost/",

    [Parameter()]
    [String]
    $FfmpegPath = "ffmpeg",

    [Parameter()]
    [String]
    $FfprobePath = "ffprobe"
)

# Ubuntu環境だとカンマ区切りの引数を指定しても自動で分割されなかったので切る
if ($HibikiAccessIds.Length -eq 1) {
    $HibikiAccessIds = $HibikiAccessIds.Split(",") | ForEach-Object { $_.Trim() }
}
if ($OnsenDirectoryNames.Length -eq 1) {
    $OnsenDirectoryNames = $OnsenDirectoryNames.Split(",") | ForEach-Object { $_.Trim() }
}

Import-Module -Force $PSScriptRoot/SaveHibikiRadio.psm1
Import-Module -Force $PSScriptRoot/SaveOnsenRadio.psm1
Import-Module -Force $PSScriptRoot/UpdatePodcastFeed.psm1

# Hibikiのダウンロードとrss生成
$HibikiAccessIds | Save-HibikiRadio -DestinationPath $destinationPath
$HibikiAccessIds | Update-HibikiRadioFeed -DestinationPath $destinationPath -PodcastBaseUrl $PodcastBaseUrl

# 音泉のダウンロードとrss生成
$OnsenDirectoryNames | Save-OnsenRadio -DestinationPath $destinationPath
$OnsenDirectoryNames | Update-OnsenRadioFeed -DestinationPath $destinationPath -PodcastBaseUrl $PodcastBaseUrl
