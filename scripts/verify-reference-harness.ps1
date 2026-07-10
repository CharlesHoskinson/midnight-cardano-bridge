$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$cargo = if (Get-Command cargo -ErrorAction SilentlyContinue) {
    (Get-Command cargo).Source
} else {
    Join-Path $HOME '.cargo\bin\cargo.exe'
}
$go = if (Get-Command go -ErrorAction SilentlyContinue) {
    (Get-Command go).Source
} else {
    Join-Path $HOME '.local\toolchains\go1.25.7\go\bin\go.exe'
}
$python = Join-Path $repoRoot '.venv-scrapling\Scripts\python.exe'
$npm = (Get-Command npm.cmd -ErrorAction Stop).Source
$git = (Get-Command git.exe -ErrorAction Stop).Source

foreach ($tool in @($cargo, $go, $python, $npm, $git)) {
    if (-not (Test-Path -LiteralPath $tool)) {
        throw "required tool not found: $tool"
    }
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [scriptblock] $Command
    )

    Write-Output "check=$Name state=RUNNING"
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "check failed: $Name (exit $LASTEXITCODE)"
    }
    Write-Output "check=$Name state=PASS"
}

function Assert-RosterPublication {
    $publicationPath = Join-Path $repoRoot 'protocol\gate-roster-v1.json'
    $hexPath = Join-Path $repoRoot 'protocol\gate-roster-v1.cbor.hex'
    $publication = Get-Content -Raw -LiteralPath $publicationPath | ConvertFrom-Json
    $hex = (Get-Content -Raw -LiteralPath $hexPath) -replace '\s', ''

    if ($hex -notmatch '^[0-9a-f]+$' -or $hex.Length % 2 -ne 0) {
        throw 'published roster CBOR hex is not canonical lowercase hexadecimal'
    }
    $bytes = [Convert]::FromHexString($hex)
    $digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    $expected = '2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f'
    if ($bytes.Length -ne 7705 -or $digest -ne $expected) {
        throw "published roster bytes mismatch: bytes=$($bytes.Length) sha256=$digest"
    }
    if ($publication.canonical_cbor_sha256 -ne $digest) {
        throw 'roster publication wrapper does not bind the published CBOR bytes'
    }

    $gateIds = @($publication.roster.entries | ForEach-Object { $_.gate_id })
    if (($gateIds | Sort-Object -Unique).Count -ne 14) {
        throw 'gate roster ids are not 14 unique values'
    }
    $blockerCount = @($gateIds | Where-Object { $_ -match '^S01-BLOCK-' }).Count
    $consensusCount = @($gateIds | Where-Object { $_ -match '^CONS-' }).Count
    if ($blockerCount -ne 6 -or $consensusCount -ne 8) {
        throw "gate roster partition mismatch: blockers=$blockerCount consensus=$consensusCount"
    }
    return [ordered]@{
        sha256 = $digest
        cbor_bytes = $bytes.Length
        blocker_count = $blockerCount
        consensus_gate_count = $consensusCount
    }
}

function Assert-UnsignedObservations {
    $paths = @(
        (Join-Path $repoRoot 'reference\evidence\observations\midnight-preview-unsigned.json'),
        (Join-Path $repoRoot 'reference\evidence\observations\mithril-preview-unsigned.json')
    )
    $digests = [ordered]@{}
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "unsigned observation missing: $path"
        }
        $record = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
        if ($record.trust -ne 'unsigned-observation' -or $record.data.gate_status -ne 'unresolved') {
            throw "unsafe observation claim: $path"
        }
        foreach ($field in @('request_body_sha256', 'raw_response_sha256')) {
            if ($record.$field -notmatch '^[0-9a-f]{64}$') {
                throw "invalid observation digest ${field}: $path"
            }
        }
        $digests[(Split-Path -Leaf $path)] = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
    }
    return $digests
}

Push-Location $repoRoot
try {
    Invoke-Checked 'rust-tests' {
        & $cargo test --manifest-path (Join-Path $repoRoot 'reference\rust\Cargo.toml') --all-targets
    }

    Push-Location (Join-Path $repoRoot 'reference\go')
    try {
        Invoke-Checked 'go-tests' { & $go test ./... }
        Invoke-Checked 'go-vet' { & $go vet ./... }
    } finally {
        Pop-Location
    }

    Invoke-Checked 'observation-tests' {
        & $python -m unittest discover -s (Join-Path $repoRoot 'reference\observers\tests') -v
    }
    Invoke-Checked 'cross-language-vectors' {
        & (Join-Path $repoRoot 'scripts\compare-reference-harness.ps1')
    }

    $roster = Assert-RosterPublication
    Write-Output 'check=roster-publication state=PASS'
    $observationDigests = Assert-UnsignedObservations
    Write-Output 'check=unsigned-observations state=PASS'

    Invoke-Checked 'openspec-strict' { & $npm run openspec:validate }
    Invoke-Checked 'git-diff-check' { & $git diff --check }

    $structuralPath = Join-Path $repoRoot 'reference\evidence\structural-report-v1.json'
    if (-not (Test-Path -LiteralPath $structuralPath)) {
        throw "structural evidence missing: $structuralPath"
    }
    $structural = Get-Content -Raw -LiteralPath $structuralPath | ConvertFrom-Json
    if (
        $structural.structural_result -ne 'structural-pass' -or
        $structural.deployment_outcome -ne 'blocked' -or
        $structural.activation_eligible -ne $false
    ) {
        throw 'structural evidence made an unsafe deployment claim'
    }
    if ($structural.roster_sha256 -ne $roster.sha256 -or $structural.roster_cbor_bytes -ne $roster.cbor_bytes) {
        throw 'structural report does not bind the verified gate roster publication'
    }

    $summary = [ordered]@{
        schema_version = 1
        profile_id = $structural.profile_id
        verified_components = @(
            'rust-structural-harness',
            'go-structural-harness',
            'go-bsb22-parser-only',
            'scrapling-observation-normalizer',
            'cross-language-vectors',
            'gate-roster-publication',
            'openspec-strict'
        )
        roster_sha256 = $roster.sha256
        roster_cbor_bytes = $roster.cbor_bytes
        open_activation_gate_count = $roster.blocker_count
        unresolved_consensus_gate_count = $roster.consensus_gate_count
        observation_trust = 'unsigned-observation'
        observation_file_sha256 = $observationDigests
        cryptographic_verification = $false
        destination_execution_confirmed = $false
        structural_result = 'structural-pass'
        deployment_outcome = 'blocked'
        activation_eligible = $false
    }
    $summaryPath = Join-Path $repoRoot 'reference\evidence\conformance-report-v1.json'
    $json = $summary | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($summaryPath, $json + "`n", [Text.UTF8Encoding]::new($false))
    Write-Output ($summary | ConvertTo-Json -Depth 8 -Compress)
} finally {
    Pop-Location
}
