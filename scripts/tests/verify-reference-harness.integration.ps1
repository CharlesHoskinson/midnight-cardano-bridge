[CmdletBinding()]
param([switch] $KeepTemp)

$ErrorActionPreference = 'Stop'

function Assert-Equal {
    param(
        [Parameter(Mandatory)] $Actual,
        [Parameter(Mandatory)] $Expected,
        [Parameter(Mandatory)] [string] $Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message`nexpected=$Expected`nactual=$Actual"
    }
}

function Copy-RepositoryInputs {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination
    )

    $files = @(
        (Join-Path $Source '.gitattributes'),
        (Join-Path $Source 'package.json'),
        (Join-Path $Source 'package-lock.json')
    )
    foreach ($directory in @('openspec', 'protocol', 'reference', 'scripts')) {
        $files += Get-ChildItem -LiteralPath (Join-Path $Source $directory) -File -Recurse |
            Where-Object {
                $_.FullName -notmatch '[\\/]reference[\\/]rust[\\/]target[\\/]' -and
                $_.FullName -notmatch '[\\/]__pycache__[\\/]'
            } |
            Select-Object -ExpandProperty FullName
    }

    foreach ($sourcePath in $files) {
        $relative = [IO.Path]::GetRelativePath($Source, $sourcePath)
        $destinationPath = Join-Path $Destination $relative
        $parent = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
        }
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
    }
}

function Initialize-TestRepository {
    param([Parameter(Mandatory)] [string] $Root)

    $git = (Get-Command git -ErrorAction Stop).Source
    foreach ($arguments in @(
        @('init', '--initial-branch=integration'),
        @('config', 'user.name', 'reference-harness-contract'),
        @('config', 'user.email', 'reference-harness-contract@example.invalid'),
        @('config', 'core.longpaths', 'true'),
        @('add', '--', '.gitattributes', 'package.json', 'package-lock.json', 'openspec', 'protocol', 'reference', 'scripts'),
        @('commit', '-m', 'Create late-failure fixture snapshot')
    )) {
        $output = & $git -C $Root @arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "fixture git command failed ($LASTEXITCODE): git $($arguments -join ' ')`n$(($output | Out-String).Trim())"
        }
    }
}

function Add-DirectoryJunction {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Target
    )

    if (-not (Test-Path -LiteralPath $Target)) {
        throw "required prepared-host directory is missing: $Target"
    }
    New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
}

function New-FakeToolchain {
    param(
        [Parameter(Mandatory)] [string] $Root,
        [Parameter(Mandatory)] [string] $ReportPath
    )

    $bin = Join-Path $Root 'fake-bin'
    New-Item -ItemType Directory -Path $bin | Out-Null
    $quotedReport = $ReportPath.Replace("'", "''")

    $cargoScript = @"
if (`$args -contains '--version') { Write-Output 'cargo 1.90.0 (840b83a10 2025-07-30)'; exit 0 }
if ((`$args -join ' ') -match 'missing-event-index') {
    [Console]::Error.WriteLine('source-event-schema: missing field source_action_or_event_index')
    exit 1
}
if (`$args -contains 'run') { Write-Output ((Get-Content -Raw -LiteralPath '$quotedReport').Trim()); exit 0 }
exit 0
"@
    $goScript = @"
if (`$args.Count -eq 1 -and `$args[0] -eq 'version') { Write-Output 'go version go1.25.7 windows/amd64'; exit 0 }
if ((`$args -join ' ') -match 'missing-event-index') {
    [Console]::Error.WriteLine('source-event-schema: missing field source_action_or_event_index')
    exit 1
}
if (`$args -contains 'run') { Write-Output ((Get-Content -Raw -LiteralPath '$quotedReport').Trim()); exit 0 }
exit 0
"@
    $rustcScript = "Write-Output 'rustc 1.90.0 (1159e78c4 2025-09-14)'`n"
    $npmScript = "if (`$args -contains '--version') { Write-Output '11.16.0' }`nexit 0`n"

    foreach ($tool in @{
        cargo = $cargoScript
        go = $goScript
        rustc = $rustcScript
        npm = $npmScript
    }.GetEnumerator()) {
        $scriptPath = Join-Path $bin ("fake-$($tool.Key).ps1")
        $cmdPath = Join-Path $bin ("$($tool.Key).cmd")
        [IO.File]::WriteAllText($scriptPath, $tool.Value, [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText(
            $cmdPath,
            "@echo off`r`npwsh -NoProfile -File `"%~dp0fake-$($tool.Key).ps1`" %*`r`n",
            [Text.ASCIIEncoding]::new()
        )
    }

    return $bin
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$tempRoot = Join-Path $env:TEMP ('mcb-verifier-integration-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

try {
    Copy-RepositoryInputs -Source $repoRoot -Destination $tempRoot
    Add-DirectoryJunction -Path (Join-Path $tempRoot 'node_modules') -Target (Join-Path $repoRoot 'node_modules')
    Add-DirectoryJunction -Path (Join-Path $tempRoot '.venv-scrapling') -Target (Join-Path $repoRoot '.venv-scrapling')

    $structuralPath = Join-Path $tempRoot 'reference\evidence\structural-report-v1.json'
    $conformancePath = Join-Path $tempRoot 'reference\evidence\conformance-report-v1.json'

    $structural = Get-Content -Raw -LiteralPath $structuralPath | ConvertFrom-Json
    $structural | Add-Member -NotePropertyName regression_sentinel -NotePropertyValue 'preserve-me'
    $structuralJson = $structural | ConvertTo-Json -Depth 20
    [IO.File]::WriteAllText($structuralPath, $structuralJson + "`n", [Text.UTF8Encoding]::new($false))

    $rosterPath = Join-Path $tempRoot 'protocol\gate-roster-v1.json'
    $roster = Get-Content -Raw -LiteralPath $rosterPath | ConvertFrom-Json
    $roster.canonical_cbor_sha256 = '0' * 64
    $rosterJson = $roster | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($rosterPath, $rosterJson + "`n", [Text.UTF8Encoding]::new($false))

    $fakeReportPath = Join-Path $tempRoot 'fake-structural-report.json'
    $fixture = Get-Content -Raw -LiteralPath (Join-Path $tempRoot 'reference\fixtures\structural-v1.json') | ConvertFrom-Json
    [IO.File]::WriteAllText(
        $fakeReportPath,
        (($fixture.expected | ConvertTo-Json -Depth 30 -Compress) + "`n"),
        [Text.UTF8Encoding]::new($false)
    )
    $fakeBin = New-FakeToolchain -Root $tempRoot -ReportPath $fakeReportPath

    $observerTests = Join-Path $tempRoot 'reference\observers\tests'
    Get-ChildItem -LiteralPath $observerTests -File | Remove-Item -Force
    [IO.File]::WriteAllText(
        (Join-Path $observerTests 'test_integration_sentinel.py'),
        "import unittest`n`nclass SentinelTest(unittest.TestCase):`n    def test_passes(self):`n        self.assertTrue(True)`n",
        [Text.UTF8Encoding]::new($false)
    )
    Initialize-TestRepository -Root $tempRoot

    $beforeStructuralHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $structuralPath).Hash
    $beforeConformanceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $conformancePath).Hash
    $beforeStructuralWrite = (Get-Item -LiteralPath $structuralPath).LastWriteTimeUtc.Ticks
    $beforeConformanceWrite = (Get-Item -LiteralPath $conformancePath).LastWriteTimeUtc.Ticks

    $verifier = Join-Path $tempRoot 'scripts\verify-reference-harness.ps1'
    $savedPath = $env:PATH
    $savedOverrides = @{
        MCB_CARGO = $env:MCB_CARGO
        MCB_GO = $env:MCB_GO
        MCB_NPM = $env:MCB_NPM
        MCB_RUSTC = $env:MCB_RUSTC
        MCB_SKIP_CONTROL_TESTS = $env:MCB_SKIP_CONTROL_TESTS
    }
    try {
        $env:PATH = "$fakeBin$([IO.Path]::PathSeparator)$savedPath"
        $env:MCB_CARGO = Join-Path $fakeBin 'cargo.cmd'
        $env:MCB_GO = Join-Path $fakeBin 'go.cmd'
        $env:MCB_NPM = Join-Path $fakeBin 'npm.cmd'
        $env:MCB_RUSTC = Join-Path $fakeBin 'rustc.cmd'
        # Prevent recursive control-test orchestration when the isolated verifier runs.
        $env:MCB_SKIP_CONTROL_TESTS = '1'
        $outputLines = & (Get-Command pwsh).Source -NoProfile -File $verifier 2>&1
        $exitCode = $LASTEXITCODE
        $output = $outputLines | Out-String
    } finally {
        $env:PATH = $savedPath
        foreach ($name in $savedOverrides.Keys) {
            Set-Item -Path "env:$name" -Value $savedOverrides[$name]
        }
    }

    Assert-Equal -Actual ($exitCode -ne 0) -Expected $true -Message 'late roster failure must return nonzero'
    Assert-Equal -Actual ($output -match 'check=cross-language-vectors state=PASS') -Expected $true -Message "test did not reach the injected late roster failure:`n$output"
    Assert-Equal -Actual ($output -match '"structural_result"\s*:|"deployment_outcome"\s*:') -Expected $false -Message 'failed run emitted a success or deployment label'
    Assert-Equal -Actual (Get-FileHash -Algorithm SHA256 -LiteralPath $structuralPath).Hash -Expected $beforeStructuralHash -Message 'failed run changed committed structural evidence bytes'
    Assert-Equal -Actual (Get-FileHash -Algorithm SHA256 -LiteralPath $conformancePath).Hash -Expected $beforeConformanceHash -Message 'failed run changed committed conformance evidence bytes'
    Assert-Equal -Actual (Get-Item -LiteralPath $structuralPath).LastWriteTimeUtc.Ticks -Expected $beforeStructuralWrite -Message 'failed run rewrote committed structural evidence'
    Assert-Equal -Actual (Get-Item -LiteralPath $conformancePath).LastWriteTimeUtc.Ticks -Expected $beforeConformanceWrite -Message 'failed run rewrote committed conformance evidence'

    Write-Output 'test=late-failure-preserves-committed-evidence state=PASS'
} finally {
    if ($KeepTemp) {
        Write-Output "integration_temp=$tempRoot"
    } elseif (Test-Path -LiteralPath $tempRoot) {
        $resolved = (Resolve-Path -LiteralPath $tempRoot).Path
        $resolvedTemp = (Resolve-Path -LiteralPath $env:TEMP).Path
        if (-not $resolved.StartsWith($resolvedTemp + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "refusing to remove integration directory outside TEMP: $resolved"
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
