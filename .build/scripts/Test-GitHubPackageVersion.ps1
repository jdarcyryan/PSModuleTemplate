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
        [string]
        $Owner = $env:GITHUB_OWNER,
        
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository = $env:GITHUB_REPOSITORY,
        
        [ValidateNotNullOrEmpty()]
        [string]
        $Token = $env:GITHUB_TOKEN
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
    
    # Construct GitHub Packages NuGet source URL
    $sourceUrl = "https://nuget.pkg.github.com/$Owner/index.json"
    $sourceName = 'github-check'
    
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
            '--password', $Token,
            '--store-password-in-clear-text'
        )
        
        $addOutput = & dotnet @addSourceArgs 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add NuGet source: $addOutput"
        }

        # Check if package exists and get versions
        Write-Verbose "Checking package versions in GitHub Packages..."
        $searchArgs = @(
            'package', 'search', $packageName,
            '--source', $sourceName,
            '--exact-match'
        )
        
        $searchOutput = & dotnet @searchArgs 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $searchOutput) {
            # Package exists, get detailed version information
            $listArgs = @(
                'list', 'package', $packageName,
                '--source', $sourceName,
                '--include-prerelease'
            )
            
            $listOutput = & dotnet @listArgs 2>&1
            
            if ($LASTEXITCODE -eq 0 -and $listOutput) {
                # Parse versions from output
                $existingVersions = @()
                foreach ($line in $listOutput) {
                    if ($line -match "$packageName\s+(\d+\.\d+\.\d+(?:\.\d+)?(?:-[\w\.-]+)?)") {
                        $existingVersions += $Matches[1]
                    }
                }
                
                if ($existingVersions -contains $version) {
                    throw "Version '$version' already exists in GitHub Packages."
                }
                
                # Check if current version is later than latest existing version
                if ($existingVersions.Count -gt 0) {
                    $latestVersion = $existingVersions | Sort-Object { [System.Version]($_ -replace '-.*$', '') } | Select-Object -Last 1
                    
                    $currentVersionParsed = [System.Version]($version -replace '-.*$', '')
                    $latestVersionParsed = [System.Version]($latestVersion -replace '-.*$', '')
                    
                    if ($currentVersionParsed -le $latestVersionParsed) {
                        throw "Current version '$version' is not later than the latest existing version '$latestVersion' in GitHub Packages."
                    }
                    
                    Write-Verbose "Current version '$version' is later than latest existing version '$latestVersion'."
                }
                
                Write-Verbose "Version '$version' does not exist in GitHub Packages."
            }
        } else {
            Write-Verbose 'Package not found in GitHub Packages (new package).'
        }
    }
    finally {
        # Clean up - remove the source
        Write-Verbose "Removing GitHub Packages source..."
        & dotnet nuget remove source $sourceName 2>&1 | Out-Null
    }
    
    # Check GitHub Releases
    $headers = @{
        Authorization = "Bearer $Token"
        Accept        = 'application/vnd.github+json'
    }
    
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
