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

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Build", "Setup", "Ship")]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'

#region Standard Definitions
# Get module name from the root directory
$ModuleName = (Get-Item $PSScriptRoot).Name
$ModuleManifestPath = Join-Path -Path $PSScriptRoot -ChildPath "$ModuleName.psd1"

Write-Verbose "Module Name: '$ModuleName'"
Write-Verbose "Module Manifest Path: '$ModuleManifestPath'"
#endregion

#region Setup Mode - Create Module Manifest
if ($Mode -eq "Setup") {
    Write-Verbose "Running in Setup mode - creating module manifest"
    
    if (Test-Path -Path $ModuleManifestPath -PathType Leaf) {
        Write-Verbose "Module manifest already exists at '.\$ModuleName.psd1', skipping creation."
    }
    elseif (Test-Path -Path $ModuleManifestPath -PathType Container) {
        throw "The path '$ModuleManifestPath' is a directory, not a file."
    }
    else {
        New-ModuleManifest -Path $ModuleManifestPath -RootModule "$ModuleName.psm1" -ModuleVersion "1.0.0"
        Write-Verbose "Module manifest created at '.\$ModuleName.psd1'"
    }
}
#endregion

#region Build and Ship Modes - Compile Module
if ($Mode -in @("Build", "Ship")) {
    Write-Verbose "Running in $Mode mode - compiling module"
    
    #region Build Directory Setup
    $BuildRootPath = Join-Path -Path $PSScriptRoot -ChildPath "build"
    $BuildOutputPath = Join-Path -Path $BuildRootPath -ChildPath "output"

    # Clean up any previous build artifacts
    if (Test-Path -Path $BuildOutputPath) {
        Write-Verbose "Cleaning up previous build output at '$BuildOutputPath'"
        Remove-Item -Path $BuildOutputPath -Recurse -Force
    }

    # Create fresh build output directory
    $null = New-Item -Path $BuildOutputPath -ItemType Directory
    Write-Verbose "Created build output directory: '$BuildOutputPath'"
    #endregion

    #region Version Management
    # Import current manifest data
    Write-Verbose "Importing module manifest data from '$ModuleManifestPath'"
    $CurrentManifestData = Import-PowerShellDataFile -Path $ModuleManifestPath

    if ($Mode -eq "Ship") {
        # For shipping, use environment variable set by CI/CD pipeline
        if (-not $env:PSModuleVersion) {
            throw "Environment variable 'PSModuleVersion' is not set. Required for Ship mode."
        }
        $ModuleVersion = $env:PSModuleVersion
        Write-Verbose "Using CI/CD version for shipping: '$ModuleVersion'"
    }
    else {
        # For building, use version from manifest
        $ModuleVersion = $CurrentManifestData.ModuleVersion
        Write-Verbose "Using manifest version for building: '$ModuleVersion'"
    }
    #endregion

    #region Output Directory Structure
    # Create versioned module output directory
    $ModuleOutputPath = Join-Path -Path $BuildOutputPath -ChildPath "$ModuleName\$ModuleVersion"
    Write-Verbose "Creating versioned module output path: '$ModuleOutputPath'"
    $null = New-Item -Path $ModuleOutputPath -ItemType Directory -Force

    # Create the main module file (.psm1)
    $OutputModuleFilePath = Join-Path -Path $ModuleOutputPath -ChildPath "$ModuleName.psm1"
    $null = New-Item -Path $OutputModuleFilePath -ItemType File -Force
    Write-Verbose "Created module file: '$OutputModuleFilePath'"
    #endregion

    #region Manifest Processing
    # Copy and update manifest with correct version
    $OutputManifestPath = Join-Path -Path $ModuleOutputPath -ChildPath "$ModuleName.psd1"
    Copy-Item -Path $ModuleManifestPath -Destination $OutputManifestPath -Force
    
    # Update version in the copied manifest
    $ManifestContent = Get-Content -Path $OutputManifestPath -Raw
    $UpdatedManifestContent = $ManifestContent -replace "ModuleVersion\s*=\s*'[\d\.]+'", "ModuleVersion = '$ModuleVersion'"
    Set-Content -Path $OutputManifestPath -Value $UpdatedManifestContent -Force
    Write-Verbose "Updated module manifest version to '$ModuleVersion' at '$OutputManifestPath'"
    #endregion

    #region Source Directory Definitions
    $SourceDirectories = @{
        Classes = Join-Path -Path $PSScriptRoot -ChildPath "classes"
        Private = Join-Path -Path $PSScriptRoot -ChildPath "private"
        Public  = Join-Path -Path $PSScriptRoot -ChildPath "public"
    }
    
    $ClassesManifestPath = Join-Path -Path $SourceDirectories.Classes -ChildPath "classes.psd1"
    
    Write-Verbose "Source directories configured:"
    $SourceDirectories.GetEnumerator() | ForEach-Object { 
        Write-Verbose "  $($_.Key): '$($_.Value)'" 
    }
    #endregion

    #region File Copying Operations
    Write-Verbose "Copying non-PowerShell files to output directory"
    
    # Copy files from classes directory (excluding .ps1 files and the classes manifest)
    Get-ChildItem -Path $SourceDirectories.Classes -Recurse |
        Where-Object { $_.FullName -ne $ClassesManifestPath } |
        Where-Object { $_.Extension -notin @(".ps1", ".gitignore", ".gitkeep") } |
        ForEach-Object {
            $DestinationPath = $_.FullName -replace [regex]::Escape($SourceDirectories.Classes), $ModuleOutputPath
            Copy-Item -Path $_.FullName -Destination $DestinationPath -Force -Verbose:$VerbosePreference
        }
    
    # Copy files from private directory (excluding .ps1 files)
    Get-ChildItem -Path $SourceDirectories.Private -Recurse |
        Where-Object { $_.Extension -notin @(".ps1", ".gitignore", ".gitkeep") } |
        ForEach-Object {
            $DestinationPath = $_.FullName -replace [regex]::Escape($SourceDirectories.Private), $ModuleOutputPath
            Copy-Item -Path $_.FullName -Destination $DestinationPath -Force -Verbose:$VerbosePreference
        }

    # Copy files from public directory (excluding .ps1 files)
    Get-ChildItem -Path $SourceDirectories.Public -Recurse |
        Where-Object { $_.Extension -notin @(".ps1", ".gitignore", ".gitkeep") } |
        ForEach-Object {
            $DestinationPath = $_.FullName -replace [regex]::Escape($SourceDirectories.Public), $ModuleOutputPath
            Copy-Item -Path $_.FullName -Destination $DestinationPath -Force -Verbose:$VerbosePreference
        }

    # Copy files from root directory (excluding manifest and build script)
    $ExcludedRootFiles = @("$ModuleName.psd1", "build.ps1")
    $ExcludedRootExtensions = @(".gitignore", ".gitkeep")
    
    Get-ChildItem -Path $PSScriptRoot -File |
        Where-Object { $_.Name -notin $ExcludedRootFiles } |
        Where-Object { $_.Extension -notin $ExcludedRootExtensions } |
        ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $ModuleOutputPath -Force -Verbose:$VerbosePreference
        }
    
    # Copy additional directories (excluding build and source directories)
    $ExcludedDirectories = @("classes", "private", "public", "build", ".github")
    
    Get-ChildItem -Path $PSScriptRoot -Directory |
        Where-Object { $_.Name -notin $ExcludedDirectories } |
        ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $ModuleOutputPath -Recurse -Force -Verbose:$VerbosePreference
        }
    #endregion

    #region Module Content Assembly
    Write-Verbose "Assembling module content (.psm1 file)"
    
    #region Classes Processing
    Write-Verbose "Processing classes from '$ClassesManifestPath'"
    $ClassesManifestData = Import-PowerShellDataFile -Path $ClassesManifestPath
    
    # Get ordered list of class files based on manifest
    $ClassFilesToImport = $ClassesManifestData.Classes | ForEach-Object {
        Join-Path -Path $SourceDirectories.Classes -ChildPath $_
    } | Get-Item  # Validate files exist

    foreach ($ClassFile in $ClassFilesToImport) {
        Write-Verbose "Processing class file: $($ClassFile.FullName)"

        switch ($ClassFile.Extension) {
            ".ps1" { 
                # Standard PowerShell class
                Write-Verbose "Adding PowerShell class from '$($ClassFile.FullName)'"
                $ClassContent = Get-Content -Path $ClassFile.FullName -Raw
                "$ClassContent`n" | Add-Content -Path $OutputModuleFilePath -Force
            }
            
            { $_ -in @(".cs", ".vb") } { 
                # Compiled classes (C# or Visual Basic)
                $ClassType = switch ($ClassFile.Extension) {
                    ".cs" { "CSharp" }
                    ".vb" { "VisualBasic" }
                }
                
                Write-Verbose "Adding $ClassType class from '$($ClassFile.FullName)'"
                "Add-Type -Path `"`$PSScriptRoot\$($ClassFile.Name)`"`n" | Add-Content -Path $OutputModuleFilePath -Force
            }
            
            default { 
                throw "Unsupported class file '$($ClassFile.FullName)'. Supported extensions are .ps1, .cs, .vb"
            }
        }
    }
    #endregion

    #region Functions Processing
    Write-Verbose "Processing functions from private and public directories"

    $PublicFunctionNames = @()
    $AliasesToExport = @()

    # Process private functions first (internal functions)
    Get-ChildItem -Path $SourceDirectories.Private -File -Filter "*.ps1" | ForEach-Object {
        Write-Verbose "Adding private function from '$($_.FullName)'"
        $FunctionContent = Get-Content -Path $_.FullName -Raw
        "$FunctionContent`n" | Add-Content -Path $OutputModuleFilePath -Force
    }

    # Process public functions (exported functions)
    Get-ChildItem -Path $SourceDirectories.Public -File -Filter "*.ps1" | ForEach-Object {
        $FunctionName = $_.BaseName
        $PublicFunctionNames += $FunctionName
        
        Write-Verbose "Adding public function '$FunctionName' from '$($_.FullName)'"
        $FunctionContent = Get-Content -Path $_.FullName -Raw
        
        # Add the function content to the module
        "$FunctionContent`n" | Add-Content -Path $OutputModuleFilePath -Force
        
        # Extract aliases from Set-Alias commands
        $SetAliasMatches = [regex]::Matches($FunctionContent, "Set-Alias\s+[`"'-]?([^`"'\s]+)[`"'-]?\s+[`"'-]?$FunctionName[`"'-]?", "IgnoreCase")
        foreach ($Match in $SetAliasMatches) {
            $AliasName = $Match.Groups[1].Value
            $AliasesToExport += $AliasName
            Write-Verbose "Creating alias '$AliasName' for function '$FunctionName'"
            "New-Alias -Name '$AliasName' -Value '$FunctionName' -Force`n" | Add-Content -Path $OutputModuleFilePath -Force
        }
        
        # Extract aliases from [Alias()] attributes
        $AttributeAliasMatches = [regex]::Matches($FunctionContent, "\[Alias\([`"']([^`"']+)[`"']\)\]", "IgnoreCase")
        foreach ($Match in $AttributeAliasMatches) {
            $AliasName = $Match.Groups[1].Value
            $AliasesToExport += $AliasName
            Write-Verbose "Creating alias '$AliasName' for function '$FunctionName' (from [Alias] attribute)"
            "New-Alias -Name '$AliasName' -Value '$FunctionName' -Force`n" | Add-Content -Path $OutputModuleFilePath -Force
        }
    }

    # Remove duplicate aliases
    $AliasesToExport = $AliasesToExport | Sort-Object -Unique
    #endregion

    #region Module Exports
    Write-Verbose "Adding Export-ModuleMember statements"

    # Export public functions
    if ($PublicFunctionNames.Count -gt 0) {
        $FunctionExportString = $PublicFunctionNames -join ", "
        "Export-ModuleMember -Function $FunctionExportString`n" | Add-Content -Path $OutputModuleFilePath -Force
        Write-Verbose "Exporting functions: '$FunctionExportString'"
    }

    # Export aliases
    if ($AliasesToExport.Count -gt 0) {
        $AliasExportString = $AliasesToExport -join "', '"
        "Export-ModuleMember -Alias '$AliasExportString'`n" | Add-Content -Path $OutputModuleFilePath -Force
        Write-Verbose "Exporting aliases: '$($AliasesToExport -join ", ")'"
    }
    #endregion
    #endregion

    Write-Verbose "$Mode operation completed successfully. Output: '$ModuleOutputPath'"
}
#endregion
