[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    [ValidateScript( { Test-Path $_ })]
    $ConfigurationFilePath
)

# config読み取り
$config = Get-Content -Path $ConfigurationFilePath -Encoding UTF8 | ConvertFrom-Json

if ((Test-Path $config.DestinationPath) -eq $false) {
    throw "DestinationPath is not exists"
}

$FfmpegPath = $config.Ffmpeg.FfmpegPath
if ($FfmpegPath -eq "") {
    $FfmpegPath = "ffmpeg"
}
$FfprobePath = $config.Ffmpeg.FfprobePath
if ($FfprobePath -eq "") {
    $FfprobePath = "ffprobe"
}

Import-Module -Force $PSScriptRoot/SaveHibikiRadio.psm1
Import-Module -Force $PSScriptRoot/SaveOnsenRadio.psm1
Import-Module -Force $PSScriptRoot/SaveRadiko.psm1
Import-Module -Force $PSScriptRoot/UpdatePodcastFeed.psm1

# Hibikiのダウンロード
if ($config.Hibiki.AccessIds) {
    $config.Hibiki.AccessIds | Save-HibikiRadio -DestinationPath $config.DestinationPath -FfmpegPath $FfmpegPath
}

# 音泉のダウンロード
if ($config.Onsen.Email -and $config.Onsen.Password) {
    $session = Connect-OnsenPremium -Email $config.Onsen.Email -Password $config.Onsen.Password
}
if ($config.Onsen.DirectoryNames) {
    $config.Onsen.DirectoryNames | Save-OnsenRadio -DestinationPath $config.DestinationPath -Session $session -FfmpegPath $FfmpegPath
}
if ($session) {
    Disconnect-OnsenPremium -Session $session
}

# Radikoタイムフリーのダウンロード
if ($config.Radiko.Programs) {
    $radiko = Connect-Radiko
    foreach ($program in $config.Radiko.Programs) {
        # 視聴エリア外の場合はスキップ
        if ($program.StationId -notin $radiko.StationIds) {
            Write-Warning -Message "Current area $($radiko.AreaId) can't listen station $($program.StationId). Skipping."
            Continue
        }

        Save-Radiko -AuthToken $radiko.AuthToken -StationId $program.StationId -MatchTitle $program.MatchTitle -DestinationPath $config.DestinationPath -DestinationSubDir $program.LocalDirectoryName -Session $session -FfmpegPath $FfmpegPath
    }
}

# Podcast用RSS更新
Get-ChildItem -Path $config.DestinationPath -Filter "info.json" -File -Recurse | Update-RadioFeed -DestinationPath $config.DestinationPath -PodcastBaseUrl $config.PodcastBaseUrl -FfprobePath $FfprobePath
