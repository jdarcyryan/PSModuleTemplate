# Invoke-ClassDemo

## Synopsis

Demonstrates the use of both PowerShell and C# classes.

## Description

This function showcases the SimpleCalculator PowerShell class and StringHelper C# class
by performing basic operations and returning the results in a formatted object.

## Syntax

```powershell
Invoke-ClassDemo [[-FirstNumber <Int32>]] [[-SecondNumber <Int32>]] [[-TestString <String>]] [-Verbose] [-Debug] [-ErrorAction <ActionPreference>] [-WarningAction <ActionPreference>] [-InformationAction <ActionPreference>] [-ProgressAction <ActionPreference>] [-ErrorVariable <String>] [-WarningVariable <String>] [-InformationVariable <String>] [-OutVariable <String>] [-OutBuffer <Int32>] [-PipelineVariable <String>]
```

## Parameters

### -FirstNumber

The first number for the calculation. Default is 10.

- **Type**: Int32
- **Required**: false
- **Position**: 1
- **Default value**: 10
- **Accepts pipeline input**: false

### -SecondNumber

The second number for the calculation. Default is 5.

- **Type**: Int32
- **Required**: false
- **Position**: 2
- **Default value**: 5
- **Accepts pipeline input**: false

### -TestString

The string to manipulate using the C# StringHelper class. Default is "Hello World".

- **Type**: String
- **Required**: false
- **Position**: 3
- **Default value**: Hello World
- **Accepts pipeline input**: false

## Examples

### Example 1

Uses default values to demonstrate both classes.

```powershell
Invoke-ClassDemo
```

### Example 2

Performs calculations with 20 and 8, and manipulates the string "PowerShell Rocks".

```powershell
Invoke-ClassDemo -FirstNumber 20 -SecondNumber 8 -TestString "PowerShell Rocks"
```
