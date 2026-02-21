<#
    .SYNOPSIS
    Generates markdown documentation for all public functions in the PowerShell module.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

function Write-PSModuleDocs {
    [CmdletBinding()]
    <#
        .SYNOPSIS
        Generates markdown documentation for all public functions in the PowerShell module.

        .DESCRIPTION
        Builds the module, imports it, and generates markdown documentation for each public
        function. Output files are written to the docs folder in the repository root, with
        one file per function named <FunctionName>.md.

        .EXAMPLE
        Write-PSModuleDocs

        Generates markdown documentation for all public functions and writes them to the docs folder.
    #>
    param()

    $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
    $moduleName = Split-Path -Path $gitRoot -Leaf
    $outputModulePath = "$gitRoot\.output\$moduleName"
    $docsPath = "$gitRoot\docs"

    # Verify module has built
    if (-not (Test-Path -Path $outputModulePath -PathType Container)) {
        throw "Module directory not found at: '$outputModulePath', run 'make build' to build the module."
    }

    try {
        Import-Module $outputModulePath -Force -ErrorAction Stop
    }
    catch {
        throw "Built module could not be imported at: '$outputModulePath', please run 'make build' to rebuild the module."
    }

    try {
        $module = Get-Module -Name $moduleName
        if (-not $module) {
            throw "Module '$moduleName' could not be found after import."
        }

        $allAlias = Get-Alias
        $docs = [Collections.Generic.List[PSCustomObject]]::new()

        foreach ($command in $module.ExportedFunctions.Values) {
            $help = Get-Help $command -Full

            # If there's no real help documentation, skip
            if (-not $help -or (
                (-not $help.Description) -and
                (-not $help.examples) -and
                ($help.Synopsis.Trim() -eq $command.Name -or -not $help.Synopsis)
            )) {
                continue
            }

            $parameters = $help.parameters.parameter
            $examples = $help.examples.example
            $alias = @(($allAlias | where ResolvedCommandName -eq $command.Name).Name)

            $sections = [Collections.Generic.List[string]]::new()

            # Header
            $header = "# $($command.Name)"
            if ($alias) {
                $header += " ($($alias -join ', '))"
            }
            $sections.Add($header)

            # Synopsis
            if ($help.Synopsis -and $help.Synopsis.Trim() -notlike "$($command.Name)*") {
                $sections.Add("## Synopsis`n`n$($help.Synopsis)")
            }

            # Description
            if ($help.Description.Text) {
                $sections.Add("## Description`n`n$($help.Description.Text)")
            }

            # Syntax
            $syntaxLines = foreach ($paramSet in $command.ParameterSets) {
                $paramStrings = foreach ($param in $paramSet.Parameters | where Name -notin [Management.Automation.Cmdlet]::CommonParameters) {
                    $typeName = if ($param.ParameterType -ne [switch]) {
                        " <$($param.ParameterType.Name)>"
                    }
                    else {
                        ''
                    }
                    $token = if ($param.Position -ge 0) {
                        "[-$($param.Name)$typeName]" | foreach {
                            if ($param.IsMandatory) {
                                "[-$($param.Name)$typeName]"
                            }
                            else {
                                "[[-$($param.Name)$typeName]]"
                            }
                        }
                    }
                    else {
                        if ($param.IsMandatory) {
                            "-$($param.Name)$typeName"
                        }
                        else {
                            "[-$($param.Name)$typeName]"
                        }
                    }
                    $token
                }
                "$($command.Name) $($paramStrings -join ' ')"
            }
            $syntaxText = ($syntaxLines -join "`n").Trim()
            if ($syntaxText) {
                $sections.Add("## Syntax`n`n``````powershell`n$syntaxText`n``````")
            }

            # Parameters
            if ($parameters) {
                $paramLines = [Collections.Generic.List[string]]::new()
                $paramLines.Add('## Parameters')

                foreach ($param in $parameters) {
                    $paramSection = "### -$($param.Name)"

                    if ($param.Description.Text) {
                        $paramSection += "`n`n$($param.Description.Text)"
                    }

                    $bullets = [Collections.Generic.List[string]]::new()

                    if ($param.Type.Name) {
                        $bullets.Add("- **Type**: $($param.Type.Name)")
                    }
                    if ($param.Required) {
                        $bullets.Add("- **Required**: $($param.Required)")
                    }
                    if ($param.Position) {
                        $bullets.Add("- **Position**: $($param.Position)")
                    }

                    $bullets.Add("- **Default value**: $(if ($param.defaultValue) {
                        $param.defaultValue
                    }
                    else {
                        'None'
                    })")

                    if ($param.pipelineInput) {
                        $bullets.Add("- **Accepts pipeline input**: $($param.pipelineInput)")
                    }

                    $paramSection += "`n`n$($bullets -join "`n")"
                    $paramLines.Add($paramSection)
                }

                $sections.Add($paramLines -join "`n`n")
            }

            # Examples
            if ($examples) {
                $exampleLines = [Collections.Generic.List[string]]::new()
                $exampleLines.Add('## Examples')

                $i = 1
                foreach ($example in $examples) {
                    $exampleSection = "### Example $i"

                    $remarksText = ($example.remarks.Text -join '').Trim()
                    if ($remarksText) {
                        $exampleSection += "`n`n$remarksText"
                    }

                    if ($example.code) {
                        $exampleSection += "`n`n``````powershell`n$($example.code)`n``````"
                    }

                    $exampleLines.Add($exampleSection)
                    $i++
                }

                $sections.Add($exampleLines -join "`n`n")
            }

            $docs.Add([PSCustomObject]@{
                FileName = "$($command.Name).md"
                Content  = $sections -join "`n`n"
            })
        }

        # Clean up docs folder
        if (Test-Path -Path $docsPath -PathType Container) {
            Get-ChildItem -Path $docsPath -File | Remove-Item -Force
        }
        else {
            $null = New-Item -Path $docsPath -ItemType Directory -Force
        }

        if ($docs.Count -eq 0) {
            $null = New-Item -Path "$docsPath\.gitkeep" -ItemType File -Force
            Write-Verbose 'No documentation generated; created .gitkeep in docs folder.'
            return
        }

        foreach ($doc in $docs) {
            $filePath = "$docsPath\$($doc.FileName)"
            Set-Content -Path $filePath -Value $doc.Content -Encoding utf8 -Force
            Write-Verbose "Written: $filePath"
        }

        Write-Host "Documentation written to '$docsPath' ($($docs.Count) file(s))." -ForegroundColor Green
    }
    finally {
        Get-Module | Where-Object Path -like "$outputModulePath\*" | Remove-Module -ErrorAction SilentlyContinue
    }
}

try {
    Write-PSModuleDocs @PSBoundParameters
}
catch {
    Write-Host $_ -ForegroundColor Red
    exit 1
}
