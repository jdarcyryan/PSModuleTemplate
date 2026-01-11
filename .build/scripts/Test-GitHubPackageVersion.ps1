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
    
    if (-not $nupkg) {
        throw 'No .nupkg file found in .output directory.'
    }
    
    Write-Verbose "Found package '$($nupkg.Name)'."
    
    $filename = $nupkg.Name
    
    if ($filename -match '\.(\d+\.\d+\.\d+(?:\.\d+)?(?:-[\w\.-]+)?)\.nupkg$') {
        $version = $Matches[1]
    }
    else {
        throw "Could not extract version from filename '$filename'."
    }
    
    $packageName = $filename -replace '\.\d+\.\d+\.\d+.*?\.nupkg$', ''
    
    Write-Verbose "Package: $packageName"
    Write-Verbose "Version: $version"
    
    # Check GitHub Packages using REST API
    $headers = @{
        Authorization = "Bearer $Token"
        Accept        = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    
    Write-Verbose 'Checking GitHub Packages...'
    
    try {
        # Try multiple endpoints to find packages
        $packagesUris = @(
            "https://api.github.com/orgs/$Owner/packages?package_type=nuget",
            "https://api.github.com/users/$Owner/packages?package_type=nuget",
            "https://api.github.com/repos/$Owner/$Repository/packages?package_type=nuget"
        )
        
        $package = $null
        $packagesResponse = $null
        $workingUri = $null
        
        foreach ($packagesUri in $packagesUris) {
            try {
                Write-Verbose "Trying packages endpoint: $packagesUri"
                $packagesResponse = Invoke-RestMethod -Uri $packagesUri -Headers $headers -ErrorAction Stop
                
                Write-Verbose "Response contains $($packagesResponse.Count) packages"
                
                # Find the specific package
                $package = $packagesResponse | where { $_.name -eq $packageName }
                
                if ($package) {
                    Write-Verbose "Found package '$packageName' in GitHub Packages at endpoint: $packagesUri"
                    $workingUri = $packagesUri
                    break
                }
                else {
                    Write-Verbose "Package '$packageName' not found in this endpoint"
                }
            }
            catch {
                $statusCode = [int]$_.Exception.Response.StatusCode
                if ($statusCode -eq 404) {
                    Write-Verbose "Endpoint not found: $packagesUri"
                    continue
                }
                else {
                    throw
                }
            }
        }
        
        if ($package) {
            # Determine the correct versions endpoint based on which packages endpoint worked
            $versionsUri = $null
            if ($workingUri -like '*orgs/*') {
                $versionsUri = "https://api.github.com/orgs/$Owner/packages/nuget/$packageName/versions"
            }
            elseif ($workingUri -like '*users/*') {
                $versionsUri = "https://api.github.com/users/$Owner/packages/nuget/$packageName/versions"
            }
            elseif ($workingUri -like '*repos/*') {
                $versionsUri = "https://api.github.com/repos/$Owner/$Repository/packages/nuget/$packageName/versions"
            }
            
            if ($versionsUri) {
                try {
                    Write-Verbose "Getting versions from: $versionsUri"
                    $versionsResponse = Invoke-RestMethod -Uri $versionsUri -Headers $headers -ErrorAction Stop
                    
                    $existingVersions = $versionsResponse | foreach { $_.name }
                    
                    Write-Verbose "Found existing versions: $($existingVersions -join ', ')"
                    
                    if ($existingVersions -contains $version) {
                        throw "Version '$version' already exists in GitHub Packages."
                    }
                    
                    # Check if current version is later than latest existing version
                    if ($existingVersions.Count -gt 0) {
                        $latestVersion = $existingVersions | sort { [Version]($_ -replace '-.*$', '') } | select -Last 1
                        
                        $currentVersionParsed = [Version]($version -replace '-.*$', '')
                        $latestVersionParsed = [Version]($latestVersion -replace '-.*$', '')
                        
                        if ($currentVersionParsed -le $latestVersionParsed) {
                            throw "Current version '$version' is not later than the latest existing version '$latestVersion' in GitHub Packages."
                        }
                        
                        Write-Verbose "Current version '$version' is later than latest existing version '$latestVersion'."
                    }
                    
                    Write-Verbose "Version '$version' does not exist in GitHub Packages."
                }
                catch {
                    $statusCode = [int]$_.Exception.Response.StatusCode
                    if ($statusCode -eq 404) {
                        Write-Verbose 'Package versions not found (empty package).'
                    }
                    else {
                        throw
                    }
                }
            }
            else {
                throw 'Could not determine correct versions endpoint.'
            }
        }
        else {
            Write-Verbose 'Package not found in GitHub Packages (new package).'
        }
    }
    catch {
        $statusCode = [int]$_.Exception.Response.StatusCode
        
        if ($statusCode -eq 401 -or $statusCode -eq 403) {
            throw 'Failed to connect to GitHub Packages. Authentication failed. Check your token permissions.'
        }
        else {
            throw "Failed to connect to GitHub Packages: '$($_.Exception.Message)'."
        }
    }
    
    # Check GitHub Releases
    $releasesUri = "https://api.github.com/repos/$Owner/$Repository/releases"
    
    Write-Verbose 'Checking GitHub Releases...'
    
    try {
        $releasesResponse = Invoke-RestMethod -Uri $releasesUri -Headers $headers -ErrorAction Stop
        $existingReleaseTags = $releasesResponse | foreach {
            $_.tag_name
        }
        
        $versionTag = $version
        
        if ($existingReleaseTags -contains $version -or $existingReleaseTags -contains $versionTag) {
            throw "Version '$version' already exists in GitHub Releases."
        }
        
        Write-Verbose "Version '$version' does not exist in GitHub Releases."
    }
    catch {
        $statusCode = [int]$_.Exception.Response.StatusCode
        
        if ($statusCode -eq 404) {
            Write-Verbose 'No releases found (new repository).'
        }
        elseif ($statusCode -eq 401 -or $statusCode -eq 403) {
            throw 'Failed to connect to GitHub Releases, Authentication failed. Check your token permissions.'
        }
        else {
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
