@{
    # ─────────────────────────────────────────────────────────────────
    # Global options — these apply to every dependency unless overridden
    # ─────────────────────────────────────────────────────────────────
    # PSDependOptions = @{
    #     Target     = 'CurrentUser'          # 'CurrentUser', 'AllUsers', or a file path
    #     AddToPath  = $true                  # Add Target to $env:PSModulePath
    #     DependencyType = 'PSGalleryModule'  # Default type if not specified per-entry
    #     Tags       = @('Build', 'Test')     # Only process deps matching these tags
    # }

    # ─────────────────────────────────────────────────────────────────
    # Simple format — module name = version string
    # ─────────────────────────────────────────────────────────────────
    # 'MyModuleName'        = 'latest'        # Always pull the newest version
    # 'AnotherModule'       = '2.4.1'         # Pin to an exact version
    # 'YetAnotherModule'    = '1.*'           # Wildcard — latest 1.x release

    # ─────────────────────────────────────────────────────────────────
    # Hashtable format — PSGallery module with extra options
    # ─────────────────────────────────────────────────────────────────
    # 'MyGalleryModule' = @{
    #     DependencyType = 'PSGalleryModule'  # Explicit (this is also the default)
    #     Version        = '3.0.0'
    #     Target         = 'CurrentUser'
    #     Tags           = @('Build')
    #     Parameters     = @{
    #         SkipPublisherCheck = $true
    #         AllowClobber       = $true
    #         Repository         = 'PSGallery'   # Use a named repo
    #     }
    # }

    # ─────────────────────────────────────────────────────────────────
    # PSGallery NuGet dependency (uses NuGet directly instead of
    # Install-Module — handy for build servers without PowerShellGet)
    # ─────────────────────────────────────────────────────────────────
    # 'MyNuGetModule' = @{
    #     DependencyType = 'PSGalleryNuget'
    #     Version        = '1.2.0'
    #     Target         = 'C:\BuildAgent\Modules'
    # }

    # ─────────────────────────────────────────────────────────────────
    # Git repository dependency
    # ─────────────────────────────────────────────────────────────────
    # 'MyGitModule' = @{
    #     DependencyType = 'Git'
    #     Version        = 'main'             # Branch, tag, or commit hash
    #     Source         = 'https://github.com/myorg/MyGitModule.git'
    #     Target         = 'C:\Modules\MyGitModule'
    # }

    # ─────────────────────────────────────────────────────────────────
    # FileSystem dependency — copy a local folder or file
    # ─────────────────────────────────────────────────────────────────
    # 'MyLocalModule' = @{
    #     DependencyType = 'FileSystem'
    #     Source         = 'C:\Source\MyLocalModule'
    #     Target         = 'C:\Deploy\Modules\MyLocalModule'
    # }

    # ─────────────────────────────────────────────────────────────────
    # Command dependency — run an arbitrary script/command
    # (useful for bootstrapping tools that aren't PS modules)
    # ─────────────────────────────────────────────────────────────────
    # 'InstallDotNetSdk' = @{
    #     DependencyType = 'Command'
    #     Source         = 'dotnet-install.ps1 -Channel 8.0'
    #     Tags           = @('Build')
    # }

    # ─────────────────────────────────────────────────────────────────
    # Package dependency — uses PackageManagement / OneGet
    # ─────────────────────────────────────────────────────────────────
    # 'MyPackage' = @{
    #     DependencyType = 'Package'
    #     Source         = 'nuget'             # Provider name
    #     Version        = '4.1.0'
    #     Target         = 'C:\Packages'
    #     Parameters     = @{
    #         ForceBootstrap = $true
    #     }
    # }

    # ─────────────────────────────────────────────────────────────────
    # Multiple dependencies with shared tags — useful for grouping
    # e.g. invoke only "Test" deps:  Invoke-PSDepend -Tags 'Test'
    # ─────────────────────────────────────────────────────────────────
    # 'TestFrameworkModule' = @{
    #     Version = '5.4.0'
    #     Tags    = @('Test')
    # }
    # 'MockingModule' = @{
    #     Version = '1.0.0'
    #     Tags    = @('Test')
    # }
    # 'BuildHelperModule' = @{
    #     Version = 'latest'
    #     Tags    = @('Build')
    # }

    # ─────────────────────────────────────────────────────────────────
    # Credential-protected dependency (private gallery / feed)
    # ─────────────────────────────────────────────────────────────────
    # 'MyPrivateModule' = @{
    #     DependencyType = 'PSGalleryModule'
    #     Version        = '2.0.0'
    #     Parameters     = @{
    #         Repository = 'MyPrivateFeed'
    #         Credential = $MyCredentialVariable   # Pass in at runtime
    #     }
    # }
}
