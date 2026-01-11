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
}

Describe 'Private Function Help Documentation' {
    Context 'Synopsis Requirements' {
        foreach ($functionFile in $script:PrivateFunctions) {
            It "Private function '$($functionFile.BaseName)' should have a synopsis" {
                $functionContent = Get-Content -Path $functionFile.FullName -Raw
                
                # Check if function is defined in the file
                $functionContent | should -match "function\s+$($functionFile.BaseName)"
                
                # Try to get help for the function
                $help = Get-Help -Name $functionFile.BaseName -ErrorAction SilentlyContinue
                
                # Synopsis should exist and not be auto-generated
                $help | should -not -BeNullOrEmpty
                $help.Synopsis | should -not -BeNullOrEmpty
                $help.Synopsis | should -not -match $functionFile.BaseName -Because 'synopsis should not be just the function name'
            }
        }
    }
}

Describe 'Public Function Help Documentation' {
    Context 'Complete Help Requirements' {
        foreach ($functionFile in $script:PublicFunctions) {
            BeforeAll {
                $help = Get-Help -Name $functionFile.BaseName -Full -ErrorAction SilentlyContinue
            }
            
            It "Public function '$($functionFile.BaseName)' should have help documentation" {
                $help | should -not -BeNullOrEmpty
            }
            
            It "Public function '$($functionFile.BaseName)' should have a synopsis" {
                $help.Synopsis | should -not -BeNullOrEmpty
                $help.Synopsis | should -not -match $functionFile.BaseName -Because 'synopsis should not be just the function name'
            }
            
            It "Public function '$($functionFile.BaseName)' should have a description" {
                $help.Description | should -not -BeNullOrEmpty
                $help.Description.Text | should -not -BeNullOrEmpty
            }
            
            It "Public function '$($functionFile.BaseName)' should have at least one example" {
                $help.Examples | should -not -BeNullOrEmpty
                $help.Examples.Example.Count | should -BeGreaterOrEqual 1
                $help.Examples.Example[0].Code | should -not -BeNullOrEmpty
            }
            
            Context "Parameter Documentation for '$($functionFile.BaseName)'" {
                BeforeAll {
                    $parameters = $help.Parameters.Parameter | where Name -notin @('WhatIf', 'Confirm')
                }
                
                if ($parameters) {
                    foreach ($parameter in $parameters) {
                        It "Parameter '$($parameter.Name)' should have a description" {
                            $parameter.Description | should -not -BeNullOrEmpty
                            $parameter.Description.Text | should -not -BeNullOrEmpty
                        }
                    }
                } else {
                    It 'should have parameters or have no parameters requiring documentation' {
                        # This test passes if there are no parameters to document
                        $true | should -be $true
                    }
                }
            }
        }
    }
}

AfterAll {
    # Clean up - remove the imported module
    Remove-Module $script:ModuleName -ErrorAction SilentlyContinue
}
