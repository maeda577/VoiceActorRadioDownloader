[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [String]
    [ValidateScript( { Test-Path $_ })]
    $ConfigurationFilePath
)

Import-Module -Force -Name $PSScriptRoot/modules/VoiceActorRadioDownloader.psd1

Start-VoiceActorRadioDownloader -ConfigurationFilePath $ConfigurationFilePath -ErrorAction Stop -WhatIf:$WhatIfPreference
