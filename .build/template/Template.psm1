#region Classes

$classesDirectoryPath = "$PSScriptRoot\classes"
$classesDataFilePath = "$classesDirectoryPath\classes.psd1"

$classes = (Import-PowerShellDataFile -Path $classesDataFilePath).classes

$classes | foreach {
    $currentClassPath = "$classesDirectoryPath\$_"

    if (!(Test-Path -Path $currentClassPath)) {
        throw "Class '$_' does not exist."
    }

    $extension = (Get-Item -Path $currentClassPath).Extension

    switch ($extension) {
        '.ps1' {
            . $_
        }
        '.cs' {
            Add-Type -Path $_ -Language CSharp
        }
        default {
            throw "Unable to process class '$_', $exentsion is an unsupported file type."
        }
    }
}

#endregion Classes
