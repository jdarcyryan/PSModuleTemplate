using System;

namespace PSModuleTemplate
{
    /// <summary>
    /// A simple C# class for string manipulation operations.
    /// </summary>
    public class StringHelper
    {
        /// <summary>
        /// Reverses the characters in a string.
        /// </summary>
        /// <param name="input">The string to reverse.</param>
        /// <returns>The reversed string.</returns>
        public static string ReverseString(string input)
        {
            if (string.IsNullOrEmpty(input))
                return input;

            char[] charArray = input.ToCharArray();
            Array.Reverse(charArray);
            return new string(charArray);
        }

        /// <summary>
        /// Counts the number of words in a string.
        /// </summary>
        /// <param name="input">The string to count words in.</param>
        /// <returns>The number of words.</returns>
        public static int CountWords(string input)
        {
            if (string.IsNullOrWhiteSpace(input))
                return 0;

            string[] words = input.Split(new char[] { ' ', '\t', '\n', '\r' }, 
                StringSplitOptions.RemoveEmptyEntries);
            return words.Length;
        }
    }
}
