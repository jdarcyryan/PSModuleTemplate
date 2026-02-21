function Get-FileLineCount {
    <#
        .SYNOPSIS
        Returns the number of lines in a file.

        .DESCRIPTION
        Reads the specified file and returns the total number of lines it contains.
        Useful for quickly auditing file sizes without opening them.

        .PARAMETER Path
        The path to the file to count lines in.

        .EXAMPLE
        Get-FileLineCount -Path '.\README.md'

        Returns the number of lines in README.md.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]
        $Path
    )

    (Get-Content -Path $Path).Count
}
