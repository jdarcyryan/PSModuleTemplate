function Get-Greeting {
    <#
        .SYNOPSIS
        Returns a greeting message for a given name.

        .DESCRIPTION
        Generates a simple greeting string for the specified person. Optionally
        includes the current date in the greeting.

        .PARAMETER Name
        The name of the person to greet.

        .PARAMETER IncludeDate
        If specified, appends today's date to the greeting.

        .EXAMPLE
        Get-Greeting -Name 'Alice'

        Returns a greeting for Alice.

        .EXAMPLE
        Get-Greeting -Name 'Bob' -IncludeDate

        Returns a greeting for Bob that includes today's date.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,

        [switch]
        $IncludeDate
    )

    $greeting = "Hello, $Name!"

    if ($IncludeDate) {
        $greeting += " Today is $(Get-Date -Format 'dddd, dd MMMM yyyy')."
    }

    $greeting
}
