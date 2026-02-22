<#
    .SYNOPSIS
    Checks if a PowerShell module version already exists in GitHub Packages.

    .DESCRIPTION
    Queries GitHub Packages to verify if the current module version already exists.
    Throws an error if the version is found, preventing duplicate releases.

    .PARAMETER Owner
    GitHub repository owner (user or organisation).
    If not provided, uses GITHUB_OWNER environment variable.

    .PARAMETER Repository
    GitHub repository name.
    If not provided, uses GITHUB_REPOSITORY environment variable.

    .PARAMETER Token
    GitHub Personal Access Token with package read permissions.
    If not provided, uses GITHUB_TOKEN environment variable.
#>
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]
    $Owner = $env:GITHUB_OWNER,
    
    [ValidateNotNullOrEmpty()]
    [string]
    $Repository = $env:GITHUB_REPOSITORY,
    
    [ValidateNotNullOrEmpty()]
    [string]
    $Token = $env:GITHUB_TOKEN
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

function Test-GitHubPackageVersion {
    [CmdletBinding()]
    <#
        .SYNOPSIS
        Checks if a PowerShell module version already exists in GitHub Packages.

        .DESCRIPTION
        Queries GitHub Packages to verify if the current module version already exists.
        Throws an error if the version is found, preventing duplicate releases.

        .PARAMETER Owner
        GitHub repository owner (user or organisation).

        .PARAMETER Repository
        GitHub repository name.

        .PARAMETER Token
        GitHub Personal Access Token with package read permissions.
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
        $Token = $env:GITHUB_TOKEN
    )

    $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
    $moduleName = Split-Path -Path $gitRoot -Leaf
    $manifestPath = "$gitRoot\$moduleName\$moduleName.psd1"

    # Verify module manifest exists
    if (-not (Test-Path -Path $manifestPath)) {
        throw "Module manifest not found at: '$manifestPath', run 'make setup' to initialise the module structure."
    }

    # Get version from manifest
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    $version = $manifest.ModuleVersion
    if (-not $version) {
        throw "ModuleVersion not found in manifest '$manifestPath'."
    }

    Write-Verbose "Checking if $moduleName version $version exists in GitHub Packages..."

    # Query GitHub Packages API
    $headers = @{
        'Authorization' = "Bearer $Token"
        'Accept' = 'application/vnd.github.v3+json'
    }

    $apiUrl = "https://api.github.com/users/$Owner/packages/nuget/$moduleName/versions"
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
        
        if ($response) {
            $existingVersion = $response | where name -eq $version | select -First 1
            
            if ($existingVersion) {
                throw "Package '$moduleName' version '$version' already exists in GitHub Packages. Increment the version in the manifest to publish a new version."
            }
        }
        
        Write-Verbose "Version $version is available for publishing."
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            # Package doesn't exist yet, which is fine
            Write-Verbose "Package '$moduleName' not found in GitHub Packages (first release)."
        }
        elseif ($_.Exception.Message -match 'already exists') {
            # Re-throw our custom error
            throw
        }
        else {
            throw "Failed to check GitHub Packages: $_"
        }
    }
}

try {
    Test-GitHubPackageVersion @PSBoundParameters
}
catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
}
