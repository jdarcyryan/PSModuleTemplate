BeforeAll {
    # Dynamically find the module in the .output folder
    $outputPath = Join-Path $PSScriptRoot '.output'
    $moduleFolders = Get-ChildItem -Path $outputPath -Directory -ErrorAction SilentlyContinue
    
    if (-not $moduleFolders) {
        throw 'No module folder found in .output directory'
    }
    
    if ($moduleFolders.Count -gt 1) {
        throw 'Multiple module folders found in .output directory. Expected only one.'
    }
    
    $script:ModulePath = $moduleFolders[0].FullName
    $script:ModuleName = $moduleFolders[0].Name
    
    # Find the module manifest
    $manifestPath = Join-Path $ModulePath "$ModuleName.psd1"
    if (-not (Test-Path $manifestPath)) {
        throw "Module manifest not found at: $manifestPath"
    }
    
    # Import the module
    Import-Module $manifestPath -Force -ErrorAction Stop
    
    # Get all function files
    $publicPath = Join-Path $ModulePath 'Public'
    $privatePath = Join-Path $ModulePath 'Private'
    
    $script:PublicFunctions = @()
    $script:PrivateFunctions = @()
    
    if (Test-Path $publicPath) {
        $script:PublicFunctions = Get-ChildItem -Path $publicPath -Filter '*.ps1' -Recurse -File
    }
    
    if (Test-Path $privatePath) {
        $script:PrivateFunctions = Get-ChildItem -Path $privatePath -Filter '*.ps1' -Recurse -File
    }
    
    # Get approved verbs for validation
    $script:ApprovedVerbs = Get-Verb | select -ExpandProperty Verb
}

Describe 'Function Naming Conventions' {
    Context 'Public Functions' {
        It 'should have public functions' -Skip:($script:PublicFunctions.Count -eq 0) {
            $script:PublicFunctions.Count | should -BeGreaterThan 0
        }
        
        foreach ($functionFile in $script:PublicFunctions) {
            It "Public function '$($functionFile.BaseName)' should use Verb-Noun naming convention" {
                # Check if name contains a hyphen
                $functionFile.BaseName | should -match '-'
                
                # Split on hyphen and validate verb
                $parts = $functionFile.BaseName -split '-', 2
                $verb = $parts[0]
                $noun = $parts[1]
                
                # Verb should be an approved PowerShell verb
                $script:ApprovedVerbs | should -contain $verb -Because 'function uses approved verb'
                
                # Noun should exist and not be empty
                $noun | should -not -BeNullOrEmpty
            }
        }
    }
    
    Context 'Private Functions' {
        It 'should have private functions' -Skip:($script:PrivateFunctions.Count -eq 0) {
            $script:PrivateFunctions.Count | should -BeGreaterThan 0
        }
        
        foreach ($functionFile in $script:PrivateFunctions) {
            It "Private function '$($functionFile.BaseName)' should use Verb-Noun naming convention" {
                # Check if name contains a hyphen
                $functionFile.BaseName | should -match '-'
                
                # Split on hyphen and validate verb
                $parts = $functionFile.BaseName -split '-', 2
                $verb = $parts[0]
                $noun = $parts[1]
                
                # Verb should be an approved PowerShell verb
                $script:ApprovedVerbs | should -contain $verb -Because 'function uses approved verb'
                
                # Noun should exist and not be empty
                $noun | should -not -BeNullOrEmpty
            }
        }
    }
}

AfterAll {
    # Clean up - remove the imported module
    Remove-Module $script:ModuleName -ErrorAction SilentlyContinue
}
