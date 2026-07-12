Set-StrictMode -Version Latest

function ConvertTo-CanonicalJsonText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Value,
        [ValidateRange(1, 100)] [int] $Depth = 30
    )

    $text = $Value | ConvertTo-Json -Depth $Depth
    $text = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    return $text.TrimEnd([char[]]"`n") + "`n"
}

function Write-CanonicalJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] $Value,
        [ValidateRange(1, 100)] [int] $Depth = 30
    )

    $text = ConvertTo-CanonicalJsonText -Value $Value -Depth $Depth
    [IO.File]::WriteAllText($Path, $text, [Text.UTF8Encoding]::new($false))
}

Export-ModuleMember -Function ConvertTo-CanonicalJsonText, Write-CanonicalJsonFile
