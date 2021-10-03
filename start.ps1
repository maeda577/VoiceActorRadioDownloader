[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [String]
    [ValidateScript( { Test-Path $_ })]
    $ConfigurationFilePath
)

Get-ChildItem -Path $PSScriptRoot/modules/ -Filter *.psm1 |
    ForEach-Object -Process { Import-Module -Force -Name $_.FullName }

Start-VoiceActorRadioDownloader -ConfigurationFilePath $ConfigurationFilePath -ErrorAction Stop -WhatIf:$WhatIfPreference
