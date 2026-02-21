# ConvertTo-UpperCase

## Synopsis

Converts one or more strings to upper case.

## Description

Accepts strings from the pipeline or directly and returns each one
converted to upper case.

## Syntax

```powershell
ConvertTo-UpperCase [-InputObject <String[]>] [-Verbose] [-Debug] [-ErrorAction <ActionPreference>] [-WarningAction <ActionPreference>] [-InformationAction <ActionPreference>] [-ProgressAction <ActionPreference>] [-ErrorVariable <String>] [-WarningVariable <String>] [-InformationVariable <String>] [-OutVariable <String>] [-OutBuffer <Int32>] [-PipelineVariable <String>]
```

## Parameters

### -InputObject

The string or strings to convert.

- **Type**: String[]
- **Required**: true
- **Position**: 1
- **Default value**: None
- **Accepts pipeline input**: true (ByValue)

## Examples

### Example 1

Returns 'HELLO WORLD'.

```powershell
ConvertTo-UpperCase -InputObject 'hello world'
```

### Example 2

Returns 'FOO' and 'BAR'.

```powershell
'foo', 'bar' | ConvertTo-UpperCase
```
