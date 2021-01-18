[CmdletBinding()]
param (
    [Parameter(ParameterSetName = "Arguments")]
    [String[]]
    $HibikiAccessIds = @(),

    [Parameter(ParameterSetName = "Arguments")]
    [String[]]
    $OnsenDirectoryNames = @(),

    [Parameter(ParameterSetName = "Arguments", Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [String]
    $DestinationPath,

    [Parameter(ParameterSetName = "Arguments")]
    [String]
    $PodcastBaseUrl = "http://localhost/",

    [Parameter(ParameterSetName = "Arguments")]
    [String]
    $FfmpegPath = "ffmpeg",

    [Parameter(ParameterSetName = "Arguments")]
    [String]
    $FfprobePath = "ffprobe",

    [Parameter(ParameterSetName = "ConfigFile", Mandatory=$true)]
    [String]
    $ConfigurationPath
)

# Ubuntu環境だとカンマ区切りの引数を指定しても自動で分割されなかったので切る
if ($HibikiAccessIds.Length -eq 1) {
    $HibikiAccessIds = $HibikiAccessIds.Split(",") | ForEach-Object { $_.Trim() }
}
if ($OnsenDirectoryNames.Length -eq 1) {
    $OnsenDirectoryNames = $OnsenDirectoryNames.Split(",") | ForEach-Object { $_.Trim() }
}

# configファイルが指定されていた場合
if ($ConfigurationPath) {
    $config = Get-Content -Path $ConfigurationPath | ConvertFrom-Json
    $HibikiAccessIds = $config.Hibiki.AccessIds
    $OnsenDirectoryNames = $config.Onsen.DirectoryNames
    $OnsenEmail = $config.Onsen.Email
    $OnsenPassword = $config.Onsen.Password
    $DestinationPath = $config.DestinationPath
    $PodcastBaseUrl = $config.PodcastBaseUrl
    $FfmpegPath = $config.Ffmpeg.FfmpegPath
    $FfprobePath = $config.Ffmpeg.FfprobePath
}

Import-Module -Force $PSScriptRoot/SaveHibikiRadio.psm1
Import-Module -Force $PSScriptRoot/SaveOnsenRadio.psm1
Import-Module -Force $PSScriptRoot/UpdatePodcastFeed.psm1

# Hibikiのダウンロードとrss生成
$HibikiAccessIds | Save-HibikiRadio -DestinationPath $DestinationPath
$HibikiAccessIds | Update-HibikiRadioFeed -DestinationPath $DestinationPath -PodcastBaseUrl $PodcastBaseUrl

# 音泉のダウンロードとrss生成
if($OnsenEmail -and $OnsenPassword){
    $session = Connect-OnsenPremium -Email $OnsenEmail -Password $OnsenPassword
}
$OnsenDirectoryNames | Save-OnsenRadio -DestinationPath $DestinationPath -Session $session
$OnsenDirectoryNames | Update-OnsenRadioFeed -DestinationPath $DestinationPath -PodcastBaseUrl $PodcastBaseUrl
if ($session) {
    Disconnect-OnsenPremium -Session $session
}