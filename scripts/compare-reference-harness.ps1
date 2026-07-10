$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fixturePath = Join-Path $repoRoot 'reference\fixtures\structural-v1.json'
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

if (-not (Test-Path -LiteralPath $cargo)) { throw "cargo not found at $cargo" }
if (-not (Test-Path -LiteralPath $go)) { throw "go not found at $go" }

$rustJson = & $cargo run --quiet --manifest-path (Join-Path $repoRoot 'reference\rust\Cargo.toml') --bin mcb-rust -- run $fixturePath $repoRoot
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

$fields = @(
    'schema_version',
    'profile_id',
    'roster_sha256',
    'roster_cbor_bytes',
    'root_set_digest',
    'deployment_domain',
    'reset_root_set_digest',
    'reset_deployment_domain',
    'continuity_key',
    'reset_continuity_key',
    'structural_result',
    'deployment_outcome',
    'activation_eligible'
)

foreach ($field in $fields) {
    if ($rust.$field -ne $goReport.$field) {
        throw "cross-language mismatch for ${field}: Rust=$($rust.$field) Go=$($goReport.$field)"
    }
    if ($null -eq $fixture.expected.PSObject.Properties[$field]) {
        throw "missing expected.$field"
    }
    if ($rust.$field -ne $fixture.expected.$field) {
        throw "golden mismatch for ${field}: actual=$($rust.$field) expected=$($fixture.expected.$field)"
    }
}

$evidence = [ordered]@{
    schema_version = 1
    fixture = 'reference/fixtures/structural-v1.json'
    verified_implementations = @('rust', 'go')
    profile_id = $rust.profile_id
    roster_sha256 = $rust.roster_sha256
    roster_cbor_bytes = $rust.roster_cbor_bytes
    root_set_digest = $rust.root_set_digest
    deployment_domain = $rust.deployment_domain
    reset_root_set_digest = $rust.reset_root_set_digest
    reset_deployment_domain = $rust.reset_deployment_domain
    continuity_key = $rust.continuity_key
    reset_continuity_key = $rust.reset_continuity_key
    structural_result = $rust.structural_result
    deployment_outcome = $rust.deployment_outcome
    activation_eligible = $rust.activation_eligible
}

$evidenceDir = Join-Path $repoRoot 'reference\evidence'
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null
$evidencePath = Join-Path $evidenceDir 'structural-report-v1.json'
$json = $evidence | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($evidencePath, $json + "`n", [Text.UTF8Encoding]::new($false))

Write-Output "cross_language_structural=PASS evidence=$evidencePath"
