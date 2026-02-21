function ConvertTo-HelpMarkdown {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Management.Automation.FunctionInfo]
        $Command
    )

    begin {
        $allAlias = Get-Alias
    }

    process {
        $help = Get-Help $Command -Full

        # If there's no real help documentation, return null
        if (-not $help -or (
            (-not $help.Description) -and
            (-not $help.examples) -and
            ($help.Synopsis.Trim() -eq $command.Name -or -not $help.Synopsis)
        )) {
            return $null
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
        $syntaxLines = foreach ($paramSet in $Command.ParameterSets) {
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
            "$($Command.Name) $($paramStrings -join ' ')"
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

        $sections -join "`n`n"
    }

    end {}
}
