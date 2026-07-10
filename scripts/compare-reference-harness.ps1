[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $EvidencePath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fixturePath = Join-Path $repoRoot 'reference\fixtures\structural-v1.json'
$publishedPath = [IO.Path]::GetFullPath((Join-Path $repoRoot 'reference\evidence\structural-report-v1.json'))
if (-not [IO.Path]::IsPathFullyQualified($EvidencePath)) {
    throw '-EvidencePath must be an absolute path'
}
$evidencePath = [IO.Path]::GetFullPath($EvidencePath)
if ($evidencePath -eq $publishedPath) {
    throw 'comparison refuses to publish directly to reference/evidence/structural-report-v1.json'
}
$evidenceParent = Split-Path -Parent $evidencePath
if (-not (Test-Path -LiteralPath $evidenceParent -PathType Container)) {
    throw "evidence parent directory does not exist: $evidenceParent"
}

$cargo = if ($env:MCB_CARGO) {
    $env:MCB_CARGO
} elseif (Get-Command cargo -ErrorAction SilentlyContinue) {
    (Get-Command cargo).Source
} else {
    Join-Path $HOME '.cargo\bin\cargo.exe'
}
$go = if ($env:MCB_GO) {
    $env:MCB_GO
} elseif (Get-Command go -ErrorAction SilentlyContinue) {
    (Get-Command go).Source
} else {
    Join-Path $HOME '.local\toolchains\go1.25.7\go\bin\go.exe'
}
if (-not (Test-Path -LiteralPath $cargo)) { throw "cargo not found at $cargo" }
if (-not (Test-Path -LiteralPath $go)) { throw "go not found at $go" }

$rustJson = & $cargo run --locked --offline --quiet --manifest-path (Join-Path $repoRoot 'reference\rust\Cargo.toml') --bin mcb-rust -- run $fixturePath $repoRoot
if ($LASTEXITCODE -ne 0) { throw 'Rust structural harness failed' }
$rust = $rustJson | ConvertFrom-Json

Push-Location (Join-Path $repoRoot 'reference\go')
try {
    $goJson = & $go run ./cmd/mcb-go run ../fixtures/structural-v1.json ../..
    if ($LASTEXITCODE -ne 0) { throw 'Go structural harness failed' }
} finally {
    Pop-Location
}
$goReport = $goJson | ConvertFrom-Json
$fixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json

$missingIndexPath = Join-Path ([IO.Path]::GetTempPath()) ("mcb-missing-event-index-{0}.json" -f [guid]::NewGuid())
try {
    $missingIndexFixture = Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json
    $missingIndexFixture.source_event_identity.PSObject.Properties.Remove('source_action_or_event_index')
    $missingIndexJson = $missingIndexFixture | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($missingIndexPath, $missingIndexJson + "`n", [Text.UTF8Encoding]::new($false))

    $rustRejectionLines = & $cargo run --locked --offline --quiet --manifest-path (Join-Path $repoRoot 'reference\rust\Cargo.toml') --bin mcb-rust -- run $missingIndexPath $repoRoot 2>&1
    $rustRejectionExit = $LASTEXITCODE
    Push-Location (Join-Path $repoRoot 'reference\go')
    try {
        $goRejectionLines = & $go run ./cmd/mcb-go run $missingIndexPath ../.. 2>&1
        $goRejectionExit = $LASTEXITCODE
    } finally {
        Pop-Location
    }

    foreach ($rejection in @(
        @{ Name = 'Rust'; Exit = $rustRejectionExit; Output = ($rustRejectionLines | Out-String).Trim() },
        @{ Name = 'Go'; Exit = $goRejectionExit; Output = ($goRejectionLines | Out-String).Trim() }
    )) {
        if ($rejection.Exit -eq 0) {
            throw "$($rejection.Name) accepted SourceEventIdentityV1 without source_action_or_event_index"
        }
        if ($rejection.Output -notmatch 'source-event-schema:') {
            throw "$($rejection.Name) missing-index rejection was not source-event-schema: $($rejection.Output)"
        }
    }
} finally {
    Remove-Item -LiteralPath $missingIndexPath -Force -ErrorAction SilentlyContinue
}

$rustFields = @($rust.PSObject.Properties.Name | Sort-Object)
$goFields = @($goReport.PSObject.Properties.Name | Sort-Object)
if (($rustFields -join "`n") -ne ($goFields -join "`n")) {
    throw "cross-language report field mismatch: Rust=$($rustFields -join ',') Go=$($goFields -join ',')"
}
foreach ($field in $rustFields) {
    if ($rust.$field -ne $goReport.$field) {
        throw "cross-language mismatch for ${field}: Rust=$($rust.$field) Go=$($goReport.$field)"
    }
}

$goldenFields = @(
    'schema_version',
    'profile_id',
    'roster_sha256',
    'roster_cbor_bytes',
    'root_set_digest',
    'deployment_domain',
    'reset_mode',
    'reset_root_set_digest',
    'reset_deployment_domain',
    'continuity_key',
    'reset_continuity_key',
    'unrelated_continuity_key',
    'imported_consumed_continuity_key_count',
    'same_event_replay_result',
    'unrelated_event_replay_result',
    'producer_dag_valid',
    'producer_dag_node_count',
    'gate_record_set_valid',
    'gate_record_count',
    'gate_record_set_digest',
    'selected_profile',
    'outcome_classifier_row',
    'classifier_vector_label',
    'open_activation_gate_count',
    'unresolved_consensus_gate_count',
    'structural_result',
    'deployment_outcome',
    'activation_eligible'
)
foreach ($field in $goldenFields) {
    if ($null -eq $fixture.expected.PSObject.Properties[$field]) {
        throw "missing expected.$field"
    }
    if ($rust.$field -ne $fixture.expected.$field) {
        throw "golden mismatch for ${field}: actual=$($rust.$field) expected=$($fixture.expected.$field)"
    }
}

$evidence = [ordered]@{
    fixture = 'reference/fixtures/structural-v1.json'
    verified_implementations = @('rust', 'go')
}
foreach ($field in @($rust.PSObject.Properties.Name)) {
    $evidence[$field] = $rust.$field
}
$json = $evidence | ConvertTo-Json -Depth 12
[IO.File]::WriteAllText($evidencePath, $json + "`n", [Text.UTF8Encoding]::new($false))

$global:LASTEXITCODE = 0
Write-Output "cross_language_structural=PASS evidence=$evidencePath"
