# Get-Greeting

## Synopsis

Gets a personalised greeting message.

## Description

This function creates a friendly greeting message for the specified person. 
It can optionally include the current time in the greeting.

## Syntax

```powershell
Get-Greeting [-Name <String>] [-IncludeTime] [-Verbose] [-Debug] [-ErrorAction <ActionPreference>] [-WarningAction <ActionPreference>] [-InformationAction <ActionPreference>] [-ProgressAction <ActionPreference>] [-ErrorVariable <String>] [-WarningVariable <String>] [-InformationVariable <String>] [-OutVariable <String>] [-OutBuffer <Int32>] [-PipelineVariable <String>]
```

## Parameters

### -Name

The name of the person to greet. This parameter is mandatory.

- **Type**: String
- **Required**: true
- **Position**: 1
- **Default value**: None
- **Accepts pipeline input**: false

### -IncludeTime

When specified, includes the current time in the greeting message.

- **Type**: SwitchParameter
- **Required**: false
- **Position**: named
- **Default value**: False
- **Accepts pipeline input**: false

## Examples

### Example 1

Returns: "Hello Alice, how are you today?"

```powershell
Get-Greeting -Name "Alice"
```

### Example 2

Returns: "Hello Bob, how are you today? The time is 14:30:25"

```powershell
Get-Greeting -Name "Bob" -IncludeTime
```
