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

Get-ChildItem -Path $privatePath -Filter '*.ps1' | where PSIsContainer -eq $false | foreach {
    . $_.FullName
}

#endregion Private

#region Public

$publicPath = "$PSScriptRoot\public"

# Snapshots
$currentAlias = Get-Alias | select Name, ReferencedCommand
$currentCommands = (Get-Command).Name

Get-ChildItem -Path $publicPath -Filter '*.ps1' | where PSIsContainer -eq $false | foreach {
    . $_.FullName
}

# Find new aliases
$aliasToExport = Compare-Object $currentAlias (Get-Alias | select Name, ReferencedCommand) -Property Name, ReferencedCommand |
    where SideIndicator -eq '=>' |
    select -ExpandProperty InputObject

# Find new commands (InputObject is just the string name)
$commandsToExport = Compare-Object $currentCommands (Get-Command).Name |
    where SideIndicator -eq '=>' |
    where InputObject -notin $aliasToExport.ReferencedCommand |
    select -ExpandProperty InputObject

# Combine all functions and export
$allFunctions = @($commandsToExport) + @($aliasToExport.ReferencedCommand) | 
    where { $_ } | 
    select -Unique

if ($allFunctions -or $aliasToExport) {
    Export-ModuleMember -Function $allFunctions -Alias $aliasToExport.Name
}

#endregion Public
