[CmdletBinding()]
<#
.SYNOPSIS
    Creates PowerShell profile for GitHub runner from template.
#>
param(
    [ValidateNotNullOrEmpty()]
    [io.FileInfo]
    $ProfilePath = "$PSScriptRoot\..\Microsoft.PowerShell_profile.ps1"
)

$ErrorActionPreference = 'Stop'

function Setup-RunnerProfile {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Creates PowerShell profile for GitHub runner from template.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [io.FileInfo]
        $ProfilePath = "$PSScriptRoot\..\Microsoft.PowerShell_profile.ps1"
    )

    $sourceProfilePath = $ProfilePath | % FullName

    if (-not (Test-Path -Path $sourceProfilePath)) {
        throw "Profile template '$sourceProfilePath' does not exist."
    }

    $profileParent = Split-Path -Path $sourceProfilePath -Parent

    Write-Verbose "Creating profile parent directory '$profileParent'."
    New-Item -Path $profileParent -ItemType Directory -Force > $null

    Write-Verbose "Copying template profile contents to '$Profile'."
    Copy-Item -Path $sourceProfilePath -Destination $Profile -Force
}

try {
    Setup-RunnerProfile @PSBoundParameters
}
catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
}
