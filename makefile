# PSModuleTemplate

.PHONY: setup build pester

# Default target
.DEFAULT_GOAL := build

# Initialize module structure from template
# Creates the module directory, manifest, and copies template files
setup:
	pwsh -File './.build/scripts/New-PSModule.ps1' -Verbose

# Build the module to .output directory
# Compiles module to .output/{ModuleName}/{Version}/ and creates .nupkg package
build:
	pwsh -File './.build/scripts/Build-PSModule.ps1' -Verbose

# Invokes PSDepend to gather dependencies
# Installs required modules detailed in PSDepend.psd1
depend:
	pwsh -File './.build/scripts/Invoke-PSModulePSDepend.ps1' -Verbose

# Run Pester tests with detailed output
# Imports local Pester module, runs all tests, and displays detailed results
pester:
	pwsh -File './.build/scripts/Invoke-PSModulePester.ps1'
