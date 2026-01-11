#region Classes

$classesPath = "$PSScriptRoot\classes"
$classesDataFilePath = "$classesPath\classes.psd1"

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
            . $_
        }
        '.cs' {
            # Process CSharp classes
            Add-Type -Path $_ -Language CSharp
        }
        default {
            throw "Unable to process class '$_', $exentsion is an unsupported file type."
        }
    }
}

#endregion Classes

#region Private

$privatePath = "$PSScriptRoot"

#endregion Private