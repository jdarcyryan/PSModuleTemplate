<#
.SYNOPSIS
A simple PowerShell class for basic arithmetic operations.

.DESCRIPTION
This class provides basic arithmetic functionality including addition and subtraction.
It demonstrates PowerShell class implementation within the module template.
#>
class SimpleCalculator {
    [int] $LastResult

    SimpleCalculator() {
        $this.LastResult = 0
    }

    [int] Add([int] $a, [int] $b) {
        $this.LastResult = $a + $b
        return $this.LastResult
    }

    [int] Subtract([int] $a, [int] $b) {
        $this.LastResult = $a - $b
        return $this.LastResult
    }

    [int] GetLastResult() {
        return $this.LastResult
    }
}
