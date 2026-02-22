<#
    .SYNOPSIS
    Publishes a PowerShell module to GitHub Packages.

    .DESCRIPTION
    Publishes the built module package to GitHub Packages using dotnet nuget CLI.
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
[CmdletBinding(SupportsShouldProcess)]
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

function Publish-GitHubModule {
    [CmdletBinding(SupportsShouldProcess)]
    <#
        .SYNOPSIS
        Publishes a PowerShell module to GitHub Packages.

        .DESCRIPTION
        Publishes the built module package to GitHub Packages using dotnet nuget CLI.
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
    $sourceName = 'github'

    # Publish to GitHub Packages using dotnet nuget CLI
    if ($PSCmdlet.ShouldProcess($nupkgFile.FullName, 'Publish to GitHub Packages')) {
        try {
            # Remove source if it exists
            Write-Verbose "Removing existing GitHub source if present..."
            & dotnet nuget remove source $sourceName 2>&1 | Out-Null

            # Add GitHub Packages source
            Write-Verbose "Adding GitHub Packages source: $sourceUrl"
            $addSourceArgs = @(
                'nuget', 'add', 'source', $sourceUrl,
                '--name', $sourceName,
                '--username', $Owner,
                '--password', $Token
            )
            
            $addOutput = & dotnet @addSourceArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to add NuGet source: $addOutput"
            }

            # Push package
            Write-Verbose "Pushing package to GitHub Packages..."
            $pushArgs = @(
                'nuget', 'push', $nupkgFile.FullName,
                '--api-key', $Token,
                '--source', $sourceName
            )
            
            $pushOutput = & dotnet @pushArgs 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                # Check if error is about duplicate package
                if ($pushOutput -match 'already exists' -or $pushOutput -match 'conflict') {
                    throw "Package '$moduleName' version '$version' already exists in GitHub Packages. Increment the version in the manifest to publish a new version."
                }
                throw "Failed to push package: $pushOutput"
            }

            Write-Verbose "Module published successfully to GitHub Packages"
            Write-Verbose "Package URL: https://github.com/$Owner/$Repository/packages"

            # Set environment variables for release
            "module_name=$ModuleName" | Out-File -FilePath $env:GITHUB_ENV -Append
            "module_version=$version" | Out-File -FilePath $env:GITHUB_ENV -Append

            $nupkgHash = (Get-FileHash -Path $nupkgFile.FullName -Algorithm SHA256).Hash
            "nupkg_hash=$nupkgHash" | Out-File -FilePath $env:GITHUB_ENV -Append
            "nupkg_name=$($nupkgFile.Name)" | Out-File -FilePath $env:GITHUB_ENV -Append
        }
        finally {
            # Clean up - remove the source
            Write-Verbose "Removing GitHub Packages source..."
            & dotnet nuget remove source $sourceName 2>&1 | Out-Null
        }
    }
}

try {
    Publish-GitHubModule @PSBoundParameters
}
catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
}
