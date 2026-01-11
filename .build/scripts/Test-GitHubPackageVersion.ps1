[CmdletBinding(SupportsShouldProcess)]
<#
    .SYNOPSIS
        Checks if a package version exists in GitHub Packages or GitHub Releases.
    
    .PARAMETER Owner
        The GitHub organization or user name that owns the repository.
    
    .PARAMETER Repository
        The GitHub repository name where releases are published.
    
    .PARAMETER Token
        GitHub Personal Access Token or GITHUB_TOKEN with read:packages permission.
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$env:GITHUB_OWNER,
    
    [ValidateNotNullOrEmpty()]
    [string]$env:GITHUB_REPOSITORY,
    
    [ValidateNotNullOrEmpty()]
    [string]$env:GITHUB_TOKEN
)

$ErrorActionPreference = 'Stop'

function Test-GitHubPackageVersion {
    [CmdletBinding()]
    <#
        .SYNOPSIS
            Checks if a package version exists in GitHub Packages or GitHub Releases.
        
        .PARAMETER Owner
            The GitHub organization or user name that owns the repository.
        
        .PARAMETER Repository
            The GitHub repository name where releases are published.
        
        .PARAMETER Token
            GitHub Personal Access Token or GITHUB_TOKEN with read:packages permission.
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Owner,
        
        [ValidateNotNullOrEmpty()]
        [string]$Repository,
        
        [ValidateNotNullOrEmpty()]
        [string]$Token
    )
    
    $nupkg = Get-ChildItem -Path '.output' -Filter '*.nupkg' | select -First 1
    
    if (-not $nupkg)
    {
        throw 'No .nupkg file found in .output directory.'
    }
    
    Write-Verbose "Found package '$($nupkg.Name)'."
    
    $filename = $nupkg.Name
    
    if ($filename -match '\.(\d+\.\d+\.\d+(?:\.\d+)?(?:-[\w\.-]+)?)\.nupkg$')
    {
        $version = $Matches[1]
    }
    else
    {
        throw "Could not extract version from filename '$filename'."
    }
    
    $packageName = $filename -replace '\.\d+\.\d+\.\d+.*?\.nupkg$', ''
    
    Write-Verbose "Package: $packageName"
    Write-Verbose "Version: $version"
    
    $headers = @{
        Authorization = "Bearer $Token"
        Accept        = 'application/vnd.github+json'
    }
    
    # Check GitHub Packages
    $packagesUri = "https://api.github.com/orgs/$Owner/packages/nuget/$packageName/versions"
    
    Write-Verbose 'Checking GitHub Packages...'
    
    try
    {
        $packagesResponse = Invoke-RestMethod -Uri $packagesUri -Headers $headers -ErrorAction Stop
        $existingPackageVersions = $packagesResponse | foreach { $_.name }
        
        if ($existingPackageVersions -contains $version)
        {
            throw "Version '$version' already exists in GitHub Packages."
        }
        
        Write-Verbose "Version '$version' does not exist in GitHub Packages."
    }
    catch
    {
        $statusCode = [int]$_.Exception.Response.StatusCode
        
        if ($statusCode -eq 404)
        {
            Write-Verbose 'Package not found in GitHub Packages (new package).'
        }
        elseif ($statusCode -eq 401 -or $statusCode -eq 403)
        {
            throw 'Failed to connect to GitHub Packages, check your token has read:packages permission.'
        }
        else
        {
            throw "Failed to connect to GitHub Packages: '$($_.Exception.Message)'"
        }
    }
    
    # Check GitHub Releases
    $releasesUri = "https://api.github.com/repos/$Owner/$Repository/releases"
    
    Write-Verbose 'Checking GitHub Releases...'
    
    try
    {
        $releasesResponse = Invoke-RestMethod -Uri $releasesUri -Headers $headers -ErrorAction Stop
        $existingReleaseTags = $releasesResponse | foreach {
            $_.tag_name
        }
        
        $versionTag = $version
        
        if ($existingReleaseTags -contains $version -or $existingReleaseTags -contains $versionTag)
        {
            throw "Version '$version' already exists in GitHub Releases."
        }
        
        Write-Verbose "Version '$version' does not exist in GitHub Releases."
    }
    catch
    {
        $statusCode = [int]$_.Exception.Response.StatusCode
        
        if ($statusCode -eq 404)
        {
            Write-Verbose 'No releases found (new repository).'
        }
        elseif ($statusCode -eq 401 -or $statusCode -eq 403)
        {
            throw 'Failed to connect to GitHub Releases, Authentication failed. Check your token permissions.'
        }
        else
        {
            throw "Failed to connect to GitHub Releases: '$($_.Exception.Message)'."
        }
    }
    
    Write-Verbose "Version '$version' is safe to publish."
}

try {
    Test-GitHubPackageVersion @PSBoundParameters
}
catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
}
