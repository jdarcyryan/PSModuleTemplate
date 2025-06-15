class ConfigurationManager {
    # Properties
    [hashtable] $Settings
    [string] $ConfigPath
    [datetime] $LastModified
    
    # Constructor
    ConfigurationManager() {
        $this.Settings = @{}
        $this.ConfigPath = ""
        $this.LastModified = Get-Date
    }
    
    # Constructor with config path
    ConfigurationManager([string] $ConfigPath) {
        $this.Settings = @{}
        $this.ConfigPath = $ConfigPath
        $this.LastModified = Get-Date
        
        if (Test-Path $ConfigPath) {
            $this.LoadConfiguration()
        }
    }
    
    # Method to set a configuration value
    [void] SetValue([string] $Key, [object] $Value) {
        $this.Settings[$Key] = $Value
        $this.LastModified = Get-Date
        Write-Verbose "Configuration value set: $Key = $Value"
    }
    
    # Method to get a configuration value
    [object] GetValue([string] $Key) {
        if ($this.Settings.ContainsKey($Key)) {
            return $this.Settings[$Key]
        }
        return $null
    }
    
    # Method to get a configuration value with default
    [object] GetValue([string] $Key, [object] $DefaultValue) {
        if ($this.Settings.ContainsKey($Key)) {
            return $this.Settings[$Key]
        }
        return $DefaultValue
    }
    
    # Method to remove a configuration value
    [bool] RemoveValue([string] $Key) {
        if ($this.Settings.ContainsKey($Key)) {
            $this.Settings.Remove($Key)
            $this.LastModified = Get-Date
            Write-Verbose "Configuration value removed: $Key"
            return $true
        }
        return $false
    }
    
    # Method to check if a key exists
    [bool] HasKey([string] $Key) {
        return $this.Settings.ContainsKey($Key)
    }
    
    # Method to get all keys
    [string[]] GetKeys() {
        return $this.Settings.Keys
    }
    
    # Method to clear all settings
    [void] Clear() {
        $this.Settings.Clear()
        $this.LastModified = Get-Date
        Write-Verbose "All configuration settings cleared"
    }
    
    # Method to load configuration from file
    [void] LoadConfiguration() {
        if (-not (Test-Path $this.ConfigPath)) {
            throw "Configuration file not found: $($this.ConfigPath)"
        }
        
        try {
            $configData = Get-Content $this.ConfigPath -Raw | ConvertFrom-Json -AsHashtable
            $this.Settings = $configData
            $this.LastModified = (Get-Item $this.ConfigPath).LastWriteTime
            Write-Verbose "Configuration loaded from: $($this.ConfigPath)"
        }
        catch {
            throw "Failed to load configuration from $($this.ConfigPath): $_"
        }
    }
    
    # Method to save configuration to file
    [void] SaveConfiguration() {
        if ([string]::IsNullOrEmpty($this.ConfigPath)) {
            throw "No configuration path specified"
        }
        
        try {
            $this.Settings | ConvertTo-Json -Depth 10 | Out-File $this.ConfigPath -Encoding UTF8
            $this.LastModified = Get-Date
            Write-Verbose "Configuration saved to: $($this.ConfigPath)"
        }
        catch {
            throw "Failed to save configuration to $($this.ConfigPath): $_"
        }
    }
    
    # Method to get configuration as JSON string
    [string] ToJson() {
        return ($this.Settings | ConvertTo-Json -Depth 10)
    }
    
    # Method to import settings from hashtable
    [void] ImportSettings([hashtable] $ImportSettings) {
        foreach ($key in $ImportSettings.Keys) {
            $this.Settings[$key] = $ImportSettings[$key]
        }
        $this.LastModified = Get-Date
        Write-Verbose "Settings imported: $($ImportSettings.Keys.Count) items"
    }
    
    # Override ToString method
    [string] ToString() {
        return "ConfigurationManager: $($this.Settings.Count) settings, Last Modified: $($this.LastModified)"
    }
}