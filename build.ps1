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
    Write-Verbose "Module manifest found at .\$moduleName.psd1, skipping creation."
}
elseif (Test-Path -Path $manifestPath -PathType Container) {
    throw "The path '$manifestPath' is a directory, not a file."
}
else {
    New-ModuleManifest -Path $manifestPath -RootModule "$moduleName.psm1" -ModuleVersion "1.0.0"
    Write-Verbose "Module manifest created at .\$moduleName.psd1"
}

# Build module psm1
if ($Mode -in @("Build", "Ship")) {
    # Build folder definitions
    $buildPath = Join-Path -Path $PSScriptRoot -ChildPath "build"
    $buildOutputPath = Join-Path -Path $buildPath -ChildPath "output"

    # Clean up previous build output
    if (Test-Path -Path $buildOutputPath) {
        Write-Verbose "Cleaning up previous build output at '$buildOutputPath'"
        Remove-item -Path $buildOutputPath -Recurse -Force
    }

    # Create build output directory
    $null = New-Item -Path $buildOutputPath -ItemType Directory

    # Import manifest data
    Write-Verbose "Importing module manifest data from '$manifestPath'"
    $ManifestData = Import-PowerShellDataFile -Path $manifestPath

    if ($Mode -eq "Ship") {
        if (!$env:PSModuleVersion) { # Set in actions CI
            throw "Environment variable 'PSModuleVersion' is not set."
        }
        else {
            Write-Verbose "Found environment variable PSModuleVersion: $env:PSModuleVersion"
        }
    }
    else {
        $env:PSModuleVersion = $ManifestData.ModuleVersion # Default version for builds
        Write-Verbose "Using default module version from manifest: $env:PSModuleVersion"
    }

    # Capture module name (in case updated from root directory name)
    $moduleName = Get-Item $manifestPath | % BaseName

    # Create module folder structure
    $moduleOutputPath = Join-Path -Path $buildOutputPath -ChildPath "$moduleName\$env:PSModuleVersion"
    Write-Verbose "Creating module output path '$moduleOutputPath'"
    $null = New-Item -Path $moduleOutputPath -ItemType Directory -Force

    # Create module psm1 file
    $outputModulePath = Join-Path -Path $moduleOutputPath -ChildPath "$moduleName.psm1"
    $null = New-Item -Path $outputModulePath -ItemType File -Force

    # Copy and version manifest
    $outputManfestPath = Join-Path -Path $moduleOutputPath -ChildPath "$moduleName.psd1"
    Copy-Item -Path $manifestPath -Destination $outputManfestPath -Force
    $manifestContent = Get-Content -Path $outputManfestPath -Raw
    $updatedManifestContent = $manifestContent -replace "ModuleVersion\s*=\s*'[\d\.]+'", "ModuleVersion = '$env:PSModuleVersion'"
    Set-Content -Path $outputManfestPath -Value $updatedManifestContent -Force
    Write-Verbose "Module manifest updated to version $env:PSModuleVersion at '$outputManfestPath'"

    # Define reference paths
    $classesRootPath = Join-Path -Path $PSScriptRoot -ChildPath "classes"
    $classManifestPath = Join-Path -Path $classesRootPath -ChildPath "classes.psd1"
    $privateFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "private"
    $publicFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "public"

    # Copy relevant files

    # Classes directory
    Get-ChildItem -Path $classesRootPath -Recurse |
        ? FullName -ne $classManifestPath |
        ? Extension -notin @(".ps1", ".gitignore", ".gitkeep") | foreach {
            $destinationPath = $_.FullName -replace [regex]::Escape($classesRootPath), $moduleOutputPath
            Copy-Item -Path $_.FullName -Destination $destinationPath -Force -Verbose:$verbosePreference
        }
    
    # Private directory
    Get-ChildItem -Path $privateFunctionsPath -Recurse |
        ? Extension -notin @(".ps1", ".gitignore", ".gitkeep") | foreach {
        $destinationPath = $_.FullName -replace [regex]::Escape($privateFunctionsPath), $moduleOutputPath
        Copy-Item -Path $_.FullName -Destination $destinationPath -Force -Verbose:$verbosePreference
    }

    # Public directory
    Get-ChildItem -Path $publicFunctionsPath -Recurse |
        ? Extension -notin @(".ps1", ".gitignore", ".gitkeep") | foreach {
        $destinationPath = $_.FullName -replace [regex]::Escape($publicFunctionsPath), $moduleOutputPath
        Copy-Item -Path $_.FullName -Destination $destinationPath -Force -Verbose:$verbosePreference
    }

    # Root directory
    Get-ChildItem -Path $PSScriptRoot -File |
        ? Name -notin @("$moduleName.psd1", "build.ps1") |
        ? Extension -notin @(".gitignore", ".gitkeep") | foreach {
            Copy-Item -Path $_.FullName -Destination $moduleOutputPath -Force -Verbose:$verbosePreference
        }
    
    Get-ChildItem -Path $PSScriptRoot -Directory |
        ? Name -notin @("classes", "private", "public", "build") | foreach {
            Copy-Item -Path $_.FullName -Destination $moduleOutputPath -Force -Verbose:$verbosePreference
        }

    Get-ChildItem -Path $PSScriptRoot -Directory |
        ? Name -notin @("classes", "private", "public", "build") | 
        Get-ChildItem -Recurse |
        ? extension -notin @(".ps1", ".gitignore", ".gitkeep") |
        foreach {
            $destinationPath = $_.FullName -replace [regex]::Escape($PSScriptRoot), $moduleOutputPath
            Copy-Item -Path $_.FullName -Destination $destinationPath -Force -Verbose:$verbosePreference
        }

    # Module psm1 build
}