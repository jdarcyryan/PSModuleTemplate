Describe 'Function Help Documentation' {
    BeforeDiscovery {
        # Find .output folder
        $outputPath = $null
        $searchPath = $PSScriptRoot
        for ($i = 0; $i -lt 3; $i++) {
            $testPath = "$searchPath\.output"
            if (Test-Path $testPath) {
                $outputPath = $testPath
                break
            }
            $searchPath = Split-Path $searchPath -Parent
        }

        if (-not $outputPath) {
            throw 'No .output folder found'
        }

        $moduleFolders = Get-ChildItem -Path $outputPath -Directory
        $moduleName = $moduleFolders[0].Name
        $moduleFolder = $moduleFolders[0].FullName
        $versionFolders = Get-ChildItem -Path $moduleFolder -Directory
        $modulePath = $versionFolders[0].FullName

        $publicPath = "$modulePath\Public"
        $privatePath = "$modulePath\Private"

        $script:PublicFunctions = @()
        $script:PrivateFunctions = @()

        if (Test-Path $publicPath) {
            $script:PublicFunctions = @(Get-ChildItem -Path $publicPath -Filter '*.ps1' -File | foreach { @{ Name = $_.BaseName } })
        }

        if (Test-Path $privatePath) {
            $script:PrivateFunctions = @(Get-ChildItem -Path $privatePath -Filter '*.ps1' -File | foreach { @{ Name = $_.BaseName; Path = $_.FullName } })
        }
    }

    BeforeAll {
        $outputPath = $null
        $searchPath = $PSScriptRoot
        for ($i = 0; $i -lt 3; $i++) {
            $testPath = "$searchPath\.output"
            if (Test-Path $testPath) {
                $outputPath = $testPath
                break
            }
            $searchPath = Split-Path $searchPath -Parent
        }

        $moduleFolders = Get-ChildItem -Path $outputPath -Directory
        $script:ModuleName = $moduleFolders[0].Name
        $moduleFolder = $moduleFolders[0].FullName
        $versionFolders = Get-ChildItem -Path $moduleFolder -Directory
        $modulePath = $versionFolders[0].FullName
        $manifestPath = "$modulePath\$script:ModuleName.psd1"
        
        Import-Module $manifestPath -Force -ErrorAction Stop
    }

    Context 'Private Function Help' {
        It "Private function '<Name>' should have synopsis" -ForEach $script:PrivateFunctions {
            . $Path
            $help = Get-Help -Name $Name -ErrorAction SilentlyContinue
            
            $help | should -not -BeNullOrEmpty
            $help.Synopsis | should -not -BeNullOrEmpty
            $help.Synopsis | should -not -match $Name
        }
    }

    Context 'Public Function Help' {
        It "Public function '<Name>' should have synopsis" -ForEach $script:PublicFunctions {
            $help = Get-Help -Name $Name -Full -ErrorAction SilentlyContinue
            $help.Synopsis | should -not -BeNullOrEmpty
            $help.Synopsis | should -not -match $Name
        }

        It "Public function '<Name>' should have description" -ForEach $script:PublicFunctions {
            $help = Get-Help -Name $Name -Full -ErrorAction SilentlyContinue
            $help.Description | should -not -BeNullOrEmpty
            $help.Description.Text | should -not -BeNullOrEmpty
        }

        It "Public function '<Name>' should have example" -ForEach $script:PublicFunctions {
            $help = Get-Help -Name $Name -Full -ErrorAction SilentlyContinue
            $help.Examples | should -not -BeNullOrEmpty
            $help.Examples.Example.Count | should -BeGreaterOrEqual 1
        }

        It "Public function '<Name>' should have parameter help" -ForEach $script:PublicFunctions {
            $help = Get-Help -Name $Name -Full -ErrorAction SilentlyContinue
            $params = $help.Parameters.Parameter | where Name -notin @('WhatIf', 'Confirm')
            
            if ($params) {
                foreach ($param in $params) {
                    $param.Description.Text | should -not -BeNullOrEmpty
                }
            }
        }
    }

    AfterAll {
        if ($script:ModuleName) {
            Remove-Module $script:ModuleName -ErrorAction SilentlyContinue
        }
    }
}
