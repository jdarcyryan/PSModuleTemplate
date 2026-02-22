<#
.SYNOPSIS
Demonstrates the use of both PowerShell and C# classes.

.DESCRIPTION
This function showcases the SimpleCalculator PowerShell class and StringHelper C# class
by performing basic operations and returning the results in a formatted object.

.PARAMETER FirstNumber
The first number for the calculation. Default is 10.

.PARAMETER SecondNumber
The second number for the calculation. Default is 5.

.PARAMETER TestString
The string to manipulate using the C# StringHelper class. Default is "Hello World".

.EXAMPLE
Invoke-ClassDemo

Uses default values to demonstrate both classes.

.EXAMPLE
Invoke-ClassDemo -FirstNumber 20 -SecondNumber 8 -TestString "PowerShell Rocks"

Performs calculations with 20 and 8, and manipulates the string "PowerShell Rocks".

.NOTES
This function demonstrates integration between PowerShell and C# classes within the module.
#>
function Invoke-ClassDemo {
    [CmdletBinding()]
    param(
        [int]
        $FirstNumber = 10,

        [int]
        $SecondNumber = 5,

        [string]
        $TestString = "Hello Worlds"
    )

    # Create an instance of the PowerShell class
    $calculator = [SimpleCalculator]::new()

    # Perform calculations
    $addResult = $calculator.Add($FirstNumber, $SecondNumber)
    $subtractResult = $calculator.Subtract($FirstNumber, $SecondNumber)

    # Use the C# class static methods
    $reversedString = [PSModuleTemplate.StringHelper]::ReverseString($TestString)
    $wordCount = [PSModuleTemplate.StringHelper]::CountWords($TestString)

    # Return results as a custom object
    return [PSCustomObject]@{
        CalculatorResults = @{
            Addition = $addResult
            Subtraction = $subtractResult
            LastResult = $calculator.GetLastResult()
        }
        StringResults = @{
            OriginalString = $TestString
            ReversedString = $reversedString
            WordCount = $wordCount
        }
    }
}
