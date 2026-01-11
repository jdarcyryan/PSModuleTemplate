.PHONY: setup

setup:
	pwsh -File './.build/scripts/New-PSModule.ps1' -Verbose
