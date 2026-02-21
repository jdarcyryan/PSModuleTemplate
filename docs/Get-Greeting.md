# Get-Greeting

## Synopsis

Returns a greeting message for a given name.

## Description

Generates a simple greeting string for the specified person. Optionally
includes the current date in the greeting.

## Syntax

```powershell
Get-Greeting [-Name <String>] [-IncludeDate] [-Verbose] [-Debug] [-ErrorAction <ActionPreference>] [-WarningAction <ActionPreference>] [-InformationAction <ActionPreference>] [-ProgressAction <ActionPreference>] [-ErrorVariable <String>] [-WarningVariable <String>] [-InformationVariable <String>] [-OutVariable <String>] [-OutBuffer <Int32>] [-PipelineVariable <String>]
```

## Parameters

### -Name

The name of the person to greet.

- **Type**: String
- **Required**: true
- **Position**: 1
- **Default value**: None
- **Accepts pipeline input**: false

### -IncludeDate

If specified, appends today's date to the greeting.

- **Type**: SwitchParameter
- **Required**: false
- **Position**: named
- **Default value**: False
- **Accepts pipeline input**: false

## Examples

### Example 1

Returns a greeting for Alice.

```powershell
Get-Greeting -Name 'Alice'
```

### Example 2

Returns a greeting for Bob that includes today's date.

```powershell
Get-Greeting -Name 'Bob' -IncludeDate
```
