# Set-SimpleMessage

## Synopsis

Sets a simple message to display.

## Description

This function allows you to set a custom message that can be displayed.
The message is returned as output and can be stored or displayed as needed.

## Syntax

```powershell
Set-SimpleMessage [-Message <String>] [-ToUpper] [-Verbose] [-Debug] [-ErrorAction <ActionPreference>] [-WarningAction <ActionPreference>] [-InformationAction <ActionPreference>] [-ProgressAction <ActionPreference>] [-ErrorVariable <String>] [-WarningVariable <String>] [-InformationVariable <String>] [-OutVariable <String>] [-OutBuffer <Int32>] [-PipelineVariable <String>]
```

## Parameters

### -Message

The message text to set. This parameter is mandatory.

- **Type**: String
- **Required**: true
- **Position**: 1
- **Default value**: None
- **Accepts pipeline input**: false

### -ToUpper

When specified, converts the message to uppercase before returning it.

- **Type**: SwitchParameter
- **Required**: false
- **Position**: named
- **Default value**: False
- **Accepts pipeline input**: false

## Examples

### Example 1

Returns: "Welcome to PowerShell"

```powershell
Set-SimpleMessage -Message "Welcome to PowerShell"
```

### Example 2

Returns: "HELLO WORLD"

```powershell
Set-SimpleMessage -Message "hello world" -ToUpper
```
