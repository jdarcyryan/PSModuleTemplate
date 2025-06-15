function Get-SystemInformation {
    <#
    .SYNOPSIS
        Retrieves comprehensive system information from the local or remote computer.
    
    .DESCRIPTION
        The Get-SystemInformation function collects detailed information about a computer system,
        including hardware specifications, operating system details, network configuration,
        and performance metrics. This function is useful for system inventory, troubleshooting,
        and monitoring purposes.
    
    .PARAMETER ComputerName
        Specifies the name of the computer to query. If not specified, queries the local computer.
        You can specify multiple computer names separated by commas.
    
    .PARAMETER IncludeNetworking
        When specified, includes detailed network adapter and TCP/IP configuration information.
    
    .PARAMETER IncludePerformance
        When specified, includes current performance counters such as CPU usage and memory utilization.
    
    .PARAMETER IncludeStorage
        When specified, includes detailed disk and storage information.
    
    .PARAMETER Credential
        Specifies alternate credentials to use when connecting to remote computers.
    
    .PARAMETER TimeoutSeconds
        Specifies the timeout in seconds for WMI queries. Default is 30 seconds.
    
    .INPUTS
        System.String
        You can pipe computer names to this function.
    
    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns a custom object containing system information.
    
    .EXAMPLE
        Get-SystemInformation
        
        Retrieves basic system information from the local computer.
    
    .EXAMPLE
        Get-SystemInformation -ComputerName "Server01" -IncludeNetworking -IncludeStorage
        
        Retrieves comprehensive system information including networking and storage details from Server01.
    
    .EXAMPLE
        "Server01", "Server02" | Get-SystemInformation -IncludePerformance
        
        Retrieves system information with performance metrics from multiple servers via pipeline.
    
    .EXAMPLE
        Get-SystemInformation -ComputerName "RemotePC" -Credential (Get-Credential) -TimeoutSeconds 60
        
        Retrieves system information from a remote computer using alternate credentials with a 60-second timeout.
    
    .NOTES
        Author: Your Name
        Version: 1.0.0
        Requires: PowerShell 5.1 or higher
        
        This function requires WMI access to target computers. Ensure that:
        - WMI service is running on target computers
        - Appropriate firewall rules are configured
        - User has sufficient permissions
    
    .LINK
        Get-WmiObject
        Get-CimInstance
        
    .FUNCTIONALITY
        System Information
    #>
    
    [Alias("Get-SysInfo", "gsysinfo")]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("CN", "Computer")]
        [string[]] $ComputerName = $env:COMPUTERNAME,
        
        [Parameter()]
        [switch] $IncludeNetworking,
        
        [Parameter()]
        [switch] $IncludePerformance,
        
        [Parameter()]
        [switch] $IncludeStorage,
        
        [Parameter()]
        [System.Management.Automation.PSCredential] $Credential,
        
        [Parameter()]
        [ValidateRange(1, 300)]
        [int] $TimeoutSeconds = 30
    )
    
    begin {
        Write-InternalLog -Message "Starting Get-SystemInformation" -Level "Info"
        
        # Common WMI parameters
        $WmiParams = @{
            ErrorAction = 'Stop'
        }
        
        if ($Credential) {
            $WmiParams['Credential'] = $Credential
        }
    }
    
    process {
        foreach ($Computer in $ComputerName) {
            Write-InternalLog -Message "Processing computer: $Computer" -Level "Info"
            
            try {
                # Basic system information
                $WmiParams['ComputerName'] = $Computer
                
                $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem @WmiParams
                $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem @WmiParams
                $Processor = Get-WmiObject -Class Win32_Processor @WmiParams | Select-Object -First 1
                $BIOS = Get-WmiObject -Class Win32_BIOS @WmiParams
                
                # Build base system information object
                $SystemInfo = [PSCustomObject]@{
                    ComputerName = $Computer
                    Manufacturer = $ComputerSystem.Manufacturer
                    Model = $ComputerSystem.Model
                    TotalPhysicalMemoryGB = [Math]::Round($ComputerSystem.TotalPhysicalMemory / 1GB, 2)
                    ProcessorName = $Processor.Name
                    ProcessorCores = $Processor.NumberOfCores
                    ProcessorLogicalProcessors = $Processor.NumberOfLogicalProcessors
                    OperatingSystem = $OperatingSystem.Caption
                    OSVersion = $OperatingSystem.Version
                    OSBuild = $OperatingSystem.BuildNumber
                    LastBootTime = $OperatingSystem.ConvertToDateTime($OperatingSystem.LastBootUpTime)
                    BIOSVersion = $BIOS.SMBIOSBIOSVersion
                    SerialNumber = $BIOS.SerialNumber
                    Domain = $ComputerSystem.Domain
                    Workgroup = $ComputerSystem.Workgroup
                    CurrentUser = $ComputerSystem.UserName
                    TimeZone = $OperatingSystem.CurrentTimeZone / 60
                    SystemType = $ComputerSystem.SystemType
                    QueryTime = Get-Date
                }
                
                # Add networking information if requested
                if ($IncludeNetworking) {
                    Write-InternalLog -Message "Including networking information for $Computer" -Level "Debug"
                    
                    $NetworkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration @WmiParams |
                        Where-Object { $_.IPEnabled -eq $true }
                    
                    $NetworkInfo = foreach ($Adapter in $NetworkAdapters) {
                        [PSCustomObject]@{
                            Description = $Adapter.Description
                            IPAddress = $Adapter.IPAddress -join ', '
                            SubnetMask = $Adapter.IPSubnet -join ', '
                            DefaultGateway = $Adapter.DefaultIPGateway -join ', '
                            DNSServers = $Adapter.DNSServerSearchOrder -join ', '
                            DHCPEnabled = $Adapter.DHCPEnabled
                            MACAddress = $Adapter.MACAddress
                        }
                    }
                    
                    $SystemInfo | Add-Member -NotePropertyName "NetworkAdapters" -NotePropertyValue $NetworkInfo
                }
                
                # Add performance information if requested
                if ($IncludePerformance) {
                    Write-InternalLog -Message "Including performance information for $Computer" -Level "Debug"
                    
                    $PerfCounters = @{
                        CPUUsagePercent = (Get-WmiObject -Class Win32_Processor @WmiParams | 
                            Measure-Object -Property LoadPercentage -Average).Average
                        AvailableMemoryGB = [Math]::Round((Get-WmiObject -Class Win32_OperatingSystem @WmiParams).FreePhysicalMemory / 1MB, 2)
                        ProcessCount = (Get-WmiObject -Class Win32_OperatingSystem @WmiParams).NumberOfProcesses
                        ThreadCount = (Get-WmiObject -Class Win32_PerfRawData_PerfProc_Process @WmiParams | 
                            Where-Object { $_.Name -eq "_Total" }).ThreadCount
                    }
                    
                    $SystemInfo | Add-Member -NotePropertyName "Performance" -NotePropertyValue ([PSCustomObject]$PerfCounters)
                }
                
                # Add storage information if requested
                if ($IncludeStorage) {
                    Write-InternalLog -Message "Including storage information for $Computer" -Level "Debug"
                    
                    $LogicalDisks = Get-WmiObject -Class Win32_LogicalDisk @WmiParams |
                        Where-Object { $_.DriveType -eq 3 }  # Fixed drives only
                    
                    $StorageInfo = foreach ($Disk in $LogicalDisks) {
                        [PSCustomObject]@{
                            Drive = $Disk.DeviceID
                            Label = $Disk.VolumeName
                            FileSystem = $Disk.FileSystem
                            TotalSizeGB = [Math]::Round($Disk.Size / 1GB, 2)
                            FreeSpaceGB = [Math]::Round($Disk.FreeSpace / 1GB, 2)
                            UsedSpaceGB = [Math]::Round(($Disk.Size - $Disk.FreeSpace) / 1GB, 2)
                            PercentFree = [Math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 1)
                        }
                    }
                    
                    $SystemInfo | Add-Member -NotePropertyName "Storage" -NotePropertyValue $StorageInfo
                }
                
                Write-Output $SystemInfo
                Write-InternalLog -Message "Successfully retrieved information for $Computer" -Level "Info"
                
            }
            catch {
                $ErrorMsg = "Failed to retrieve system information from $Computer : $_"
                Write-InternalLog -Message $ErrorMsg -Level "Error"
                Write-Error $ErrorMsg
            }
        }
    }
    
    end {
        Write-InternalLog -Message "Get-SystemInformation completed" -Level "Info"
    }
}

# Create aliases for the function
Set-Alias -Name "Get-SysInfo" -Value "Get-SystemInformation" -Description "Alias for Get-SystemInformation"
Set-Alias -Name "gsysinfo" -Value "Get-SystemInformation" -Description "Short alias for Get-SystemInformation"