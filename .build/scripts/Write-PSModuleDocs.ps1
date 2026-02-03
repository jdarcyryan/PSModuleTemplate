function ConvertTo-HelpMarkdown {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Management.Automation.FunctionInfo]
        $Command
    )

    begin {
#        $gitRoot = Resolve-Path -Path "$PSScriptRoot\..\.."
#        $moduleName = Split-Path -Path $gitRoot -Leaf
#        $outputModulePath = "$gitRoot\.output\$moduleName"
#
#        # Verify module has built
#        if (-not (Test-Path -Path $outputModulePath -PathType Container)) {
#            throw "Module directory not found at: '$outputModulePath', run 'make build' to build the module."
#        }
#        else {
#            try {
#                # Test module import before tests
#                Import-Module $outputModulePath
#            }
#            catch {
#                throw "Built module could not be imported at: '$outputModulePath', please run 'make build' to rebuild the module."
#            }
#            finally {
#                Get-Module | where Path -like "$outputModulePath\*" | Remove-Module
#            }
#        }
#
#        # Get module and alias'
#        $module = Get-Module $outputModulePath
        $allAlias = Get-Alias
    }

    process {
        $help = Get-Help $Command -Full
        $parameters = $help.parameters.parameter
        $examples = $help.examples.example

        $alias = @(($allAlias | where ResolvedCommandName -eq $command.Name).Name)

        @"
# $($command.Name)$(if ($alias) {" ($($alias.Name -join ', '))"})

## Synopsis

$($help.Synopsis)

## Description

$($help.Description.Text)

## Syntax

$('```')powershell
$(($help.Syntax | Out-String).Trim())
$('```')

$(if ($parameters){
    @"
## Parameters

$(
    $parameters | foreach {
        @"
### -$($_.Name)

$($_.Description.Text)

- **Type**: $($_.Type.Name)
- **Required**: $($_.Required)
- **Position**: $($_.Position)
- **Default value**: $(
    if ($_.defaultValue) {
        $_.defaultValue
    }
    else {
        'None'
    }
)
- **Accepts pipeline input**: $($_.pipelineInput)
"@
    }
)

"@
})
## Examples

$($examples | foreach {$i = 1} {
    @"
### Example $i

$($($_.remarks.Text -join '').Trim())

$('```')powershell
$($_.code)
$('```')

"@
    $i++
})
"@
    }

    end {
        # remove module
    }
}
