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

    # Create module directory
    if (!(Test-Path -Path $modulePath -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($modulePath, "Create directory")) {
            New-Item -Path $modulePath -ItemType Directory -Confirm:$false -WhatIf:$false > $null
        }
    }

    # Copy everything except Template.psm1
    Get-ChildItem -Path $templateFolderPath -Recurse | 
        where Name -ne 'Template.psm1' | 
        foreach {
            $relativePath = $_.FullName.Substring($templateFolderPath.Path.Length + 1)
            $destinationPath = Join-Path -Path $modulePath -ChildPath $relativePath
            
            if ($_.PSIsContainer) {
                # Create directories - only show WhatIf for new directories
                if (!(Test-Path -Path $destinationPath)) {
                    if ($PSCmdlet.ShouldProcess($destinationPath, "Create directory")) {
                        New-Item -Path $destinationPath -ItemType Directory -Confirm:$false -WhatIf:$false > $null
                    }
                }
                # Skip existing directories entirely - no ShouldProcess call
            } else {
                # Skip .gitkeep files if they already exist
                if ($_.Name -eq '.gitkeep' -and (Test-Path -Path $destinationPath)) {
                    return
                }
                
                # Files - only confirm if overwriting
                $exists = Test-Path -Path $destinationPath
                $action = if ($exists) { "Overwrite file" } else { "Create file" }
                
                if ($PSCmdlet.ShouldProcess($destinationPath, $action)) {
                    $parentDir = Split-Path -Path $destinationPath -Parent
                    if (!(Test-Path -Path $parentDir)) {
                        New-Item -Path $parentDir -ItemType Directory -Force -Confirm:$false -WhatIf:$false > $null
                    }
                    Copy-Item -Path $_.FullName -Destination $destinationPath -Force -Confirm:$false -WhatIf:$false
                }
            }
        }

    # Copy and rename Template.psm1
    $moduleFileExists = Test-Path -Path $moduleFilePath
    $action = if ($moduleFileExists) { "Overwrite file" } else { "Create file" }
    
    if ($PSCmdlet.ShouldProcess($moduleFilePath, $action)) {
        Copy-Item -Path $templateModuleFilePath -Destination $moduleFilePath -Force -Confirm:$false -WhatIf:$false
    }
}

New-PSModule @PSBoundParameters
