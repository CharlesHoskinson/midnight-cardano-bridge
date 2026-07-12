$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptPath = Join-Path $repoRoot 'scripts\compare-reference-harness.ps1'
$command = Get-Command $scriptPath
if (-not $command.Parameters.ContainsKey('EvidencePath')) {
    throw 'compare-reference-harness.ps1 does not declare -EvidencePath'
}
$source = Get-Content -Raw -LiteralPath $scriptPath
foreach ($requiredToken in @('$env:MCB_CARGO', '$env:MCB_GO', '--locked', '--offline')) {
    if (-not $source.Contains($requiredToken)) {
        throw "compare-reference-harness.ps1 is missing required verifier token $requiredToken"
    }
}

$publishedPath = Join-Path $repoRoot 'reference\evidence\structural-report-v1.json'
$publishedHash = if (Test-Path -LiteralPath $publishedPath) {
    (Get-FileHash -Algorithm SHA256 -LiteralPath $publishedPath).Hash
} else {
    $null
}
$candidatePath = Join-Path ([IO.Path]::GetTempPath()) ("mcb-structural-candidate-{0}.json" -f [guid]::NewGuid())
try {
    & $scriptPath -EvidencePath $candidatePath
    if ($LASTEXITCODE -ne 0) {
        throw "comparison failed with exit $LASTEXITCODE"
    }
    if (-not (Test-Path -LiteralPath $candidatePath)) {
        throw 'comparison did not write the requested candidate path'
    }
    if ([IO.File]::ReadAllBytes($candidatePath) -contains 13) {
        throw 'comparison candidate contains noncanonical CR bytes'
    }
    $candidate = Get-Content -Raw -LiteralPath $candidatePath | ConvertFrom-Json
    foreach ($field in @(
        'root_set_cbor_hex',
        'root_set_hash_preimage_hex',
        'deployment_domain_hash_preimage_hex',
        'reset_root_set_cbor_hex',
        'reset_root_set_hash_preimage_hex',
        'reset_deployment_domain_hash_preimage_hex',
        'source_event_identity_cbor_hex',
        'continuity_hash_preimage_hex',
        'gate_record_set_cbor_hex',
        'gate_record_set_hash_preimage_hex',
        'gate_record_count',
        'outcome_classifier_row',
        'open_activation_gate_count',
        'unresolved_consensus_gate_count'
    )) {
        if ($null -eq $candidate.PSObject.Properties[$field]) {
            throw "candidate evidence is missing $field"
        }
    }
    if ($candidate.deployment_outcome -ne 'blocked' -or $candidate.activation_eligible -ne $false) {
        throw 'candidate evidence made an activating claim'
    }
    if ($publishedHash) {
        $after = (Get-FileHash -Algorithm SHA256 -LiteralPath $publishedPath).Hash
        if ($after -ne $publishedHash) {
            throw 'comparison rewrote published structural evidence'
        }
    }
} finally {
    Remove-Item -LiteralPath $candidatePath -Force -ErrorAction SilentlyContinue
}
