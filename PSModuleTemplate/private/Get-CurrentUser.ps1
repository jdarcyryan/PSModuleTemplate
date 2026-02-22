<#
.SYNOPSIS
Gets the current user's name from the environment.

.DESCRIPTION
This private function retrieves the current user's name from the Windows environment variables.
It provides a simple way to get the logged-in user's identity.

.EXAMPLE
Get-CurrentUser

Returns the current user's name, e.g., "JohnDoe"

.NOTES
This is a private helper function used internally by the module.
#>
function Get-CurrentUser {
    [CmdletBinding()]
    param()

    return $env:USERNAME
}
