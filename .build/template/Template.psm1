#region Authoring

###########################################################################
# PSModuleTemplate
# Author:  James D'Arcy Ryan
# GitHub:  https://github.com/jdarcyryan/PSModuleTemplate
# License: https://github.com/jdarcyryan/PSModuleTemplate/blob/main/LICENSE
#
# A standardized template for creating PowerShell modules with support for
# classes (PowerShell and C#), private functions, and public functions with
# automatic discovery and export of commands and aliases.
#
# LEGAL NOTICE:
# The license referenced above applies to the PSModuleTemplate repository
# and template structure only. Any module created using this template is
# subject to its own license as specified in the module's LICENSE file,
# which supersedes the template license for that specific module.
###########################################################################

#region Authoring

#region Classes

$classesPath = "$PSScriptRoot\classes"
$classesDataFilePath = "$classesPath\classes.psd1"

if (Test-Path -Path $classesDataFilePath) {
    $classes = (Import-PowerShellDataFile -Path $classesDataFilePath).classes

    $classes | foreach {
        $currentClassPath = "$classesPath\$_"

        if (!(Test-Path -Path $currentClassPath)) {
            throw "Class '$_' does not exist."
        }

        $extension = (Get-Item -Path $currentClassPath).Extension

        switch ($extension) {
            '.ps1' {
                # Process standard classes
                . $currentClassPath
            }
            '.cs' {
                # Process CSharp classes
                Add-Type -Path $currentClassPath -Language CSharp
            }
            default {
                throw "Unable to process class '$_', $extension is an unsupported file type."
            }
        }
    }
}

#endregion Classes

#region Private

$privatePath = "$PSScriptRoot\private"

if (Test-Path -Path $privatePath) {
    Get-ChildItem -Path $privatePath -Filter '*.ps1' | where PSIsContainer -eq $false | foreach {
        . $_.FullName
    }
}

#endregion Private

#region Public

$publicPath = "$PSScriptRoot\public"

if (Test-Path -Path $publicPath) {
    Get-ChildItem -Path $publicPath -Filter '*.ps1' | where PSIsContainer -eq $false | foreach {
        . $_.FullName
    }
}

#endregion Public
