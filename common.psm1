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
    if (((Test-Path $fullPath) -eq $false) -and ($PSCmdlet.ShouldProcess($fullPath))) {
        $createdDirectory = New-Item -Path $fullPath -ItemType "Directory"
        Write-Information -MessageData "Directory Created: $([System.IO.Path]::GetFullPath($fullPath))"
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
        $OutFile
    )
    if ((Test-Path $OutFile) -eq $false) {
        if ($PSCmdlet.ShouldProcess($OutFile)) {
            $null = Invoke-WebRequest -Method Get -Uri $Uri -OutFile $OutFile -UseBasicParsing
            Write-Information -MessageData "File Downloaded: $([System.IO.Path]::GetFullPath($OutFile))"
        }
        return $true
    }
    else {
        return $false
    }
}
