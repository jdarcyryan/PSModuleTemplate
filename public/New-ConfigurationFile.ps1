function New-ConfigurationFile {
    <#
    .SYNOPSIS
        Creates a new configuration file with specified settings.
    
    .DESCRIPTION
        The New-ConfigurationFile function creates a new JSON or XML configuration file
        with default or custom settings. This function supports creating configuration
        files for applications, services, or modules with predefined templates or
        custom configuration objects.
    
    .PARAMETER Path
        Specifies the path where the configuration file will be created.
        The file extension determines the format (.json, .xml, .psd1).
    
    .PARAMETER Template
        Specifies a predefined template to use for the configuration file.
        Available templates: Application, Service, Module, Database, WebServer.
    
    .PARAMETER Settings
        Specifies a hashtable of custom settings to include in the configuration file.
        This parameter can be used alone or combined with a template.
    
    .PARAMETER Format
        Specifies the output format for the configuration file.
        Valid values: JSON, XML, PowerShellData.
        If not specified, the format is determined by the file extension.
    
    .PARAMETER Force
        Overwrites an existing configuration file without prompting.
    
    .PARAMETER IncludeComments
        When specified, includes helpful comments in the configuration file
        (supported for JSON and PowerShell Data formats).
    
    .PARAMETER Encoding
        Specifies the file encoding. Default is UTF8.
    
    .INPUTS
        System.Collections.Hashtable
        You can pipe a hashtable of settings to this function.
    
    .OUTPUTS
        System.IO.FileInfo
        Returns information about the created configuration file.
    
    .EXAMPLE
        New-ConfigurationFile -Path "C:\Config\app.json" -Template Application
        
        Creates a new JSON configuration file using the Application template.
    
    .EXAMPLE
        $settings = @{
            ServerName = "localhost"
            Port = 8080
            EnableLogging = $true
            LogLevel = "Info"
        }
        New-ConfigurationFile -Path ".\server.json" -Settings $settings -IncludeComments
        
        Creates a configuration file with custom settings and includes comments.
    
    .EXAMPLE
        @{ Database = "MyDB"; ConnectionString = "Server=." } | New-ConfigurationFile -Path "db.psd1" -Force
        
        Creates a PowerShell data file with database settings, overwriting if it exists.
    
    .NOTES
        Author: Your Name
        Version: 1.0.0
        
        Supported file formats:
        - JSON (.json)
        - XML (.xml) 
        - PowerShell Data (.psd1)
        
        Templates provide common configuration structures for different application types.
    
    .LINK
        ConvertTo-Json
        Export-Clixml
        
    .FUNCTIONALITY
        Configuration Management
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,
        
        [Parameter()]
        [ValidateSet("Application", "Service", "Module", "Database", "WebServer")]
        [string] $Template,
        
        [Parameter(ValueFromPipeline)]
        [hashtable] $Settings = @{},
        
        [Parameter()]
        [ValidateSet("JSON", "XML", "PowerShellData")]
        [string] $Format,
        
        [Parameter()]
        [switch] $Force,
        
        [Parameter()]
        [switch] $IncludeComments,
        
        [Parameter()]
        [ValidateSet("UTF8", "ASCII", "UTF32", "Unicode")]
        [string] $Encoding = "UTF8"
    )
    
    begin {
        Write-InternalLog -Message "Starting New-ConfigurationFile" -Level "Info"
        
        # Define templates
        $Templates = @{
            Application = @{
                ApplicationName = "MyApplication"
                Version = "1.0.0"
                Settings = @{
                    EnableLogging = $true
                    LogLevel = "Information"
                    LogPath = ".\logs"
                    MaxLogFiles = 10
                }
                Features = @{
                    EnableAutoUpdate = $true
                    EnableTelemetry = $false
                    EnableCaching = $true
                }
            }
            
            Service = @{
                ServiceName = "MyService"
                DisplayName = "My Windows Service"
                Description = "A custom Windows service"
                Configuration = @{
                    StartMode = "Automatic"
                    RestartPolicy = "Always"
                    TimeoutSeconds = 30
                    WorkingDirectory = "C:\Services\MyService"
                }
                Logging = @{
                    Provider = "EventLog"
                    Source = "MyService"
                    Level = "Warning"
                }
            }
            
            Module = @{
                ModuleName = "MyPowerShellModule"
                ModuleVersion = "1.0.0"
                Author = "Module Author"
                Description = "A PowerShell module"
                Settings = @{
                    DefaultParameterValues = @{}
                    ModulePath = ""
                    AutoLoadFunctions = $true
                    VerboseLogging = $false
                }
            }
            
            Database = @{
                ConnectionStrings = @{
                    Primary = "Server=localhost;Database=MyDB;Integrated Security=true"
                    Backup = "Server=backup-server;Database=MyDB;Integrated Security=true"
                }
                Settings = @{
                    CommandTimeout = 30
                    ConnectionTimeout = 15
                    EnableConnectionPooling = $true
                    MaxPoolSize = 100
                    MinPoolSize = 5
                }
                Features = @{
                    EnableAuditing = $true
                    EnableEncryption = $false
                    BackupEnabled = $true
                }
            }
            
            WebServer = @{
                ServerSettings = @{
                    Port = 80
                    SecurePort = 443
                    BindingAddress = "0.0.0.0"
                    MaxConnections = 1000
                }
                Security = @{
                    EnableSSL = $true
                    CertificatePath = ""
                    RequireAuthentication = $false
                    AllowedOrigins = @("*")
                }
                Logging = @{
                    AccessLogEnabled = $true
                    ErrorLogEnabled = $true
                    LogPath = ".\logs"
                    LogFormat = "Combined"
                }
            }
        }
    }
    
    process {
        try {
            # Resolve the full path
            $FullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            
            # Check if file exists and handle accordingly
            if ((Test-Path $FullPath) -and -not $Force) {
                $Message = "Configuration file already exists at '$FullPath'. Use -Force to overwrite."
                Write-InternalLog -Message $Message -Level "Warning"
                throw $Message
            }
            
            # Determine format from file extension if not specified
            if (-not $Format) {
                $Extension = [System.IO.Path]::GetExtension($FullPath).ToLower()
                $Format = switch ($Extension) {
                    ".json" { "JSON" }
                    ".xml" { "XML" }
                    ".psd1" { "PowerShellData" }
                    default { "JSON" }  # Default to JSON
                }
                
                # Update path extension if needed
                if ($Extension -notin @(".json", ".xml", ".psd1")) {
                    $FullPath = [System.IO.Path]::ChangeExtension($FullPath, ".json")
                    Write-InternalLog -Message "Updated file extension to .json" -Level "Info"
                }
            }
            
            Write-InternalLog -Message "Creating configuration file: $FullPath (Format: $Format)" -Level "Info"
            
            # Start with template settings if specified
            $ConfigData = @{}
            if ($Template) {
                if ($Templates.ContainsKey($Template)) {
                    $ConfigData = $Templates[$Template].Clone()
                    Write-InternalLog -Message "Applied template: $Template" -Level "Info"
                } else {
                    Write-Warning "Template '$Template' not found. Available templates: $($Templates.Keys -join ', ')"
                }
            }
            
            # Merge custom settings
            if ($Settings.Count -gt 0) {
                foreach ($key in $Settings.Keys) {
                    $ConfigData[$key] = $Settings[$key]
                }
                Write-InternalLog -Message "Merged $($Settings.Count) custom settings" -Level "Info"
            }
            
            # Add metadata
            $ConfigData["_metadata"] = @{
                CreatedBy = $env:USERNAME
                CreatedDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                ComputerName = $env:COMPUTERNAME
                Template = $Template
                Format = $Format
            }
            
            # Ensure directory exists
            $Directory = [System.IO.Path]::GetDirectoryName($FullPath)
            if (-not (Test-Path $Directory)) {
                New-Item -Path $Directory -ItemType Directory -Force | Out-Null
                Write-InternalLog -Message "Created directory: $Directory" -Level "Info"
            }
            
            # Generate content based on format
            if ($PSCmdlet.ShouldProcess($FullPath, "Create configuration file")) {
                switch ($Format) {
                    "JSON" {
                        if ($IncludeComments) {
                            $JsonContent = $ConfigData | ConvertTo-Json -Depth 10
                            $CommentedContent = @"
/*
 * Configuration File
 * Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
 * Template: $($Template ?? "Custom")
 * 
 * This file contains configuration settings.
 * Modify values as needed for your environment.
 */

$JsonContent
"@
                            $CommentedContent | Out-File -FilePath $FullPath -Encoding $Encoding -Force
                        } else {
                            $ConfigData | ConvertTo-Json -Depth 10 | Out-File -FilePath $FullPath -Encoding $Encoding -Force
                        }
                    }
                    
                    "XML" {
                        $ConfigData | Export-Clixml -Path $FullPath -Encoding $Encoding -Force
                    }
                    
                    "PowerShellData" {
                        $PsdContent = "@{`n"
                        
                        if ($IncludeComments) {
                            $PsdContent += @"
# Configuration File
# Created: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Template: $($Template ?? "Custom")

"@
                        }
                        
                        function ConvertTo-PSDString {
                            param($Object, $Indent = 1)
                            
                            $IndentString = "    " * $Indent
                            
                            if ($Object -is [hashtable]) {
                                $Result = "@{`n"
                                foreach ($Key in $Object.Keys) {
                                    $Value = ConvertTo-PSDString -Object $Object[$Key] -Indent ($Indent + 1)
                                    $Result += "$IndentString$Key = $Value`n"
                                }
                                $Result += "$("    " * ($Indent - 1))}"
                                return $Result
                            }
                            elseif ($Object -is [array]) {
                                $Items = $Object | ForEach-Object { ConvertTo-PSDString -Object $_ -Indent $Indent }
                                return "@($($Items -join ', '))"
                            }
                            elseif ($Object -is [string]) {
                                return "'$($Object -replace "'", "''")'"
                            }
                            elseif ($Object -is [bool]) {
                                return if ($Object) { '$true' } else { '$false' }
                            }
                            elseif ($Object -is [int] -or $Object -is [double]) {
                                return $Object.ToString()
                            }
                            else {
                                return "'$Object'"
                            }
                        }
                        
                        foreach ($Key in $ConfigData.Keys) {
                            $Value = ConvertTo-PSDString -Object $ConfigData[$Key] -Indent 1
                            $PsdContent += "    $Key = $Value`n"
                        }
                        
                        $PsdContent += "}"
                        $PsdContent | Out-File -FilePath $FullPath -Encoding $Encoding -Force
                    }
                }
                
                Write-InternalLog -Message "Configuration file created successfully: $FullPath" -Level "Info"
                
                # Return file information
                Get-Item $FullPath
            }
            
        }
        catch {
            $ErrorMsg = "Failed to create configuration file '$Path': $_"
            Write-InternalLog -Message $ErrorMsg -Level "Error"
            Write-Error $ErrorMsg
        }
    }
    
    end {
        Write-InternalLog -Message "New-ConfigurationFile completed" -Level "Info"
    }
}