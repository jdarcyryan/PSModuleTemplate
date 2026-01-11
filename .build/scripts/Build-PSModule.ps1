[CmdletBinding(SupportsShouldProcess)]
<#
    .SYNOPSIS
    Builds a PowerShell module to the .output directory.

    .PARAMETER Force
    Suppresses confirmation prompts during module build.
#>
param(
    [switch]
    $Force
)

function Build-PSModule {
    <#
        .SYNOPSIS
        Builds a PowerShell module to the .output directory.

        .PARAMETER Force
        Suppresses confirmation prompts during module build.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]
        $Force
    )

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
    $moduleName = Split-Path -Path $gitRoot -Leaf

    $modulePath = "$gitRoot\$moduleName"
    $manifestFilePath = "$modulePath\$moduleName.psd1"
    $outputPath = "$gitRoot\.output"

    # Verify module path exists
    if (!(Test-Path -Path $modulePath)) {
        throw "Module directory not found at: $modulePath"
    }

    # Verify module manifest exists
    if (!(Test-Path -Path $manifestFilePath)) {
        throw "Module manifest not found at: $manifestFilePath"
    }

    # Get version from manifest
    $manifest = Import-PowerShellDataFile -Path $manifestFilePath
    $version = $manifest.ModuleVersion
    if (!$version) {
        throw "ModuleVersion not found in manifest: $manifestFilePath"
    }

    $outputModulePath = "$outputPath\$moduleName\$version"

    # Handle existing .output directory
    if (Test-Path -Path $outputPath) {
        if ($PSCmdlet.ShouldProcess($outputPath, 'Overwrite output directory')) {
            if ($ConfirmPreference -eq 'None' -or $PSCmdlet.ShouldContinue('Delete and recreate output directory?', $outputPath)) {
                Remove-Item -Path $outputPath -Recurse -Force -Confirm:$false -WhatIf:$false
                New-Item -Path $outputModulePath -ItemType Directory -Force -Confirm:$false -WhatIf:$false > $null
            } else {
                return
            }
        } else {
            return
        }
    } else {
        New-Item -Path $outputModulePath -ItemType Directory -Force -Confirm:$false -WhatIf:$false > $null
    }

    # Copy module files to output
    $moduleFiles = Get-ChildItem -Path $modulePath -Recurse -ErrorAction SilentlyContinue
    
    if (!$moduleFiles) {
        Write-Warning "No files found in module directory: $modulePath"
        return
    }

    $moduleFiles | foreach {
        $relativePath = $_.FullName.Substring($modulePath.Length + 1)
        $destinationPath = "$outputModulePath\$relativePath"
        
        if ($_.PSIsContainer) {
            # Check if directory has files other than .gitkeep
            $hasFiles = Get-ChildItem -Path $_.FullName -Recurse -File | 
                where Name -ne '.gitkeep' | 
                select -First 1
            
            # Skip empty directories
            if (!$hasFiles) { return }
            
            if (!(Test-Path -Path $destinationPath)) {
                New-Item -Path $destinationPath -ItemType Directory -Confirm:$false -WhatIf:$false > $null
            }
        } else {
            # Skip .gitkeep files
            if ($_.Name -eq '.gitkeep') { return }
            
            $parentDir = Split-Path -Path $destinationPath -Parent
            if (!(Test-Path -Path $parentDir)) {
                New-Item -Path $parentDir -ItemType Directory -Force -Confirm:$false -WhatIf:$false > $null
            }
            Copy-Item -Path $_.FullName -Destination $destinationPath -Force -Confirm:$false -WhatIf:$false
        }
    }

    Write-Verbose "Module built successfully to: $outputModulePath"
}

Build-PSModule @PSBoundParameters
