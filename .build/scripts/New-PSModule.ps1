[CmdletBinding(SupportsShouldProcess)]
<#
    .SYNOPSIS
    Creates a new PowerShell module from a template.

    .PARAMETER Force
    Suppresses confirmation prompts during module creation.
#>
param(
    [switch]
    $Force
)

$ErrorActionPreference = 'Stop'

function New-PSModule {
    <#
        .SYNOPSIS
        Creates a new PowerShell module from a template.

        .PARAMETER Force
        Suppresses confirmation prompts during module creation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]
        $Force
    )

    if ($Force) {
        $ConfirmPreference = 'None'
    }

    $templateFolderPath = Resolve-Path -Path "$PSScriptRoot\..\template"
    $templateModuleFilePath = "$templateFolderPath\Template.psm1"
    $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
    $moduleName = Split-Path -Path $gitRoot -Leaf

    $modulePath = "$gitRoot\$moduleName"
    $moduleFilePath = "$modulePath\$moduleName.psm1"
    $manifestFilePath = "$modulePath\$moduleName.psd1"

    # Create module directory
    if (-not (Test-Path -Path $modulePath -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($modulePath, 'Create directory')) {
            New-Item -Path $modulePath -ItemType Directory -Confirm:$false -WhatIf:$false > $null
        }
    }

    # Copy template files
    Get-ChildItem -Path $templateFolderPath -Recurse | 
        where Name -ne 'Template.psm1' | 
        foreach {
            $relativePath = $_.FullName.Substring($templateFolderPath.Path.Length + 1)
            $destinationPath = "$modulePath\$relativePath"
            
            if ($_.PSIsContainer) {
                if (-not (Test-Path -Path $destinationPath)) {
                    if ($PSCmdlet.ShouldProcess($destinationPath, 'Create directory')) {
                        New-Item -Path $destinationPath -ItemType Directory -Confirm:$false -WhatIf:$false > $null
                    }
                }
            }
            else {
                # Skip .gitkeep if directory has other files or .gitkeep exists
                if ($_.Name -eq '.gitkeep') {
                    $gitkeepDir = Split-Path -Path $destinationPath -Parent
                    
                    if (Test-Path -Path $gitkeepDir) {
                        $hasFiles = Get-ChildItem -Path $gitkeepDir -Recurse -File | 
                            where Name -ne '.gitkeep' | 
                            select -First 1
                        
                        if ($hasFiles) {
                            return
                        }
                    }
                    
                    if (Test-Path -Path $destinationPath) {
                        return
                    }
                }
                
                $exists = Test-Path -Path $destinationPath
                $action = if ($exists) {
                    'Overwrite file'
                }
                else {
                    'Create file'
                }
                
                if ($exists) {
                    if ($PSCmdlet.ShouldProcess($destinationPath, $action)) {
                        if ($ConfirmPreference -eq 'None' -or $PSCmdlet.ShouldContinue('Overwrite existing file?', $destinationPath)) {
                            $parentDir = Split-Path -Path $destinationPath -Parent
                            if (-not (Test-Path -Path $parentDir)) {
                                New-Item -Path $parentDir -ItemType Directory -Force -Confirm:$false -WhatIf:$false > $null
                            }
                            Copy-Item -Path $_.FullName -Destination $destinationPath -Force -Confirm:$false -WhatIf:$false
                        }
                    }
                }
                else {
                    if ($PSCmdlet.ShouldProcess($destinationPath, $action)) {
                        $parentDir = Split-Path -Path $destinationPath -Parent
                        if (-not (Test-Path -Path $parentDir)) {
                            New-Item -Path $parentDir -ItemType Directory -Force -Confirm:$false -WhatIf:$false > $null
                        }
                        Copy-Item -Path $_.FullName -Destination $destinationPath -Force -Confirm:$false -WhatIf:$false
                    }
                }
            }
        }

    # Copy Template.psm1 to module file
    $moduleFileExists = Test-Path -Path $moduleFilePath
    $action = if ($moduleFileExists) {
        'Overwrite file'
    } else {
        'Create file'
    }
    
    if ($moduleFileExists) {
        if ($PSCmdlet.ShouldProcess($moduleFilePath, $action)) {
            if ($ConfirmPreference -eq 'None' -or $PSCmdlet.ShouldContinue('Overwrite existing file?', $moduleFilePath)) {
                Copy-Item -Path $templateModuleFilePath -Destination $moduleFilePath -Force -Confirm:$false -WhatIf:$false
            }
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess($moduleFilePath, $action)) {
            Copy-Item -Path $templateModuleFilePath -Destination $moduleFilePath -Force -Confirm:$false -WhatIf:$false
        }
    }

    # Create module manifest
    $manifestExists = Test-Path -Path $manifestFilePath
    $action = if ($manifestExists) {
        'Overwrite manifest'
    }
    else {
        'Create manifest'
    }
    
    if ($manifestExists) {
        if ($PSCmdlet.ShouldProcess($manifestFilePath, $action)) {
            if ($ConfirmPreference -eq 'None' -or $PSCmdlet.ShouldContinue('Overwrite existing manifest?', $manifestFilePath)) {
                New-ModuleManifest -Path $manifestFilePath -ModuleVersion '0.1.0' -RootModule "$moduleName.psm1" -Confirm:$false -WhatIf:$false
            }
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess($manifestFilePath, $action)) {
            New-ModuleManifest -Path $manifestFilePath -ModuleVersion '0.1.0' -RootModule "$moduleName.psm1" -Confirm:$false -WhatIf:$false
        }
    }
}

try {
    New-PSModule @PSBoundParameters
}
catch {
    Write-Host "$_" -ForegroundColor Red
    exit 1
}
