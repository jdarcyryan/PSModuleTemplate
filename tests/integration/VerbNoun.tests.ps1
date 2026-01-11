Describe 'Function Naming Conventions' {
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
            $script:PrivateFunctions = @(Get-ChildItem -Path $privatePath -Filter '*.ps1' -File | foreach { @{ Name = $_.BaseName } })
        }

    }

    BeforeAll {
        $script:ApprovedVerbs = (Get-Verb).Verb
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

    Context 'Public Functions' {
        It "Public function '<Name>' should use Verb-Noun naming" -ForEach $script:PublicFunctions {
            $Name | should -match '-'
            
            $parts = $Name -split '-', 2
            $verb = $parts[0]
            $noun = $parts[1]
            
            $script:ApprovedVerbs | should -contain $verb
            $noun | should -not -BeNullOrEmpty
        }
    }

    Context 'Private Functions' {
        It "Private function '<Name>' should use Verb-Noun naming" -ForEach $script:PrivateFunctions {
            $Name | should -match '-'
            
            $parts = $Name -split '-', 2
            $verb = $parts[0]
            $noun = $parts[1]
            
            $script:ApprovedVerbs | should -contain $verb
            $noun | should -not -BeNullOrEmpty
        }
    }

    AfterAll {
        if ($script:ModuleName) {
            Remove-Module $script:ModuleName -ErrorAction SilentlyContinue
        }
    }
}
