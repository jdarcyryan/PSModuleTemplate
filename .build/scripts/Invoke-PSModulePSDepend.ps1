<#
    .SYNOPSIS
    Installs module dependencies using PSDepend.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Invoke-PSModulePSDepend {
    <#
        .SYNOPSIS
        Installs module dependencies using PSDepend.
    #>
    [CmdletBinding()]
    param()

    $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
    $psDependModulePath = "$PSScriptRoot\..\modules\PSDepend"
    $psDependManifestPath = "$gitRoot\PSDepend.psd1"

    # Verify PSDepend manifest exists
    if (-not (Test-Path -Path $psDependManifestPath -PathType Leaf)) {
        throw "PSDepend manifest not found at: '$psDependManifestPath'."
    }

    # Verify PSDepend module exists
    if (-not (Test-Path -Path $psDependModulePath)) {
        throw "PSDepend module not found at '$psDependModulePath'."
    }

    try {
        # Import PSDepend from local path
        Import-Module -Name $psDependModulePath -Force -ErrorAction Stop -Verbose:$false -WarningAction SilentlyContinue *>$null

        # Install dependencies using PSDepend
        Push-Location -Path $gitRoot

        try {
            Invoke-PSDepend -Path $psDependManifestPath -Install -Force
        }
        finally {
            Pop-Location
        }
    }
    finally {
        # Clean up - remove PSDepend module
        Remove-Module -Name PSDepend -ErrorAction SilentlyContinue
    }
}

try {
    Invoke-PSModulePSDepend @PSBoundParameters
}
catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
}
