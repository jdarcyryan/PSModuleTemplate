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
    $templateModuleFilePath = "$templateFolderPath\Template.psd1"
    $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
    $moduleName = Split-Path -Path $gitRoot -Leaf

    $modulePath = "$gitRoot\$moduleName"
    $moduleFilePath = "$modulePath\$moduleName.psd1"

    if (!(Test-Path -Path $modulePath -PathType Container)) {
        New-Item -Path $modulePath -ItemType Directory > $null
    }

    # Copy everything except Template.psd1
    Get-ChildItem -Path $templateFolderPath | 
        where Name -ne 'Template.psd1' | 
        Copy-Item -Destination $modulePath -Recurse

    # Copy and rename Template.psd1
    Copy-Item -Path $templateModuleFilePath -Destination $moduleFilePath
}

New-PSModule @PSBoundParameters
