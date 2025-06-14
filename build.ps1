<#
.SYNOPSIS
    Builds, sets up, or ships a PowerShell module based on the specified mode.

.DESCRIPTION
    This script performs different operations on a PowerShell module depending on the mode specified:
    - Build: Compiles the module without versioning (typically used for pull requests)
    - Setup: Initializes the module manifest for new modules
    - Ship: Builds the module with proper versioning for release

.PARAMETER Mode
    Specifies the operation mode for the script.
    
    Valid values are:
    - "Build": Build with no versioning (pull request)
    - "Setup": Setup module manifest (for new modules) 
    - "Ship": Build with version (release)

.EXAMPLE
    .\Build.ps1 -Mode Build
    
    Builds the module without versioning, typically used during development or for pull requests.

.EXAMPLE
    .\Build.ps1 -Mode Setup
    
    Sets up the module manifest for a new module, initializing required files and structure.

.EXAMPLE
    .\Build.ps1 -Mode Ship
    
    Builds the module with proper versioning for release to PowerShell Gallery or distribution.

.EXAMPLE
    .\Build.ps1 -Mode Build -Verbose
    
    Builds the module with verbose output showing detailed progress information.

.NOTES
    Author: James D'Arcy Ryan
    
.LINK
    https://github.com/jdarcyryan/PSModuleTemplate
#>
[CmdLetBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(
        "Build", # Build with no versioning (pull request)
        "Setup", # Setup module manfiest (for new modules)
        "Ship" # Build with version (release)
    )]
    [string]
    $Mode
)

$errorActionPreference = 'Stop'

# Standard definitions for all modes
$moduleName = Get-Item $PSScriptRoot | % Name
$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath "$moduleName.psd1"

# Manifest template creation
if (Test-Path -Path $manifestPath -PathType Leaf) {
    Write-Verbose "Module manifest found, skipping creation."
}
elseif (Test-Path -Path $manifestPath -PathType Container) {
    throw "The path '$manifestPath' is a directory, not a file."
}
else {
    New-ModuleManifest -Path $manifestPath -RootModule "$moduleName.psm1" -ModuleVersion "1.0.0"
    Write-Verbose "Module manifest created at root\$moduleName.psd1"
}

# Build module psm1
if ($Mode -in @("Build", "Ship")) {

}