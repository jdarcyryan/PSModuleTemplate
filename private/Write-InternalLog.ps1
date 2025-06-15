function Write-InternalLog {
    <#
    .SYNOPSIS
        Internal logging function for the module.
    
    .DESCRIPTION
        This is a private function used internally by the module to write log messages
        with consistent formatting and optional file output.
    
    .PARAMETER Message
        The log message to write.
    
    .PARAMETER Level
        The log level (Info, Warning, Error, Debug).
    
    .PARAMETER LogPath
        Optional path to a log file. If not specified, only writes to verbose stream.
    
    .PARAMETER IncludeTimestamp
        Whether to include a timestamp in the log message.
    
    .EXAMPLE
        Write-InternalLog -Message "Module initialized" -Level "Info"
        
        Writes an info-level log message.
    
    .EXAMPLE
        Write-InternalLog -Message "Configuration error" -Level "Error" -LogPath "C:\Logs\module.log"
        
        Writes an error message to both the error stream and a log file.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Message,
        
        [Parameter()]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string] $Level = "Info",
        
        [Parameter()]
        [string] $LogPath,
        
        [Parameter()]
        [switch] $IncludeTimestamp
    )
    
    # Format the message
    $FormattedMessage = if ($IncludeTimestamp) {
        "[{0:yyyy-MM-dd HH:mm:ss}] [{1}] {2}" -f (Get-Date), $Level.ToUpper(), $Message
    } else {
        "[{0}] {1}" -f $Level.ToUpper(), $Message
    }
    
    # Write to appropriate stream based on level
    switch ($Level) {
        "Info" {
            Write-Verbose $FormattedMessage
        }
        "Warning" {
            Write-Warning $FormattedMessage
        }
        "Error" {
            Write-Error $FormattedMessage
        }
        "Debug" {
            Write-Debug $FormattedMessage
        }
    }
    
    # Write to log file if specified
    if ($LogPath) {
        try {
            # Ensure the directory exists
            $LogDirectory = Split-Path $LogPath -Parent
            if ($LogDirectory -and -not (Test-Path $LogDirectory)) {
                New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
            }
            
            # Append to log file
            Add-Content -Path $LogPath -Value $FormattedMessage -Encoding UTF8
        }
        catch {
            Write-Warning "Failed to write to log file '$LogPath': $_"
        }
    }
}