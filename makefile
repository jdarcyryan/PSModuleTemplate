# PSModuleTemplate

.PHONY: setup build

# Initialize module structure from template
# Creates the module directory, manifest, and copies template files
setup:
	pwsh -File './.build/scripts/New-PSModule.ps1' -Verbose

# Build the module to .output directory
# Compiles module to .output/{ModuleName}/{Version}/ and creates .nupkg package
build:
	pwsh -File './.build/scripts/Build-PSModule.ps1' -Verbose
