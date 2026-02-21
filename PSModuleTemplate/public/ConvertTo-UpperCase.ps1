function ConvertTo-UpperCase {
    <#
        .SYNOPSIS
        Converts one or more strings to upper case.

        .DESCRIPTION
        Accepts strings from the pipeline or directly and returns each one
        converted to upper case.

        .PARAMETER InputObject
        The string or strings to convert.

        .EXAMPLE
        ConvertTo-UpperCase -InputObject 'hello world'

        Returns 'HELLO WORLD'.

        .EXAMPLE
        'foo', 'bar' | ConvertTo-UpperCase

        Returns 'FOO' and 'BAR'.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string[]]
        $InputObject
    )

    process {
        foreach ($item in $InputObject) {
            $item.ToUpper()
        }
    }
}
