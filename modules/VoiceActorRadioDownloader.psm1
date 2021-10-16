function Start-VoiceActorRadioDownloader {
    [CmdletBinding(SupportsShouldProcess)]
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
    if ([System.String]::IsNullOrWhiteSpace($FfmpegPath)) {
        $FfmpegPath = "ffmpeg"
    }
    $FfprobePath = $config.Ffmpeg.FfprobePath
    if ([System.String]::IsNullOrWhiteSpace($FfprobePath)) {
        $FfprobePath = "ffprobe"
    }

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

    # RadioTalkのダウンロード
    if ($config.RadioTalk.ProgramIds) {
        $config.RadioTalk.ProgramIds | Save-RadioTalk -DestinationPath $config.DestinationPath -FfmpegPath $FfmpegPath 6>&1
    }

    # Podcast用RSS更新
    Get-ChildItem -Path $config.DestinationPath -Filter "info.json" -File -Recurse | Update-RadioFeed -DestinationPath $config.DestinationPath -PodcastBaseUrl $config.PodcastBaseUrl -FfprobePath $FfprobePath
}

function Start-VoiceActorRadioDownloaderService {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        [ValidateScript( { Test-Path $_ })]
        $ConfigurationFilePath,

        [int]
        [ValidateScript( { ($_ -ge 0) -and ($_ -le 23) })]
        $InvokeHour = 0
    )

    while ($true) {
        $now = Get-Date
        # 次の実行予定時刻
        $nextInvokeDate = $now.Date.AddHours($InvokeHour)
        # 予定時刻を過ぎていたら1日進める
        if ($now -gt $nextInvokeDate) {
            $nextInvokeDate = $nextInvokeDate.AddDays(1)
        }
        # 待機してから実行
        Start-Sleep -Seconds ($nextInvokeDate - $now).TotalSeconds.ToInt32($null)
        Start-VoiceActorRadioDownloader -ConfigurationFilePath $ConfigurationFilePath -ErrorAction Stop -WhatIf:$WhatIfPreference
    }
}
