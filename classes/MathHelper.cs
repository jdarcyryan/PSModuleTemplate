using System;

namespace PowerShellModule
{
    public class MathHelper
    {
        /// <summary>
        /// Calculates the factorial of a number
        /// </summary>
        /// <param name="number">The number to calculate factorial for</param>
        /// <returns>The factorial result</returns>
        public static long CalculateFactorial(int number)
        {
            if (number < 0)
                throw new ArgumentException("Number must be non-negative");
            
            if (number <= 1)
                return 1;
            
            long result = 1;
            for (int i = 2; i <= number; i++)
            {
                result *= i;
            }
            
            return result;
        }

        /// <summary>
        /// Checks if a number is prime
        /// </summary>
        /// <param name="number">The number to check</param>
        /// <returns>True if the number is prime, false otherwise</returns>
        public static bool IsPrime(int number)
        {
            if (number <= 1)
                return false;
            
            if (number <= 3)
                return true;
            
            if (number % 2 == 0 || number % 3 == 0)
                return false;
            
            for (int i = 5; i * i <= number; i += 6)
            {
                if (number % i == 0 || number % (i + 2) == 0)
                    return false;
            }
            
            return true;
        }

        /// <summary>
        /// Calculates the greatest common divisor of two numbers
        /// </summary>
        /// <param name="a">First number</param>
        /// <param name="b">Second number</param>
        /// <returns>The greatest common divisor</returns>
        public static int GreatestCommonDivisor(int a, int b)
        {
            a = Math.Abs(a);
            b = Math.Abs(b);
            
            while (b != 0)
            {
                int temp = b;
                b = a % b;
                a = temp;
            }
            
            return a;
        }
    }
}