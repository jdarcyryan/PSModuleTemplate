<#
.SYNOPSIS
Tests if a string meets the specified length requirements.

.DESCRIPTION
This private function validates whether a given string meets minimum and maximum length requirements.
It returns a boolean value indicating whether the string passes the length validation.

.PARAMETER InputString
The string to test for length requirements.

.PARAMETER MinLength
The minimum required length for the string. Default is 1.

.PARAMETER MaxLength
The maximum allowed length for the string. Default is 100.

.EXAMPLE
Test-StringLength -InputString "Hello" -MinLength 3 -MaxLength 10

Returns: $true

.EXAMPLE
Test-StringLength -InputString "Hi" -MinLength 5

Returns: $false

.NOTES
This is a private helper function for string validation within the module.
#>
function Test-StringLength {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $InputString,

        [int]
        $MinLength = 1,

        [int]
        $MaxLength = 100
    )

    $length = $InputString.Length
    return ($length -ge $MinLength -and $length -le $MaxLength)
}
