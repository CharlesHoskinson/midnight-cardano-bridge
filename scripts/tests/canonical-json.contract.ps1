$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$modulePath = Join-Path $repoRoot 'scripts\CanonicalJson.psm1'
if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "canonical JSON module is missing: $modulePath"
}

Import-Module $modulePath -Force
$outputPath = Join-Path ([IO.Path]::GetTempPath()) ("mcb-canonical-json-{0}.json" -f [guid]::NewGuid().ToString('N'))
try {
    $value = [ordered]@{
        schema_version = 1
        nested = [ordered]@{ enabled = $true; values = @('alpha', 'beta') }
    }
    Write-CanonicalJsonFile -Path $outputPath -Value $value -Depth 8

    $bytes = [IO.File]::ReadAllBytes($outputPath)
    if ($bytes -contains 13) { throw 'canonical JSON contains a carriage return' }
    if ($bytes.Length -eq 0 -or $bytes[-1] -ne 10) { throw 'canonical JSON does not end with LF' }
    if ($bytes.Length -gt 1 -and $bytes[-2] -eq 10) { throw 'canonical JSON has more than one trailing LF' }

    $roundTrip = Get-Content -Raw -LiteralPath $outputPath | ConvertFrom-Json
    if ($roundTrip.schema_version -ne 1 -or $roundTrip.nested.values[1] -ne 'beta') {
        throw 'canonical JSON did not round-trip'
    }

    Write-Output 'canonical-json-contract: PASS'
} finally {
    Remove-Item -LiteralPath $outputPath -Force -ErrorAction SilentlyContinue
}
