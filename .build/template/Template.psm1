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

#endregion Classes

#region Private

$privatePath = "$PSScriptRoot\private"

$privatePath | Get-ChildItem -Filter '*.ps1' | where PSIsContainer -eq $false | foreach {
    . $_.FullName
}

#endregion Private

#region Public

$publicPath = "$PSScriptRoot\public"

# Alias snapshot
$currentAlias = Get-Alias | select Name, ReferencedCommand

# Function snapshot
$currentCommands = (Get-Command).Name

$publicPath | Get-ChildItem -Filter '*.ps1' | where PSIsContainer -eq $false | foreach {
    . $_.FullName
}

# Exported commands and alias'
$aliasToExport = Compare-Object $currentAlias (Get-Alias) -Property Name, ReferencedCommand |
    where SideIndicator -eq '=>' |
    select -ExpandProperty InputObject

$commandsToExport = Compare-Object $currentCommands (Get-Command).Name |
    where SideIndicator -eq '=>' |
    where Name -notin $aliasToExport.ReferencedCommand |
    select -ExpandProperty InputObject

Export-ModuleMember -Function $aliasToExport.ReferencedCommand -Alias $aliasToExport.Name

Export-ModuleMember -Function $commandsToExport.Name

#endregion Public
