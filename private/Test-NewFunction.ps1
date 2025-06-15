function Test-NewFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputString
    )

    # This function simply returns the input string in uppercase
    return $InputString.ToUpper()
}