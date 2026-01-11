[CmdletBinding(SupportsShouldProcess)]
<#
    .SYNOPSIS
    Publishes a PowerShell module to GitHub Packages.

    .DESCRIPTION
    Publishes the built module package to GitHub Packages.
    Throws an error if the package version already exists.

    .PARAMETER Owner
    GitHub repository owner (user or organization).
    If not provided, uses GITHUB_OWNER environment variable.

    .PARAMETER Repository
    GitHub repository name.
    If not provided, uses GITHUB_REPOSITORY environment variable.

    .PARAMETER Token
    GitHub Personal Access Token with package write permissions.
    If not provided, uses GITHUB_TOKEN environment variable.

    .PARAMETER Force
    Suppresses confirmation prompts during package publishing.
#>
param(
    [ValidateNotNullOrEmpty()]
    [string]
    $Owner = $env:GITHUB_OWNER,
    
    [ValidateNotNullOrEmpty()]
    [string]
    $Repository = $env:GITHUB_REPOSITORY,
    
    [ValidateNotNullOrEmpty()]
    [string]
    $Token = $env:GITHUB_TOKEN,

    [switch]
    $Force
)

$ErrorActionPreference = 'Stop'

# Pre-import PackageManagement to avoid verbose output during publish
Import-Module -Name PackageManagement -Force -Verbose:$false -WarningAction SilentlyContinue > $null

function Publish-GitHubModule {
    [CmdletBinding(SupportsShouldProcess)]
    <#
        .SYNOPSIS
        Publishes a PowerShell module to GitHub Packages.

        .DESCRIPTION
        Publishes the built module package to GitHub Packages.
        Throws an error if the package version already exists.

        .PARAMETER Owner
        GitHub repository owner (user or organization).

        .PARAMETER Repository
        GitHub repository name.

        .PARAMETER Token
        GitHub Personal Access Token with package write permissions.

        .PARAMETER Force
        Suppresses confirmation prompts during package publishing.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $Owner = $env:GITHUB_OWNER,
        
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository = $env:GITHUB_REPOSITORY,
        
        [ValidateNotNullOrEmpty()]
        [string]
        $Token = $env:GITHUB_TOKEN,

        [switch]
        $Force
    )

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
    $moduleName = Split-Path -Path $gitRoot -Leaf
    $outputPath = "$gitRoot\.output"

    # Verify output directory exists
    if (-not (Test-Path -Path $outputPath)) {
        throw "Output directory not found at: '$outputPath', run 'make build' to build the module first."
    }

    # Find the .nupkg file
    $nupkgFiles = Get-ChildItem -Path $outputPath -Filter "*.nupkg" -File
    if (-not $nupkgFiles) {
        throw "No .nupkg file found in '$outputPath', run 'make build' to build the module first."
    }

    if ($nupkgFiles.Count -gt 1) {
        throw "Multiple .nupkg files found in '$outputPath'. Expected only one package file."
    }

    $nupkgFile = $nupkgFiles[0]
    $version = $nupkgFile.BaseName -replace "^$moduleName\.", ''

    Write-Verbose "Found package: $($nupkgFile.Name)"
    Write-Verbose "Module: $moduleName"
    Write-Verbose "Version: $version"
    Write-Verbose "Owner: $Owner"
    Write-Verbose "Repository: $Repository"

    # Construct GitHub Packages NuGet source URL
    $sourceUrl = "https://nuget.pkg.github.com/$Owner/index.json"
    $repositoryName = 'GitHubPackages'

    # Get GitHub credential object for PSResourceGet
    $ghCredential = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]::new(
        $sourceUrl,
        [pscredential]::new($Owner, (ConvertTo-SecureString $Token -AsPlainText -Force))
    )

    # Check if package already exists in GitHub Packages
    try {
        $savedGlobalVerbose = $global:VerbosePreference

        $existingPackage = & {
            $VerbosePreference = 'SilentlyContinue'
            $global:VerbosePreference = 'SilentlyContinue'
            $ProgressPreference = 'SilentlyContinue'

            # Register temporary repository to check for existing package
            Register-PSResourceRepository -Name $repositoryName -Uri $sourceUrl -Trusted -CredentialInfo $ghCredential -ErrorAction SilentlyContinue > $null

            try {
                Find-PSResource -Name $moduleName -Version $version -Repository $repositoryName -CredentialInfo $ghCredential -ErrorAction SilentlyContinue
            }
            finally {
                Unregister-PSResourceRepository -Name $repositoryName -ErrorAction SilentlyContinue > $null
            }
        }

        $global:VerbosePreference = $savedGlobalVerbose

        if ($existingPackage) {
            throw "Package '$moduleName' version '$version' already exists in GitHub Packages. Increment the version in the manifest to publish a new version."
        }
    }
    catch {
        # If error is about package already existing, rethrow it
        if ($_.Exception.Message -match 'already exists') {
            throw
        }
        # Otherwise just log that we couldn't check (package probably doesn't exist)
        Write-Verbose "Could not check for existing package: $_"
    }

    # Publish to GitHub Packages (run in isolated scope to suppress all output)
    if ($PSCmdlet.ShouldProcess($nupkgFile.FullName, 'Publish to GitHub Packages')) {
        $savedGlobalVerbose = $global:VerbosePreference

        & {
            $VerbosePreference = 'SilentlyContinue'
            $global:VerbosePreference = 'SilentlyContinue'
            $ProgressPreference = 'SilentlyContinue'
            $ConfirmPreference = 'None'
            $WhatIfPreference = $false

            # Register GitHub Packages repository
            Register-PSResourceRepository -Name $repositoryName -Uri $sourceUrl -Trusted -CredentialInfo $ghCredential > $null

            try {
                # Publish nupkg file
                Publish-PSResource -Path $nupkgFile.FullName -Repository $repositoryName -CredentialInfo $ghCredential > $null
            }
            finally {
                Unregister-PSResourceRepository -Name $repositoryName > $null
            }
        }

        $global:VerbosePreference = $savedGlobalVerbose

        Write-Verbose "Module published successfully to GitHub Packages"
        Write-Verbose "Package URL: https://github.com/$Owner/$Repository/packages"
    }
}

try {
    Publish-GitHubModule @PSBoundParameters
}
catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
}
