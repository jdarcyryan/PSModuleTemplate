<#
    .SYNOPSIS
    Runs Pester tests for the PowerShell module.
#>
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

function Invoke-PSModulePester {
    <#
        .SYNOPSIS
        Runs Pester tests for the PowerShell module.
    #>
    param()

    $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
    $pesterModulePath = "$PSScriptRoot\..\modules\Pester"

    # Verify Pester module exists
    if (-not (Test-Path -Path $pesterModulePath)) {
        throw "Pester module not found at '$pesterModulePath'."
    }

    try {
        # Import Pester from local path
        Import-Module -Name $pesterModulePath -Force -ErrorAction Stop -Verbose:$false -WarningAction SilentlyContinue *>$null

        # Run Pester tests with detailed output
        Push-Location -Path $gitRoot
        
        try {
            Invoke-Pester -Output Detailed
        }
        finally {
            Pop-Location
        }
    }
    finally {
        # Clean up - remove Pester module
        Remove-Module -Name Pester -ErrorAction SilentlyContinue
    }
}

try {
    Invoke-PSModulePester @PSBoundParameters -Verbose:$false
}
catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
}
