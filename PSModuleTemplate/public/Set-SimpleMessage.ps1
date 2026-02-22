<#
.SYNOPSIS
Sets a simple message to display.

.DESCRIPTION
This function allows you to set a custom message that can be displayed.
The message is returned as output and can be stored or displayed as needed.

.PARAMETER Message
The message text to set. This parameter is mandatory.

.PARAMETER ToUpper
When specified, converts the message to uppercase before returning it.

.EXAMPLE
Set-SimpleMessage -Message "Welcome to PowerShell"

Returns: "Welcome to PowerShell"

.EXAMPLE
Set-SimpleMessage -Message "hello world" -ToUpper

Returns: "HELLO WORLD"

.NOTES
This function demonstrates basic parameter handling and string manipulation.
#>
function Set-SimpleMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $ToUpper
    )

    if ($ToUpper) {
        return $Message.ToUpper()
    }
    
    return $Message
}
