﻿[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]
    [ValidateScript({Test-Path $_})]
    $ConfigurationFilePath
)

# config読み取り
$config = Get-Content -Path $ConfigurationFilePath -Encoding UTF8 | ConvertFrom-Json

if ((Test-Path $config.DestinationPath) -eq $false) {
    throw "DestinationPath is not exists"
}

$FfmpegPath = $config.Ffmpeg.FfmpegPath
if ($FfmpegPath -eq "") {
    $FfmpegPath = $null
}
$FfprobePath = $config.Ffmpeg.FfprobePath
if ($FfprobePath -eq "") {
    $FfprobePath = $null
}

Import-Module -Force $PSScriptRoot/SaveHibikiRadio.psm1
Import-Module -Force $PSScriptRoot/SaveOnsenRadio.psm1
Import-Module -Force $PSScriptRoot/UpdatePodcastFeed.psm1

# Hibikiのダウンロードとrss生成
if ($config.Hibiki.AccessIds) {
    $config.Hibiki.AccessIds | Save-HibikiRadio -DestinationPath $config.DestinationPath -FfmpegPath $FfmpegPath
    $config.Hibiki.AccessIds | Update-HibikiRadioFeed -DestinationPath $config.DestinationPath -PodcastBaseUrl $config.PodcastBaseUrl -FfprobePath $FfprobePath
}

# 音泉のダウンロードとrss生成
if($config.Onsen.Email -and $config.Onsen.Password){
    $session = Connect-OnsenPremium -Email $config.Onsen.Email -Password $config.Onsen.Password
}
if ($config.Onsen.DirectoryNames) {
    $config.Onsen.DirectoryNames | Save-OnsenRadio -DestinationPath $config.DestinationPath -Session $session -FfmpegPath $FfmpegPath
    $config.Onsen.DirectoryNames | Update-OnsenRadioFeed -DestinationPath $config.DestinationPath -PodcastBaseUrl $config.PodcastBaseUrl -FfprobePath $FfprobePath
}
if ($session) {
    Disconnect-OnsenPremium -Session $session
}
