$ErrorActionPreference = 'Stop'

function Assert-Contains {
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [string] $Expected
    )

    if (-not $Text.Contains($Expected, [StringComparison]::Ordinal)) {
        throw "setup dry run did not report expected operation: $Expected`n$Text"
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$setup = Join-Path $repoRoot 'scripts\setup-reference-harness.ps1'
$requirements = Join-Path $repoRoot 'reference\observers\requirements.txt'
$savedGo = $env:MCB_GO
$savedCargo = $env:MCB_CARGO
$savedRustc = $env:MCB_RUSTC

try {
    $env:MCB_GO = $null
    $expectedRequirements = @('scrapling[fetchers]==0.4.10', 'cbor2==5.7.1')
    $actualRequirements = @(Get-Content -LiteralPath $requirements | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if (($actualRequirements -join "`n") -ne ($expectedRequirements -join "`n")) {
        throw "observer requirements do not declare the exact Fetcher dependency intent"
    }
    if (-not $env:MCB_CARGO) {
        $env:MCB_CARGO = Join-Path $HOME '.cargo\bin\cargo.exe'
    }
    if (-not $env:MCB_RUSTC) {
        $env:MCB_RUSTC = Join-Path $HOME '.cargo\bin\rustc.exe'
    }

    $outputLines = & (Get-Command pwsh).Source -NoProfile -File $setup -WhatIf 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "setup dry run failed with exit $LASTEXITCODE`n$(($outputLines | Out-String).Trim())"
    }
    $output = $outputLines | Out-String
    foreach ($expected in @(
        'setup=npm-ci state=PLANNED',
        'setup=python-venv state=PLANNED',
        'setup=python-lock-validation state=PASS',
        'setup=python-requirements state=PLANNED',
        'setup=cargo-fetch-locked state=PLANNED',
        'public_data_fetch=false',
        'setup=reference-harness state=READY'
    )) {
        Assert-Contains -Text $output -Expected $expected
    }
    Write-Output 'test=setup-dry-run-contract state=PASS'
} finally {
    $env:MCB_GO = $savedGo
    $env:MCB_CARGO = $savedCargo
    $env:MCB_RUSTC = $savedRustc
}
