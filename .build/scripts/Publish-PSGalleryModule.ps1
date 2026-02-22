<#
    .SYNOPSIS
    Publishes a PowerShell module to PowerShell Gallery.

    .DESCRIPTION
    Downloads the latest release from GitHub and publishes the module package to PowerShell Gallery.
    Requires a PowerShell Gallery API key to be provided.

    .PARAMETER Owner
    GitHub repository owner (user or organisation).
    If not provided, uses GITHUB_OWNER environment variable.

    .PARAMETER Repository
    GitHub repository name.
    If not provided, uses GITHUB_REPOSITORY environment variable.

    .PARAMETER Token
    GitHub Personal Access Token with repository read permissions.
    If not provided, uses GITHUB_TOKEN environment variable.

    .PARAMETER ApiKey
    PowerShell Gallery API key for publishing modules.
    If not provided, uses PSGALLERY_API_KEY environment variable.

    .PARAMETER Force
    Suppresses confirmation prompts during module publishing.
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

    [ValidateNotNullOrEmpty()]
    [string]
    $ApiKey = $env:PSGALLERY_API_KEY,

    [switch]
    $Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Publish-PSGalleryModule {
    [CmdletBinding(SupportsShouldProcess)]
    <#
        .SYNOPSIS
        Publishes a PowerShell module to PowerShell Gallery.

        .DESCRIPTION
        Downloads the latest release from GitHub and publishes the module package to PowerShell Gallery.
        Requires a PowerShell Gallery API key to be provided.

        .PARAMETER Owner
        GitHub repository owner (user or organisation).

        .PARAMETER Repository
        GitHub repository name.

        .PARAMETER Token
        GitHub Personal Access Token with repository read permissions.

        .PARAMETER ApiKey
        PowerShell Gallery API key for publishing modules.

        .PARAMETER Force
        Suppresses confirmation prompts during module publishing.
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

        [ValidateNotNullOrEmpty()]
        [string]
        $ApiKey = $env:PSGALLERY_API_KEY,

        [switch]
        $Force
    )

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    # Validate required parameters
    if (-not $Owner) {
        throw 'GitHub owner is required. Set GITHUB_OWNER environment variable or provide -Owner parameter.'
    }

    if (-not $Repository) {
        throw 'GitHub repository is required. Set GITHUB_REPOSITORY environment variable or provide -Repository parameter.'
    }

    if (-not $Token) {
        throw 'GitHub token is required. Set GITHUB_TOKEN environment variable or provide -Token parameter.'
    }

    if (-not $ApiKey) {
        throw 'PowerShell Gallery API key is required. Set PSGALLERY_API_KEY environment variable or provide -ApiKey parameter.'
    }

    $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
    $tempPath = "$gitRoot\.temp"

    # Clean up temp directory if it exists
    if (Test-Path -Path $tempPath) {
        Remove-Item -Path $tempPath -Recurse -Force
    }

    New-Item -Path $tempPath -ItemType Directory -Force > $null

    try {
        # Get latest release from GitHub
        Write-Verbose "Getting latest release from GitHub..."
        $headers = @{
            'Authorization' = "Bearer $Token"
            'Accept' = 'application/vnd.github.v3+json'
        }

        $apiUrl = "https://api.github.com/repos/$Owner/$Repository/releases/latest"
        
        try {
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 404) {
                throw "No releases found for repository '$Owner/$Repository'. Create a release first."
            }
            throw "Failed to get latest release: $_"
        }

        Write-Verbose "Found release: $($release.tag_name)"

        # Find .nupkg asset
        $nupkgAsset = $release.assets | where name -like '*.nupkg' | select -First 1

        if (-not $nupkgAsset) {
            throw "No .nupkg file found in release '$($release.tag_name)'. Ensure the release contains a module package."
        }

        Write-Verbose "Found package: $($nupkgAsset.name)"

        # Download .nupkg file
        $nupkgPath = "$tempPath\$($nupkgAsset.name)"
        
        Write-Verbose "Downloading package from: $($nupkgAsset.browser_download_url)"
        
        try {
            Invoke-WebRequest -Uri $nupkgAsset.browser_download_url -OutFile $nupkgPath -Headers $headers
        }
        catch {
            throw "Failed to download package: $_"
        }

        if (-not (Test-Path -Path $nupkgPath)) {
            throw "Package download failed - file not found at: $nupkgPath"
        }

        # Extract module name and version from filename
        $packageName = [IO.Path]::GetFileNameWithoutExtension($nupkgAsset.name)
        $parts = $packageName -split '\.'
        
        if ($parts.Count -lt 4) {
            throw "Unable to parse module name and version from package: $($nupkgAsset.name)"
        }

        # Reconstruct module name (everything except last 3 parts which are version)
        $moduleName = ($parts[0..($parts.Count - 4)] -join '.')
        $version = ($parts[($parts.Count - 3)..($parts.Count - 1)] -join '.')

        Write-Verbose "Module: $moduleName"
        Write-Verbose "Version: $version"

        # Publish to PowerShell Gallery
        if ($PSCmdlet.ShouldProcess($nupkgPath, 'Publish to PowerShell Gallery')) {
            try {
                Write-Verbose "Publishing to PowerShell Gallery..."
                
                # Use Publish-Module with -Path pointing to extracted module
                # First extract the nupkg to get the module folder
                $extractPath = "$tempPath\extracted"
                New-Item -Path $extractPath -ItemType Directory -Force > $null

                # Rename .nupkg to .zip for extraction
                $zipPath = "$tempPath\package.zip"
                Copy-Item -Path $nupkgPath -Destination $zipPath

                # Extract the package
                Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

                # Find the module folder in extracted content
                $moduleFolder = Get-ChildItem -Path $extractPath -Directory | where Name -eq $moduleName | select -First 1

                if (-not $moduleFolder) {
                    throw "Module folder '$moduleName' not found in extracted package."
                }

                # Publish the module
                Publish-Module -Path $moduleFolder.FullName -NuGetApiKey $ApiKey -Repository PSGallery -Force:$Force -Verbose:$false

                Write-Host "Module '$moduleName' version '$version' published successfully to PowerShell Gallery." -ForegroundColor Green
            }
            catch {
                if ($_.Exception.Message -match 'already exists') {
                    throw "Module '$moduleName' version '$version' already exists in PowerShell Gallery. Increment the version to publish a new version."
                }
                throw "Failed to publish to PowerShell Gallery: $_"
            }
        }
    }
    finally {
        # Clean up temp directory
        if (Test-Path -Path $tempPath) {
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

try {
    Publish-PSGalleryModule @PSBoundParameters
}
catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
}
