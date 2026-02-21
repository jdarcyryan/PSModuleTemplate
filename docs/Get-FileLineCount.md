# Get-FileLineCount

## Synopsis

Returns the number of lines in a file.

## Description

Reads the specified file and returns the total number of lines it contains.
Useful for quickly auditing file sizes without opening them.

## Syntax

```powershell
Get-FileLineCount [-Path <String>] [-Verbose] [-Debug] [-ErrorAction <ActionPreference>] [-WarningAction <ActionPreference>] [-InformationAction <ActionPreference>] [-ProgressAction <ActionPreference>] [-ErrorVariable <String>] [-WarningVariable <String>] [-InformationVariable <String>] [-OutVariable <String>] [-OutBuffer <Int32>] [-PipelineVariable <String>]
```

## Parameters

### -Path

The path to the file to count lines in.

- **Type**: String
- **Required**: true
- **Position**: 1
- **Default value**: None
- **Accepts pipeline input**: false

## Examples

### Example 1

Returns the number of lines in README.md.

```powershell
Get-FileLineCount -Path '.\README.md'
```
