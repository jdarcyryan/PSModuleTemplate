# This section is reserved for custom steps that run after the module has been built
# to the output directory. Examples include:
#
#   - Copying compiled DLLs or native binaries into the output module folder
#   - Generating or embedding additional metadata files
#   - Running post-compilation validation or smoke tests
#   - Signing output binaries or the module manifest
#   - Packaging additional assets to include in the nupkg

# Paths
$gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
$outputRoot = "$gitRoot\.output"
$moduleName = (Get-Item -Path $gitRoot).Name
$moduleVersion = . {
    $manifestPath = "$gitRoot\$moduleName\$moduleName.psd1"
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    $manifest.ModuleVersion
}.GetNewClosure()

# Path where module is built before nupkg pack
$outputModulePath = "$outputRoot\$moduleName\$moduleVersion"
