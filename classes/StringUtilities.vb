Imports System
Imports System.Text

Namespace PowerShellModule
    Public Class StringUtilities
        ''' <summary>
        ''' Reverses a string
        ''' </summary>
        ''' <param name="input">The string to reverse</param>
        ''' <returns>The reversed string</returns>
        Public Shared Function ReverseString(input As String) As String
            If String.IsNullOrEmpty(input) Then
                Return input
            End If
            
            Dim charArray As Char() = input.ToCharArray()
            Array.Reverse(charArray)
            Return New String(charArray)
        End Function

        ''' <summary>
        ''' Counts the number of words in a string
        ''' </summary>
        ''' <param name="input">The string to count words in</param>
        ''' <returns>The number of words</returns>
        Public Shared Function CountWords(input As String) As Integer
            If String.IsNullOrWhiteSpace(input) Then
                Return 0
            End If
            
            Dim words As String() = input.Trim().Split(New Char() {" "c, ControlChars.Tab, ControlChars.Cr, ControlChars.Lf}, StringSplitOptions.RemoveEmptyEntries)
            Return words.Length
        End Function

        ''' <summary>
        ''' Converts a string to title case
        ''' </summary>
        ''' <param name="input">The string to convert</param>
        ''' <returns>The string in title case</returns>
        Public Shared Function ToTitleCase(input As String) As String
            If String.IsNullOrWhiteSpace(input) Then
                Return input
            End If
            
            Dim words As String() = input.ToLower().Split(" "c)
            Dim result As New StringBuilder()
            
            For Each word As String In words
                If word.Length > 0 Then
                    Dim titleWord As String = Char.ToUpper(word(0)) + word.Substring(1)
                    result.Append(titleWord + " ")
                End If
            Next
            
            Return result.ToString().Trim()
        End Function

        ''' <summary>
        ''' Removes all whitespace from a string
        ''' </summary>
        ''' <param name="input">The string to remove whitespace from</param>
        ''' <returns>The string without whitespace</returns>
        Public Shared Function RemoveWhitespace(input As String) As String
            If String.IsNullOrEmpty(input) Then
                Return input
            End If
            
            Return input.Replace(" ", "").Replace(ControlChars.Tab, "").Replace(ControlChars.Cr, "").Replace(ControlChars.Lf, "")
        End Function
    End Class
End Namespace