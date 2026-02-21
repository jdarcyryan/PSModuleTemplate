function Resolve-InternalPath {
    param(
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    Resolve-Path -Path $Path
}
