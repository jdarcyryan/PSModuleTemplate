.PHONY: setup

setup:
	pwsh -File './.build/scripts/New-PSModule.ps1' -Verbose

build:
	pwsh -File './.build/scripts/Build-PSModule.ps1' -Verbose
