<#
.SYNOPSIS
Gets a personalised greeting message.

.DESCRIPTION
This function creates a friendly greeting message for the specified person. 
It can optionally include the current time in the greeting.

.PARAMETER Name
The name of the person to greet. This parameter is mandatory.

.PARAMETER IncludeTime
When specified, includes the current time in the greeting message.

.EXAMPLE
Get-Greeting -Name "Alice"

Returns: "Hello Alice, how are you today?"

.EXAMPLE
Get-Greeting -Name "Bob" -IncludeTime

Returns: "Hello Bob, how are you today? The time is 14:30:25"

.NOTES
This is a simple demonstration function for the PSModuleTemplate.
#>
function Get-Greeting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $IncludeTime
    )

    $greeting = "Hello $Name, how are you today?"
    
    if ($IncludeTime) {
        $currentTime = Get-Date -Format "HH:mm:ss"
        $greeting += " The time is $currentTime"
    }

    return $greeting
}
