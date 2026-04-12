Register-ArgumentCompleter -CommandName 'Set-SimpleMessage' -ParameterName 'Message' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    @(
        'Hello World'
        'Welcome to PowerShell'
        'Module loaded successfully'
        'Ready to go'
    ) | where { $_ -like "$wordToComplete*" } | foreach {
        [System.Management.Automation.CompletionResult]::new(
            "'$_'",
            $_,
            'ParameterValue',
            $_
        )
    }
}
