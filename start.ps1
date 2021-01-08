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

if ($HibikiAccessIds.Length -eq 1) {
    $HibikiAccessIds = $HibikiAccessIds.Split(",") | ForEach-Object { $_.Trim() }
}

Import-Module -Force $PSScriptRoot/SaveHibikiRadio.psm1

$HibikiAccessIds | Save-HibikiRadio -DestinationPath $destinationPath
$HibikiAccessIds | Update-HibikiRadioFeed -DestinationPath $destinationPath -PodcastBaseUrl $PodcastBaseUrl
