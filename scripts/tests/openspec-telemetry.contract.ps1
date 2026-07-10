$ErrorActionPreference = 'Stop'

# Verifies the verifier applies OpenSpec telemetry opt-out before OpenSpec use.
# Uses a disposable snapshot so no user-global OpenSpec config is written.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$verifierSource = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'scripts\verify-reference-harness.ps1')

foreach ($token in @('OPENSPEC_TELEMETRY', 'DO_NOT_TRACK', "OPENSPEC_TELEMETRY = '0'", "DO_NOT_TRACK = '1'")) {
    if (-not $verifierSource.Contains($token)) {
        throw "verify-reference-harness.ps1 missing telemetry control token: $token"
    }
}

# The first *call* to Get-ToolVersions (version discovery) must follow an opt-out assignment.
$callMarker = '$toolVersions = Get-ToolVersions'
$firstOptOut = $verifierSource.IndexOf("OPENSPEC_TELEMETRY = '0'", [StringComparison]::Ordinal)
$versionCall = $verifierSource.IndexOf($callMarker, [StringComparison]::Ordinal)
if ($firstOptOut -lt 0 -or $versionCall -lt 0 -or $firstOptOut -gt $versionCall) {
    throw 'OpenSpec version discovery must occur only after OPENSPEC_TELEMETRY=0 is assigned'
}

$tempRoot = Join-Path $env:TEMP ('mcb-openspec-telemetry-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
try {
    $configHome = Join-Path $tempRoot 'config'
    $dataHome = Join-Path $tempRoot 'data'
    New-Item -ItemType Directory -Path $configHome, $dataHome | Out-Null

    $saved = @{
        OPENSPEC_TELEMETRY = $env:OPENSPEC_TELEMETRY
        DO_NOT_TRACK = $env:DO_NOT_TRACK
        XDG_CONFIG_HOME = $env:XDG_CONFIG_HOME
        XDG_DATA_HOME = $env:XDG_DATA_HOME
        HOME = $env:HOME
    }
    try {
        $env:OPENSPEC_TELEMETRY = '0'
        $env:DO_NOT_TRACK = '1'
        $env:XDG_CONFIG_HOME = $configHome
        $env:XDG_DATA_HOME = $dataHome

        $openspec = Join-Path $repoRoot 'node_modules\.bin\openspec.cmd'
        if (-not (Test-Path -LiteralPath $openspec)) {
            throw "openspec binary missing: $openspec"
        }
        $version = & $openspec --version 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "openspec --version failed: $version"
        }
        if ($env:OPENSPEC_TELEMETRY -ne '0' -or $env:DO_NOT_TRACK -ne '1') {
            throw 'telemetry opt-out variables were cleared during OpenSpec invocation'
        }

        $written = @(Get-ChildItem -LiteralPath $configHome, $dataHome -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer })
        if ($written.Count -gt 0) {
            throw "OpenSpec wrote user config/data under isolated homes: $($written.FullName -join ', ')"
        }
    } finally {
        foreach ($name in $saved.Keys) {
            Set-Item -Path "env:$name" -Value $saved[$name]
        }
    }
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output 'test=openspec-telemetry-contract state=PASS'
