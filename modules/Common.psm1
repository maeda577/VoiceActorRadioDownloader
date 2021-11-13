function New-DirectoryIfNotExists {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true)]
        [String]
        $ParentDirectory,

        [Parameter(Mandatory = $true)]
        [String]
        $DirectoryName
    )
    $fullPath = Join-Path -Path $ParentDirectory -ChildPath $DirectoryName
    if ((Test-Path $fullPath) -eq $false) {
        $createdDirectory = New-Item -Path $fullPath -ItemType "Directory" -WhatIf:$WhatIfPreference
        if ($WhatIfPreference -eq $false) {
            Write-Information -MessageData "Directory Created: $([System.IO.Path]::GetFullPath($fullPath))"
        }
        return $createdDirectory
    }
    else {
        return Get-Item -Path $fullPath
    }
}

function Invoke-DownloadItemIfNotExists {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true)]
        [String]
        $Uri,

        [Parameter(Mandatory = $true)]
        [String]
        $OutFile,

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    if ((Test-Path $OutFile) -eq $false) {
        if ($PSCmdlet.ShouldProcess($OutFile, "Download")) {
            $null = Invoke-WebRequest -Method Get -Uri $Uri -OutFile $OutFile -UseBasicParsing -WebSession $WebSession
            Write-Information -MessageData "File Downloaded: $([System.IO.Path]::GetFullPath($OutFile))"
        }
        return $true
    }
    else {
        return $false
    }
}

function Set-PodcastInfoFile {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $DestinationDirectory,
        [Parameter(Mandatory = $true)]
        [String]
        $Title,
        [Parameter()]
        [String]
        $Description,
        [Parameter()]
        [String]
        $ImageFileName,
        [Parameter()]
        [String]
        $SiteUri,
        [Parameter()]
        [String]
        $Copyright
    )
    $infoFullPath = Join-Path -Path $DestinationDirectory -ChildPath "info.json"
    @{
        "title" = $Title;
        "description" = $Description;
        "image" = $ImageFileName;
        "link" = $SiteUri;
        "copyright" = $Copyright;
    } | ConvertTo-Json | Out-File -FilePath $infoFullPath -Encoding UTF8 -WhatIf:$WhatIfPreference
}
