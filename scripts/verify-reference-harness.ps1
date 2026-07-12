[CmdletBinding()]
param(
    [switch] $UpdateEvidence
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:CurrentCheck = 'initialization'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$runRoot = $null
Import-Module (Join-Path $PSScriptRoot 'CommittedInputManifest.psm1') -Force

$expectedVersions = [ordered]@{
    powershell = '7.6.3'
    cargo = '1.90.0'
    rustc = '1.90.0'
    go = '1.25.7'
    python = '3.14.6'
    node = '24.18.0'
    npm = '11.16.0'
    git = '2.55.0.windows.1'
    openspec = '1.5.0'
    scrapling = '0.4.10'
    cbor2 = '5.7.1'
}

function Resolve-Tool {
    param(
        [Parameter(Mandatory)] [string[]] $Names,
        [Parameter(Mandatory)] [string] $EnvironmentVariable,
        [string[]] $FallbackPaths = @()
    )

    $override = [Environment]::GetEnvironmentVariable($EnvironmentVariable)
    if ($override) {
        if (-not (Test-Path -LiteralPath $override -PathType Leaf)) {
            throw "$EnvironmentVariable does not name an executable file: $override"
        }
        return (Resolve-Path -LiteralPath $override).Path
    }

    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command -and $command.Source) {
            return $command.Source
        }
    }
    foreach ($path in $FallbackPaths) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $path).Path
        }
    }
    throw "required tool not found: $($Names -join ', ') (override with $EnvironmentVariable)"
}

function Invoke-Captured {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [string[]] $Arguments = @()
    )

    $output = & $Path @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "command failed ($LASTEXITCODE): $Path $($Arguments -join ' ')"
    }
    return (($output | Out-String).Trim())
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [scriptblock] $Command
    )

    $script:CurrentCheck = $Name
    Write-Output "check=$Name state=RUNNING"
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "check failed: $Name (exit $LASTEXITCODE)"
    }
    Write-Output "check=$Name state=PASS"
}

function Assert-Equal {
    param(
        [Parameter(Mandatory)] $Actual,
        [Parameter(Mandatory)] $Expected,
        [Parameter(Mandatory)] [string] $Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message (expected=$Expected actual=$Actual)"
    }
}

function Assert-Version {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Actual
    )

    Assert-Equal -Actual $Actual -Expected $expectedVersions[$Name] -Message "unsupported $Name version"
}

function Get-PythonPackageVersion {
    param(
        [Parameter(Mandatory)] [string] $Python,
        [Parameter(Mandatory)] [string] $Package
    )

    $output = & $Python -B -c "import importlib.metadata as m; print(m.version('$Package'))" 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }
    return (($output | Out-String).Trim())
}

function Get-PythonDistributionVersions {
    param([Parameter(Mandatory)] [string] $Python)

    $code = @'
import importlib.metadata as metadata
import json
import re

versions = {}
for distribution in metadata.distributions():
    raw_name = distribution.metadata.get("Name")
    if raw_name:
        name = re.sub(r"[-_.]+", "-", raw_name.casefold())
        if name != "pip":
            versions[name] = distribution.version
print(json.dumps(dict(sorted(versions.items())), separators=(",", ":")))
'@
    $json = Invoke-Captured -Path $Python -Arguments @('-B', '-c', $code)
    return ($json | ConvertFrom-Json)
}

function Get-LockedPythonPackages {
    param([Parameter(Mandatory)] [string] $Path)

    $packages = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $value = $line.Trim().TrimEnd('\')
        if (-not $value -or $value.StartsWith('#') -or $value.StartsWith('--hash=')) { continue }
        if ($value -notmatch '^(?<name>[A-Za-z0-9][A-Za-z0-9._-]*)==(?<version>[^\s;\\]+)') {
            throw "Python lock entry is not an exact name==version pin: $value"
        }
        $name = [regex]::Replace($Matches.name.ToLowerInvariant(), '[-_.]+', '-')
        if ($packages.ContainsKey($name)) { throw "duplicate normalized Python lock package: $name" }
        $packages[$name] = $Matches.version
    }
    $ordered = [ordered]@{}
    foreach ($name in @($packages.Keys | Sort-Object -CaseSensitive)) { $ordered[$name] = $packages[$name] }
    return $ordered
}

function Assert-PythonLockMatch {
    param(
        [Parameter(Mandatory)] $Locked,
        [Parameter(Mandatory)] $Installed
    )

    $lockedJson = $Locked | ConvertTo-Json -Compress
    $installedJson = $Installed | ConvertTo-Json -Compress
    Assert-Equal -Actual $installedJson -Expected $lockedJson -Message 'installed Python distributions do not match requirements.lock.txt'
}

function Get-ToolVersions {
    param(
        [Parameter(Mandatory)] [hashtable] $Tools
    )

    $cargoText = Invoke-Captured -Path $Tools.cargo -Arguments @('--version')
    $rustcText = Invoke-Captured -Path $Tools.rustc -Arguments @('--version')
    $goText = Invoke-Captured -Path $Tools.go -Arguments @('version')
    $gitText = Invoke-Captured -Path $Tools.git -Arguments @('--version')

    if ($cargoText -notmatch '^cargo (?<version>\d+\.\d+\.\d+) ') { throw "unrecognized cargo version: $cargoText" }
    $cargoVersion = $Matches.version
    if ($rustcText -notmatch '^rustc (?<version>\d+\.\d+\.\d+) ') { throw "unrecognized rustc version: $rustcText" }
    $rustcVersion = $Matches.version
    if ($goText -notmatch '^go version go(?<version>\d+\.\d+\.\d+) ') { throw "unrecognized go version: $goText" }
    $goVersion = $Matches.version
    if ($gitText -notmatch '^git version (?<version>\S+)$') { throw "unrecognized git version: $gitText" }
    $gitVersion = $Matches.version

    $versions = [ordered]@{
        powershell = $PSVersionTable.PSVersion.ToString()
        cargo = $cargoVersion
        rustc = $rustcVersion
        go = $goVersion
        python = Invoke-Captured -Path $Tools.python -Arguments @('-B', '-c', 'import platform; print(platform.python_version())')
        node = (Invoke-Captured -Path $Tools.node -Arguments @('--version')).TrimStart('v')
        npm = Invoke-Captured -Path $Tools.npm -Arguments @('--version')
        git = $gitVersion
        openspec = Invoke-Captured -Path $Tools.openspec -Arguments @('--version')
        scrapling = Get-PythonPackageVersion -Python $Tools.python -Package 'scrapling'
        cbor2 = Get-PythonPackageVersion -Python $Tools.python -Package 'cbor2'
    }

    foreach ($name in @('powershell', 'cargo', 'rustc', 'go', 'python', 'node', 'npm', 'git', 'openspec', 'scrapling')) {
        if (-not $versions[$name]) { throw "required version could not be read: $name" }
        Assert-Version -Name $name -Actual $versions[$name]
    }
    if ($versions.cbor2) {
        Assert-Version -Name 'cbor2' -Actual $versions.cbor2
    } else {
        $versions.cbor2 = 'not-installed'
    }
    return $versions
}

function Get-RosterPublication {
    $publicationPath = Join-Path $repoRoot 'protocol\gate-roster-v1.json'
    $hexPath = Join-Path $repoRoot 'protocol\gate-roster-v1.cbor.hex'
    $publication = Get-Content -Raw -LiteralPath $publicationPath | ConvertFrom-Json
    $hex = (Get-Content -Raw -LiteralPath $hexPath) -replace '\s', ''

    if ($hex -notmatch '^[0-9a-f]+$' -or $hex.Length % 2 -ne 0) {
        throw 'published roster CBOR is not canonical lowercase hexadecimal'
    }
    $bytes = [Convert]::FromHexString($hex)
    $digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    Assert-Equal -Actual $bytes.Length -Expected 7705 -Message 'published roster byte length mismatch'
    Assert-Equal -Actual $digest -Expected '2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f' -Message 'published roster digest mismatch'
    Assert-Equal -Actual $publication.canonical_cbor_sha256 -Expected $digest -Message 'roster wrapper does not bind the published bytes'

    $expectedGateIds = @(
        'S01-BLOCK-01/catalog-completeness',
        'S01-BLOCK-02/public-scls-availability',
        'S01-BLOCK-03/event-inclusion',
        'S01-BLOCK-04/full-decider',
        'S01-BLOCK-05/midnight-execution',
        'S01-BLOCK-06/cardano-execution',
        'CONS-BOOT-01',
        'CONS-CARDANO-01',
        'CONS-BEEFY-01',
        'CONS-CHECKPOINT-01',
        'CONS-MIDNIGHT-ID-01',
        'CONS-DOMAIN-01',
        'CONS-FRESH-01',
        'CONS-FREEZE-01'
    )
    $actualGateIds = @($publication.roster.entries | ForEach-Object { $_.gate_id })
    Assert-Equal -Actual ($actualGateIds.Count) -Expected $expectedGateIds.Count -Message 'gate roster count mismatch'
    for ($index = 0; $index -lt $expectedGateIds.Count; $index++) {
        Assert-Equal -Actual $actualGateIds[$index] -Expected $expectedGateIds[$index] -Message "gate roster id mismatch at index $index"
    }

    return [ordered]@{
        sha256 = $digest
        cbor_bytes = $bytes.Length
        blocker_count = 6
        consensus_gate_count = 8
    }
}

function Invoke-ThirdCborCheck {
    param(
        [Parameter(Mandatory)] [string] $Python,
        [Parameter(Mandatory)] [string] $Cbor2Version,
        [Parameter(Mandatory)] [string] $StructuralCandidate
    )

    if ($Cbor2Version -eq 'not-installed') {
        throw 'cbor2 5.7.1 is required for the independent CBOR check; run scripts/setup-reference-harness.ps1'
    }
    $code = @'
import hashlib
import json
import pathlib
import sys
import cbor2

publication = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
published = bytes.fromhex("".join(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8").split()))
fixture = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding="utf-8"))
report = json.loads(pathlib.Path(sys.argv[4]).read_text(encoding="utf-8"))
encoded = cbor2.dumps(publication["roster"], canonical=True)
if encoded != published:
    raise SystemExit("independent-cbor-byte-mismatch")

def require_cbor(field, value):
    if field not in report:
        raise SystemExit(f"missing-independent-byte-field:{field}")
    actual = bytes.fromhex(report[field])
    expected = cbor2.dumps(value, canonical=True)
    if actual != expected:
        raise SystemExit(f"independent-cbor-byte-mismatch:{field}")
    return expected

def require_frame(field, domain, body):
    if field not in report:
        raise SystemExit(f"missing-independent-frame-field:{field}")
    domain_bytes = domain.encode("utf-8")
    expected = len(domain_bytes).to_bytes(8, "big") + domain_bytes + len(body).to_bytes(8, "big") + body
    if bytes.fromhex(report[field]) != expected:
        raise SystemExit(f"independent-hash-frame-mismatch:{field}")

def typed_root(root):
    return {
        "bridge_program_id": root["bridge_program_id"],
        "fresh_deployment_instance_id": bytes.fromhex(root["fresh_deployment_instance_id"]),
        "source_identity_fingerprints": [
            {
                "chain": item["chain"],
                "identity_digest": bytes.fromhex(item["identity_digest"]),
                "protocol_fingerprint": bytes.fromhex(item["protocol_fingerprint"]),
            }
            for item in root["source_identity_fingerprints"]
        ],
        "checkpoint_manifest_digests": [
            bytes.fromhex(value) for value in root["checkpoint_manifest_digests"]
        ],
        "semantic_registry_template_root": bytes.fromhex(root["semantic_registry_template_root"]),
        "artifact_template_root": bytes.fromhex(root["artifact_template_root"]),
        "destination_abi_template_digests": [
            bytes.fromhex(value) for value in root["destination_abi_template_digests"]
        ],
        "deployment_recipe_digests": [
            bytes.fromhex(value) for value in root["deployment_recipe_digests"]
        ],
        "replay_policy_template_digest": bytes.fromhex(root["replay_policy_template_digest"]),
        "freshness_policy_template_digest": bytes.fromhex(root["freshness_policy_template_digest"]),
    }

def typed_event(event):
    return {
        "version": event["version"],
        "source_chain_identity_digest": bytes.fromhex(event["source_chain_identity_digest"]),
        "source_handler_or_namespace": event["source_handler_or_namespace"],
        "source_transaction_or_object_id": bytes.fromhex(event["source_transaction_or_object_id"]),
        "source_action_or_event_index": event["source_action_or_event_index"],
        "event_discriminator": event["event_discriminator"],
        "source_event_commitment": bytes.fromhex(event["source_event_commitment"]),
    }

root_cbor = require_cbor("root_set_cbor_hex", typed_root(fixture["root_set"]))
reset_root = dict(fixture["root_set"])
reset_root["fresh_deployment_instance_id"] = fixture["reset_fresh_deployment_instance_id"]
reset_cbor = require_cbor("reset_root_set_cbor_hex", typed_root(reset_root))
event_cbor = require_cbor("source_event_identity_cbor_hex", typed_event(fixture["source_event_identity"]))
reset_event_cbor = require_cbor("reset_source_event_identity_cbor_hex", typed_event(fixture["source_event_identity"]))
unrelated_event_cbor = require_cbor(
    "unrelated_source_event_identity_cbor_hex",
    typed_event(fixture["continuity_replay"]["unrelated_event"]),
)
statuses = {record["gate_id"]: record for record in fixture["outcome_classifier"]["gate_statuses"]}
roster_entries = publication["roster"]["entries"]
if set(statuses) != {entry["gate_id"] for entry in roster_entries}:
    raise SystemExit("independent-gate-overlay-mismatch")
merged_gate_records = []
for entry in roster_entries:
    status = statuses[entry["gate_id"]]
    record = dict(entry)
    record.update({
        "gate_id": status["gate_id"],
        "status": status["status"],
        "evidence_digest": bytes.fromhex(status["evidence_digest"]),
        "evidence_retention_valid": status["evidence_retention_valid"],
    })
    merged_gate_records.append(record)
gate_cbor = require_cbor("gate_record_set_cbor_hex", merged_gate_records)
gate_records = cbor2.loads(bytes.fromhex(report["gate_record_set_cbor_hex"]))
if not isinstance(gate_records, list):
    raise SystemExit("invalid-candidate-gate-record-set")
open_activation = sum(
    1 for record in gate_records
    if record.get("gate_id", "").startswith("S01-BLOCK-") and record.get("status") != "passed"
)
unresolved_consensus = sum(
    1 for record in gate_records
    if record.get("gate_id", "").startswith("CONS-") and record.get("status") == "unresolved"
)

require_frame("root_set_hash_preimage_hex", "mcb/deployment-root-set/v1", root_cbor)
require_frame("reset_root_set_hash_preimage_hex", "mcb/deployment-root-set/v1", reset_cbor)
require_frame("deployment_domain_hash_preimage_hex", "mcb/deployment-domain/v1", bytes.fromhex(report["root_set_digest"]))
require_frame("reset_deployment_domain_hash_preimage_hex", "mcb/deployment-domain/v1", bytes.fromhex(report["reset_root_set_digest"]))
require_frame("continuity_hash_preimage_hex", "mcb/continuity-key/v1", event_cbor)
require_frame("reset_continuity_hash_preimage_hex", "mcb/continuity-key/v1", reset_event_cbor)
require_frame("unrelated_continuity_hash_preimage_hex", "mcb/continuity-key/v1", unrelated_event_cbor)
require_frame("gate_record_set_hash_preimage_hex", "mcb/structural-gate-record-set/v1", gate_cbor)

print(json.dumps({
    "bytes": len(encoded),
    "sha256": hashlib.sha256(encoded).hexdigest(),
    "verified_candidate_fields": 15,
    "gate_record_count": len(gate_records),
    "open_activation_gate_count": open_activation,
    "unresolved_consensus_gate_count": unresolved_consensus,
}, separators=(",", ":")))
'@
    $result = & $Python -B -c $code `
        (Join-Path $repoRoot 'protocol\gate-roster-v1.json') `
        (Join-Path $repoRoot 'protocol\gate-roster-v1.cbor.hex') `
        (Join-Path $repoRoot 'reference\fixtures\structural-v1.json') `
        $StructuralCandidate 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "independent CBOR check failed: $(($result | Out-String).Trim())"
    }
    $parsed = ($result | Out-String) | ConvertFrom-Json
    Assert-Equal -Actual $parsed.bytes -Expected 7705 -Message 'independent CBOR byte length mismatch'
    Assert-Equal -Actual $parsed.sha256 -Expected '2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f' -Message 'independent CBOR digest mismatch'
    return $parsed
}

function Get-ObservationDigests {
    param([Parameter(Mandatory)] $InputHashes)
    $directory = Join-Path $repoRoot 'reference\evidence\observations'
    $expected = [ordered]@{
        'midnight-preview-unsigned.json' = [ordered]@{
            chain = 'midnight'
            network = 'preview'
            endpoint = 'https://rpc.preview.midnight.network'
            request_method = 'POST:chain_getFinalizedHead+chain_getHeader'
            affected_gates = @('S01-BLOCK-03/event-inclusion')
            exchange_count = 2
        }
        'mithril-preview-unsigned.json' = [ordered]@{
            chain = 'cardano'
            network = 'pre-release-preview'
            endpoint = 'https://aggregator.pre-release-preview.api.mithril.network/aggregator/certificates'
            request_method = 'GET'
            affected_gates = @('S01-BLOCK-02/public-scls-availability')
            exchange_count = 1
        }
    }
    $actualNames = @(Get-ChildItem -LiteralPath $directory -File -Filter '*-unsigned.json' | Sort-Object Name | Select-Object -ExpandProperty Name)
    $expectedNames = @($expected.Keys | Sort-Object)
    Assert-Equal -Actual ($actualNames -join "`n") -Expected ($expectedNames -join "`n") -Message 'unsigned observation file set mismatch'

    $digests = [ordered]@{}
    foreach ($name in $expected.Keys) {
        $path = Join-Path $directory $name
        $record = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json -DateKind String
        Assert-Equal -Actual $record.schema_version -Expected 1 -Message "observation schema mismatch: $name"
        Assert-Equal -Actual $record.adapter_revision -Expected 'mcb.scrapling-observer.v1' -Message "observation adapter mismatch: $name"
        Assert-Equal -Actual $record.trust -Expected 'unsigned-observation' -Message "unsafe observation trust: $name"
        Assert-Equal -Actual $record.data.gate_status -Expected 'unresolved' -Message "unsafe observation gate status: $name"
        foreach ($field in @('chain', 'network', 'endpoint', 'request_method')) {
            Assert-Equal -Actual $record.$field -Expected $expected[$name][$field] -Message "observation $field mismatch: $name"
        }
        foreach ($field in @('request_body_sha256', 'raw_response_sha256')) {
            if ($record.$field -notmatch '^[0-9a-f]{64}$') {
                throw "invalid observation digest $field`: $name"
            }
        }
        if ($record.capture_sha256 -notmatch '^[0-9a-f]{64}$') {
            throw "invalid observation capture digest: $name"
        }
        if ($record.observed_at -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') {
            throw "invalid observation timestamp: $name"
        }
        $affected = @($record.data.affected_gates)
        Assert-Equal -Actual ($affected -join "`n") -Expected ($expected[$name].affected_gates -join "`n") -Message "affected gate set mismatch: $name"
        $exchanges = @($record.exchanges)
        Assert-Equal -Actual $exchanges.Count -Expected $expected[$name].exchange_count -Message "exchange count mismatch: $name"
        Assert-Equal -Actual (@($record.response_statuses).Count) -Expected $exchanges.Count -Message "response status count mismatch: $name"
        for ($index = 0; $index -lt $exchanges.Count; $index++) {
            $exchange = $exchanges[$index]
            Assert-Equal -Actual $exchange.response_status -Expected 200 -Message "non-success observation response: $name exchange $index"
            Assert-Equal -Actual $record.response_statuses[$index] -Expected $exchange.response_status -Message "response status binding mismatch: $name exchange $index"
            foreach ($binding in @(
                @('request_body_hex', 'request_body_sha256'),
                @('response_body_hex', 'raw_response_sha256')
            )) {
                $hexValue = [string]$exchange.($binding[0])
                if ($hexValue -notmatch '^[0-9a-f]*$' -or $hexValue.Length % 2 -ne 0) {
                    throw "invalid exchange hex $($binding[0]): $name exchange $index"
                }
                $body = [Convert]::FromHexString($hexValue)
                $bodyDigest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($body)).ToLowerInvariant()
                Assert-Equal -Actual $exchange.($binding[1]) -Expected $bodyDigest -Message "exchange digest mismatch $($binding[1]): $name exchange $index"
            }
        }
        if ($name -eq 'midnight-preview-unsigned.json') {
            foreach ($field in @('finality_evaluation', 'event_inclusion_evaluation', 'destination_execution_evaluation')) {
                Assert-Equal -Actual $record.data.$field -Expected 'not-performed' -Message "unsafe Midnight evaluation: $field"
            }
        } else {
            Assert-Equal -Actual $record.data.scls_profile_evaluation -Expected 'not-performed' -Message 'unsafe Mithril SCLS evaluation'
        }
        $relative = "reference/evidence/observations/$name"
        $digests[$name] = $InputHashes[$relative]
    }
    return $digests
}

function Assert-StructuralCandidate {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] $Roster,
        [Parameter(Mandatory)] $CborSummary
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "cross-language candidate is missing: $Path"
    }
    $report = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    Assert-Equal -Actual $report.schema_version -Expected 1 -Message 'structural report schema mismatch'
    Assert-Equal -Actual $report.profile_id -Expected 'mcb.structural-lab.sha256-cbor.v1' -Message 'structural profile mismatch'
    Assert-Equal -Actual $report.roster_sha256 -Expected $Roster.sha256 -Message 'structural report roster digest mismatch'
    Assert-Equal -Actual $report.roster_cbor_bytes -Expected $Roster.cbor_bytes -Message 'structural report roster length mismatch'
    Assert-Equal -Actual $report.structural_result -Expected 'structural-pass' -Message 'candidate structural checks did not pass'
    Assert-Equal -Actual $report.deployment_outcome -Expected 'blocked' -Message 'candidate deployment outcome is unsafe'
    Assert-Equal -Actual $report.activation_eligible -Expected $false -Message 'candidate is activation eligible'
    Assert-Equal -Actual $report.reset_mode -Expected 'state-bearing-continuity-migration' -Message 'candidate reset mode mismatch'
    Assert-Equal -Actual $report.same_event_replay_result -Expected 'rejected-consumed' -Message 'candidate did not reject the imported consumed event'
    Assert-Equal -Actual $report.unrelated_event_replay_result -Expected 'accepted-unused' -Message 'candidate did not accept the unrelated unused event'
    Assert-Equal -Actual $report.producer_dag_valid -Expected $true -Message 'candidate producer DAG is invalid'
    Assert-Equal -Actual $report.gate_record_set_valid -Expected $true -Message 'candidate gate-record set is invalid'
    Assert-Equal -Actual $report.selected_profile -Expected 'public' -Message 'candidate selected profile mismatch'
    Assert-Equal -Actual $report.evidence_retention_valid -Expected $true -Message 'candidate evidence retention is invalid'
    foreach ($field in @(
        'cardano_to_midnight_transition_confirmed',
        'cardano_to_midnight_successor_state_read_confirmed',
        'midnight_to_cardano_transition_confirmed',
        'midnight_to_cardano_successor_state_read_confirmed'
    )) {
        Assert-Equal -Actual $report.$field -Expected $false -Message "candidate unexpectedly confirms destination evidence: $field"
    }
    Assert-Equal -Actual $report.gate_record_count -Expected $CborSummary.gate_record_count -Message 'candidate gate-record count mismatch'
    if ($report.outcome_classifier_row -notin @(1, 2, 3, 4, 5)) {
        throw "invalid candidate outcome classifier row: $($report.outcome_classifier_row)"
    }
    if ($null -ne $report.PSObject.Properties['open_activation_gate_count']) {
        Assert-Equal -Actual $report.open_activation_gate_count -Expected $CborSummary.open_activation_gate_count -Message 'candidate activation-gate count mismatch'
    }
    if ($null -ne $report.PSObject.Properties['unresolved_consensus_gate_count']) {
        Assert-Equal -Actual $report.unresolved_consensus_gate_count -Expected $CborSummary.unresolved_consensus_gate_count -Message 'candidate consensus-gate count mismatch'
    }
    return [pscustomobject]@{
        report = $report
        open_activation_gate_count = $CborSummary.open_activation_gate_count
        unresolved_consensus_gate_count = $CborSummary.unresolved_consensus_gate_count
        outcome_classifier_row = $report.outcome_classifier_row
    }
}

function Get-InputFileHashes {
    param(
        [Parameter(Mandatory)] [string] $GitPath,
        [string] $Snapshot = 'HEAD'
    )
    return Get-CommittedInputManifest `
        -RepositoryRoot $repoRoot `
        -GitPath $GitPath `
        -Snapshot $Snapshot `
        -Pathspec @(
            '.gitattributes',
            'package.json',
            'package-lock.json',
            'scripts',
            'protocol',
            'reference/rust',
            'reference/go',
            'reference/observers',
            'reference/fixtures',
            'reference/evidence/bootstrap',
            'reference/evidence/observations',
            'openspec'
        )
}

function Assert-HashManifestUnchanged {
    param(
        [Parameter(Mandatory)] $Before,
        [Parameter(Mandatory)] $After
    )

    $beforeJson = $Before | ConvertTo-Json -Depth 20 -Compress
    $afterJson = $After | ConvertTo-Json -Depth 20 -Compress
    Assert-Equal -Actual $afterJson -Expected $beforeJson -Message 'verification inputs changed during the run'
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] $Value
    )

    $json = $Value | ConvertTo-Json -Depth 30
    [IO.File]::WriteAllText($Path, $json + "`n", [Text.UTF8Encoding]::new($false))
}

function Assert-ByteIdentical {
    param(
        [Parameter(Mandatory)] [string] $Candidate,
        [Parameter(Mandatory)] [string] $Committed,
        [Parameter(Mandatory)] [string] $Name
    )

    if (-not (Test-Path -LiteralPath $Committed -PathType Leaf)) {
        throw "committed $Name evidence is missing: $Committed"
    }
    $actual = [IO.File]::ReadAllBytes($Candidate)
    $expected = [IO.File]::ReadAllBytes($Committed)
    if ($actual.Length -ne $expected.Length) {
        throw "$Name evidence differs from the committed input-bound golden; review and run with -UpdateEvidence"
    }
    for ($index = 0; $index -lt $actual.Length; $index++) {
        if ($actual[$index] -ne $expected[$index]) {
            throw "$Name evidence differs from the committed input-bound golden; review and run with -UpdateEvidence"
        }
    }
}

function Move-Replace {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination
    )

    [IO.File]::Move($Source, $Destination, $true)
}

function Get-EvidenceGenerationRoot {
    param([Parameter(Mandatory)] [string] $RepoRoot)
    return (Join-Path $RepoRoot 'reference\evidence\generations')
}

function Get-CurrentGenerationPointerPath {
    param([Parameter(Mandatory)] [string] $RepoRoot)
    return (Join-Path $RepoRoot 'reference\evidence\current-generation.json')
}

function Read-CurrentGeneration {
    param([Parameter(Mandatory)] [string] $RepoRoot)

    $pointerPath = Get-CurrentGenerationPointerPath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $pointerPath -PathType Leaf)) {
        throw 'current-generation pointer is missing'
    }
    $pointer = Get-Content -Raw -LiteralPath $pointerPath | ConvertFrom-Json
    if (-not $pointer.generation_id) { throw 'current-generation pointer lacks generation_id' }
    $genDir = Join-Path (Get-EvidenceGenerationRoot -RepoRoot $RepoRoot) $pointer.generation_id
    $structural = Join-Path $genDir 'structural-report-v1.json'
    $conformance = Join-Path $genDir 'conformance-report-v1.json'
    if (-not (Test-Path -LiteralPath $structural -PathType Leaf) -or -not (Test-Path -LiteralPath $conformance -PathType Leaf)) {
        throw "current generation $($pointer.generation_id) is incomplete"
    }
    $structuralHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $structural).Hash.ToLowerInvariant()
    $conformanceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $conformance).Hash.ToLowerInvariant()
    if ($pointer.structural_sha256 -ne $structuralHash -or $pointer.conformance_sha256 -ne $conformanceHash) {
        throw "current generation $($pointer.generation_id) hashes do not match generation files"
    }
    return [ordered]@{
        generation_id = $pointer.generation_id
        structural_path = $structural
        conformance_path = $conformance
        structural_sha256 = $structuralHash
        conformance_sha256 = $conformanceHash
        pointer_path = $pointerPath
    }
}

function Publish-EvidencePair {
    param(
        [Parameter(Mandatory)] [string] $StructuralCandidate,
        [Parameter(Mandatory)] [string] $ConformanceCandidate,
        [Parameter(Mandatory)] [string] $RepoRoot
    )

    # Stage an immutable generation on the destination volume, verify the pair,
    # then publish the small current-generation pointer last.
    $generationRoot = Get-EvidenceGenerationRoot -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $generationRoot)) {
        New-Item -ItemType Directory -Force -Path $generationRoot | Out-Null
    }
    $generationId = [guid]::NewGuid().ToString('N')
    $stageDir = Join-Path $generationRoot $generationId
    New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

    $stagedStructural = Join-Path $stageDir 'structural-report-v1.json'
    $stagedConformance = Join-Path $stageDir 'conformance-report-v1.json'
    $stagedPointer = Join-Path $stageDir 'generation-manifest.json'

    try {
        [IO.File]::Copy($StructuralCandidate, $stagedStructural, $true)
        [IO.File]::Copy($ConformanceCandidate, $stagedConformance, $true)
        $structuralHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $stagedStructural).Hash.ToLowerInvariant()
        $conformanceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $stagedConformance).Hash.ToLowerInvariant()
        $manifest = [ordered]@{
            schema_version = 1
            generation_id = $generationId
            structural_sha256 = $structuralHash
            conformance_sha256 = $conformanceHash
            structural_file = 'structural-report-v1.json'
            conformance_file = 'conformance-report-v1.json'
            report_roles = [ordered]@{
                structural = 'payload'
                conformance = 'envelope'
            }
            published_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        }
        Write-JsonFile -Path $stagedPointer -Value $manifest

        # Verify full pair before pointer publication.
        Assert-ByteIdentical -Candidate $stagedStructural -Committed $StructuralCandidate -Name 'staged-structural'
        Assert-ByteIdentical -Candidate $stagedConformance -Committed $ConformanceCandidate -Name 'staged-conformance'
        if ($structuralHash.Length -ne 64 -or $conformanceHash.Length -ne 64) {
            throw 'staged generation produced invalid hashes'
        }

        # Mirror convenience copies for stable paths (byte-identical to generation).
        $mirrorStructural = Join-Path $RepoRoot 'reference\evidence\structural-report-v1.json'
        $mirrorConformance = Join-Path $RepoRoot 'reference\evidence\conformance-report-v1.json'
        [IO.File]::Copy($stagedStructural, $mirrorStructural, $true)
        [IO.File]::Copy($stagedConformance, $mirrorConformance, $true)

        $pointerPath = Get-CurrentGenerationPointerPath -RepoRoot $RepoRoot
        $pointer = [ordered]@{
            schema_version = 1
            generation_id = $generationId
            structural_sha256 = $structuralHash
            conformance_sha256 = $conformanceHash
            structural_relative_path = "generations/$generationId/structural-report-v1.json"
            conformance_relative_path = "generations/$generationId/conformance-report-v1.json"
        }
        $pointerTemp = Join-Path $stageDir 'current-generation.pointer.tmp'
        Write-JsonFile -Path $pointerTemp -Value $pointer
        Move-Replace -Source $pointerTemp -Destination $pointerPath
    } catch {
        if (Test-Path -LiteralPath $stageDir) {
            Remove-Item -LiteralPath $stageDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        throw
    }
}

function Set-RunEnvironment {
    param(
        [Parameter(Mandatory)] [string] $RunDirectory,
        [Parameter(Mandatory)] [hashtable] $Tools
    )

    $names = @(
        'ALL_PROXY', 'CARGO_NET_OFFLINE', 'CARGO_TARGET_DIR', 'GOCACHE', 'GOTOOLCHAIN',
        'HTTP_PROXY', 'HTTPS_PROXY', 'MCB_CARGO', 'MCB_GO', 'MCB_OFFLINE',
        'npm_config_cache', 'npm_config_offline', 'NO_PROXY', 'PYTHONDONTWRITEBYTECODE',
        'OPENSPEC_TELEMETRY', 'DO_NOT_TRACK', 'CI'
    )
    $saved = @{}
    foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name) }

    $env:CARGO_NET_OFFLINE = 'true'
    $env:CARGO_TARGET_DIR = Join-Path $RunDirectory 'cargo-target'
    $env:GOCACHE = Join-Path $RunDirectory 'go-cache'
    $env:GOTOOLCHAIN = 'local'
    $env:MCB_CARGO = $Tools.cargo
    $env:MCB_GO = $Tools.go
    $env:MCB_OFFLINE = '1'
    $env:npm_config_cache = Join-Path $RunDirectory 'npm-cache'
    $env:npm_config_offline = 'true'
    $env:PYTHONDONTWRITEBYTECODE = '1'
    $env:OPENSPEC_TELEMETRY = '0'
    $env:DO_NOT_TRACK = '1'
    $env:HTTP_PROXY = 'http://127.0.0.1:9'
    $env:HTTPS_PROXY = 'http://127.0.0.1:9'
    $env:ALL_PROXY = 'http://127.0.0.1:9'
    $env:NO_PROXY = ''
    return $saved
}

$script:CommandRecords = [System.Collections.Generic.List[object]]::new()

function ConvertTo-EvidencePath {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $RepoRoot,
        [string] $RunRoot = $null
    )

    $full = [IO.Path]::GetFullPath($Path)
    $repo = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
    if ($RunRoot) {
        $run = [IO.Path]::GetFullPath($RunRoot).TrimEnd('\', '/')
        if ($full.StartsWith($run + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
            $full.Equals($run, [StringComparison]::OrdinalIgnoreCase)) {
            $suffix = if ($full.Length -gt $run.Length) { $full.Substring($run.Length).TrimStart('\', '/') } else { '' }
            if ($suffix) { return '${RUN_TEMP}/' + ($suffix -replace '\\', '/') }
            return '${RUN_TEMP}'
        }
    }
    if ($full.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        $full.Equals($repo, [StringComparison]::OrdinalIgnoreCase)) {
        $suffix = if ($full.Length -gt $repo.Length) { $full.Substring($repo.Length).TrimStart('\', '/') } else { '' }
        if ($suffix) { return '${REPO}/' + ($suffix -replace '\\', '/') }
        return '${REPO}'
    }
    # Keep tool identity, not host-absolute install paths.
    return [IO.Path]::GetFileName($full)
}

function ConvertTo-OrderedOfflineEnvironment {
    param([hashtable] $OfflineEnvironment)

    $ordered = [ordered]@{}
    foreach ($key in @($OfflineEnvironment.Keys | Sort-Object -CaseSensitive)) {
        $ordered[$key] = [string]$OfflineEnvironment[$key]
    }
    return $ordered
}

function New-CommandRecord {
    param(
        [Parameter(Mandatory)] [string] $LogicalTool,
        [Parameter(Mandatory)] [string] $Executable,
        [Parameter(Mandatory)] [string] $Cwd,
        [Parameter(Mandatory)] [string[]] $Argv,
        [string] $PinnedVersion = '',
        [hashtable] $OfflineEnvironment = @{},
        [string] $InlineSourceSha256 = $null,
        [int] $ExitCode = 0,
        [string] $RepoRoot = $null,
        [string] $RunRoot = $null
    )

    $root = if ($RepoRoot) { $RepoRoot } else { $script:repoRoot }
    $run = if ($RunRoot) { $RunRoot } else { $script:runRoot }
    $normalizedArgv = @($Argv | ForEach-Object {
        $arg = $_
        if (-not $arg) { return $arg }
        # Keep package patterns and flags intact (./..., --offline, etc.).
        if ($arg.StartsWith('.') -or $arg.StartsWith('-') -or $arg -notmatch '[\\/:]') {
            return $arg
        }
        if ([IO.Path]::IsPathRooted($arg) -or $arg -match '^[A-Za-z]:[\\/]' -or $arg -match '[\\/]') {
            ConvertTo-EvidencePath -Path $arg -RepoRoot $root -RunRoot $run
        } else {
            $arg
        }
    })
    $record = [ordered]@{
        logical_tool = $LogicalTool
        executable = ConvertTo-EvidencePath -Path $Executable -RepoRoot $root -RunRoot $run
        pinned_version = $PinnedVersion
        cwd = ConvertTo-EvidencePath -Path $Cwd -RepoRoot $root -RunRoot $run
        argv = $normalizedArgv
        offline_environment = ConvertTo-OrderedOfflineEnvironment -OfflineEnvironment $OfflineEnvironment
        exit_code = $ExitCode
    }
    if ($InlineSourceSha256) {
        $record.inline_source_sha256 = $InlineSourceSha256
    }
    return $record
}

function Invoke-Recorded {
    param(
        [Parameter(Mandatory)] [string] $LogicalTool,
        [Parameter(Mandatory)] [string] $Executable,
        [Parameter(Mandatory)] [string] $Cwd,
        [Parameter(Mandatory)] [string[]] $Argv,
        [string] $PinnedVersion = '',
        [hashtable] $OfflineEnvironment = @{},
        [string] $InlineSourceSha256 = $null
    )

    Push-Location $Cwd
    try {
        $output = & $Executable @Argv 2>&1
        $code = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    $record = New-CommandRecord -LogicalTool $LogicalTool -Executable $Executable -Cwd $Cwd -Argv $Argv `
        -PinnedVersion $PinnedVersion -OfflineEnvironment $OfflineEnvironment -InlineSourceSha256 $InlineSourceSha256 -ExitCode $code `
        -RepoRoot $repoRoot -RunRoot $runRoot
    $script:CommandRecords.Add($record) | Out-Null
    if ($code -ne 0) {
        throw "command failed ($code): $LogicalTool"
    }
    return $output
}

function Restore-Environment {
    param([Parameter(Mandatory)] [hashtable] $Saved)
    foreach ($name in $Saved.Keys) {
        [Environment]::SetEnvironmentVariable($name, $Saved[$name])
    }
}

$savedEnvironment = $null
$exitCode = 1
$successSummaryJson = $null

try {
    $script:CurrentCheck = 'tool-discovery'
    $venvPython = if ($IsWindows) {
        Join-Path $repoRoot '.venv-scrapling\Scripts\python.exe'
    } else {
        Join-Path $repoRoot '.venv-scrapling/bin/python'
    }
    $tools = @{
        cargo = Resolve-Tool -Names @('cargo.exe', 'cargo') -EnvironmentVariable 'MCB_CARGO' -FallbackPaths @((Join-Path $HOME '.cargo\bin\cargo.exe'), (Join-Path $HOME '.cargo/bin/cargo'))
        rustc = Resolve-Tool -Names @('rustc.exe', 'rustc') -EnvironmentVariable 'MCB_RUSTC' -FallbackPaths @((Join-Path $HOME '.cargo\bin\rustc.exe'), (Join-Path $HOME '.cargo/bin/rustc'))
        go = Resolve-Tool -Names @('go.exe', 'go') -EnvironmentVariable 'MCB_GO' -FallbackPaths @((Join-Path $HOME '.local\toolchains\go1.25.7\go\bin\go.exe'), (Join-Path $HOME '.local/toolchains/go1.25.7/go/bin/go'))
        python = (Resolve-Path -LiteralPath $venvPython -ErrorAction Stop).Path
        node = Resolve-Tool -Names @('node.exe', 'node') -EnvironmentVariable 'MCB_NODE'
        npm = Resolve-Tool -Names @('npm.cmd', 'npm') -EnvironmentVariable 'MCB_NPM'
        git = Resolve-Tool -Names @('git.exe', 'git') -EnvironmentVariable 'MCB_GIT'
        openspec = (Resolve-Path -LiteralPath (Join-Path $repoRoot 'node_modules\.bin\openspec.cmd') -ErrorAction Stop).Path
        compare = (Resolve-Path -LiteralPath (Join-Path $repoRoot 'scripts\compare-reference-harness.ps1') -ErrorAction Stop).Path
    }

    # Telemetry opt-out must be active before any OpenSpec discovery call
    # (including version probes inside Get-ToolVersions).
    $savedTelemetry = @{
        OPENSPEC_TELEMETRY = [Environment]::GetEnvironmentVariable('OPENSPEC_TELEMETRY')
        DO_NOT_TRACK = [Environment]::GetEnvironmentVariable('DO_NOT_TRACK')
    }
    $env:OPENSPEC_TELEMETRY = '0'
    $env:DO_NOT_TRACK = '1'

    $script:CurrentCheck = 'tool-versions'
    $toolVersions = Get-ToolVersions -Tools $tools
    $pythonDistributionVersions = Get-PythonDistributionVersions -Python $tools.python
    $pythonLockPath = Join-Path $repoRoot 'reference\observers\requirements.lock.txt'
    $pythonHashLockPath = Join-Path $repoRoot 'reference\observers\requirements.hashes.txt'
    $lockedPythonDistributionVersions = Get-LockedPythonPackages -Path $pythonLockPath
    Assert-PythonLockMatch -Locked $lockedPythonDistributionVersions -Installed $pythonDistributionVersions
    $hashLockedPackages = Get-LockedPythonPackages -Path $pythonHashLockPath
    Assert-PythonLockMatch -Locked $hashLockedPackages -Installed $pythonDistributionVersions
    $hashLockText = Get-Content -Raw -LiteralPath $pythonHashLockPath
    if (([regex]::Matches($hashLockText, '--hash=sha256:[0-9a-f]{64}')).Count -lt $hashLockedPackages.Count) {
        throw 'Python hash lock is incomplete for installed distributions'
    }
    Write-Output 'check=tool-versions state=PASS'
    Write-Output 'check=python-lock state=PASS'

    $runRoot = Join-Path ([IO.Path]::GetTempPath()) ('mcb-reference-verify-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $runRoot | Out-Null
    $savedEnvironment = Set-RunEnvironment -RunDirectory $runRoot -Tools $tools
    # Merge early telemetry saves so Restore-Environment still restores caller state.
    foreach ($name in $savedTelemetry.Keys) {
        if (-not $savedEnvironment.ContainsKey($name)) {
            $savedEnvironment[$name] = $savedTelemetry[$name]
        }
    }
    if ($env:OPENSPEC_TELEMETRY -ne '0' -or $env:DO_NOT_TRACK -ne '1') {
        throw 'OpenSpec telemetry opt-out environment was not applied'
    }
    $inputHashes = Get-InputFileHashes -GitPath $tools.git
    $script:CommandRecords = [System.Collections.Generic.List[object]]::new()
    $offlineEnv = [ordered]@{
        CARGO_NET_OFFLINE = 'true'
        MCB_OFFLINE = '1'
        npm_config_offline = 'true'
        OPENSPEC_TELEMETRY = '0'
        DO_NOT_TRACK = '1'
        HTTP_PROXY = 'http://127.0.0.1:9'
        HTTPS_PROXY = 'http://127.0.0.1:9'
    }

    Push-Location $repoRoot
    try {
        # Control tests must not recurse into this verifier. The late-failure
        # integration sets MCB_SKIP_CONTROL_TESTS=1 when it invokes an isolated copy.
        if ($env:MCB_SKIP_CONTROL_TESTS -ne '1') {
            Invoke-Checked 'control-tests' {
                $null = Invoke-Recorded -LogicalTool 'pwsh-setup-contract' -Executable (Get-Command pwsh).Source -Cwd $repoRoot `
                    -Argv @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts\tests\setup-reference-harness.contract.ps1')) `
                    -PinnedVersion $toolVersions.powershell -OfflineEnvironment $offlineEnv
                $null = Invoke-Recorded -LogicalTool 'pwsh-compare-tests' -Executable (Get-Command pwsh).Source -Cwd $repoRoot `
                    -Argv @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts\tests\compare-reference-harness.Tests.ps1')) `
                    -PinnedVersion $toolVersions.powershell -OfflineEnvironment $offlineEnv
                $null = Invoke-Recorded -LogicalTool 'pwsh-late-failure-regression' -Executable (Get-Command pwsh).Source -Cwd $repoRoot `
                    -Argv @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts\tests\verify-reference-harness.integration.ps1')) `
                    -PinnedVersion $toolVersions.powershell -OfflineEnvironment $offlineEnv
                $null = Invoke-Recorded -LogicalTool 'pwsh-openspec-telemetry-contract' -Executable (Get-Command pwsh).Source -Cwd $repoRoot `
                    -Argv @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts\tests\openspec-telemetry.contract.ps1')) `
                    -PinnedVersion $toolVersions.powershell -OfflineEnvironment $offlineEnv
                $null = Invoke-Recorded -LogicalTool 'pwsh-committed-input-manifest-contract' -Executable (Get-Command pwsh).Source -Cwd $repoRoot `
                    -Argv @('-NoProfile', '-File', (Join-Path $repoRoot 'scripts\tests\committed-input-manifest.contract.ps1')) `
                    -PinnedVersion $toolVersions.powershell -OfflineEnvironment $offlineEnv
            }
        } else {
            Write-Output 'check=control-tests state=SKIPPED-NON-RECURSIVE'
        }

        Invoke-Checked 'rust-tests' {
            $null = Invoke-Recorded -LogicalTool 'cargo' -Executable $tools.cargo -Cwd $repoRoot `
                -Argv @('test', '--locked', '--offline', '--manifest-path', (Join-Path $repoRoot 'reference\rust\Cargo.toml'), '--all-targets') `
                -PinnedVersion $toolVersions.cargo -OfflineEnvironment $offlineEnv
        }

        Invoke-Checked 'go-tests' {
            $null = Invoke-Recorded -LogicalTool 'go-test' -Executable $tools.go -Cwd (Join-Path $repoRoot 'reference\go') `
                -Argv @('test', './...') -PinnedVersion $toolVersions.go -OfflineEnvironment $offlineEnv
        }
        Invoke-Checked 'go-vet' {
            $null = Invoke-Recorded -LogicalTool 'go-vet' -Executable $tools.go -Cwd (Join-Path $repoRoot 'reference\go') `
                -Argv @('vet', './...') -PinnedVersion $toolVersions.go -OfflineEnvironment $offlineEnv
        }

        Invoke-Checked 'observation-tests' {
            $null = Invoke-Recorded -LogicalTool 'python-unittest' -Executable $tools.python -Cwd $repoRoot `
                -Argv @('-B', '-m', 'unittest', 'discover', '-s', (Join-Path $repoRoot 'reference\observers\tests'), '-v') `
                -PinnedVersion $toolVersions.python -OfflineEnvironment $offlineEnv
        }

        $structuralCandidatePath = Join-Path $runRoot 'structural-report-v1.json'
        Invoke-Checked 'cross-language-vectors' {
            $null = Invoke-Recorded -LogicalTool 'compare-reference-harness' -Executable (Get-Command pwsh).Source -Cwd $repoRoot `
                -Argv @('-NoProfile', '-File', $tools.compare, '-EvidencePath', $structuralCandidatePath) `
                -PinnedVersion $toolVersions.powershell -OfflineEnvironment $offlineEnv
        }

        $script:CurrentCheck = 'roster-publication'
        $roster = Get-RosterPublication
        Write-Output 'check=roster-publication state=PASS'

        $script:CurrentCheck = 'independent-cbor'
        $cborInlineSha = $inputHashes['scripts/verify-reference-harness.ps1']
        $cborSummary = Invoke-ThirdCborCheck -Python $tools.python -Cbor2Version $toolVersions.cbor2 -StructuralCandidate $structuralCandidatePath
        $script:CommandRecords.Add((New-CommandRecord -LogicalTool 'independent-cbor2' -Executable $tools.python -Cwd $repoRoot `
            -Argv @('-B', '-c', '<independent-cbor-check-source-bound>') -PinnedVersion $toolVersions.cbor2 `
            -OfflineEnvironment $offlineEnv -InlineSourceSha256 $cborInlineSha -ExitCode 0 `
            -RepoRoot $repoRoot -RunRoot $runRoot)) | Out-Null
        Write-Output 'check=independent-cbor state=PASS'

        $script:CurrentCheck = 'unsigned-observations'
        $observationDigests = Get-ObservationDigests -InputHashes $inputHashes
        Write-Output 'check=unsigned-observations state=PASS'

        $script:CurrentCheck = 'bootstrap-qualification'
        $bootstrapReceipt = Join-Path $repoRoot 'reference\evidence\bootstrap\clean-checkout-qualification-v1.json'
        if (-not (Test-Path -LiteralPath $bootstrapReceipt -PathType Leaf)) {
            throw 'bootstrap qualification receipt is missing'
        }
        $bootstrap = Get-Content -Raw -LiteralPath $bootstrapReceipt | ConvertFrom-Json
        if ($bootstrap.receipt_kind -ne 'clean-checkout-bootstrap-qualification') {
            throw 'bootstrap receipt kind mismatch'
        }
        if ($bootstrap.network.public_chain_endpoints_reachable -ne $false) {
            throw 'bootstrap receipt must keep public chain endpoints unreachable'
        }
        if ($bootstrap.network.offline_default_verification -ne $true) {
            throw 'bootstrap receipt must declare offline default verification'
        }
        $bootstrapSha = $inputHashes['reference/evidence/bootstrap/clean-checkout-qualification-v1.json']
        Write-Output 'check=bootstrap-qualification state=PASS'

        $script:CurrentCheck = 'structural-candidate'
        $structuralState = Assert-StructuralCandidate -Path $structuralCandidatePath -Roster $roster -CborSummary $cborSummary
        $structural = $structuralState.report
        Write-Output 'check=structural-candidate state=PASS'

        Invoke-Checked 'openspec-strict' {
            $null = Invoke-Recorded -LogicalTool 'npm-openspec-validate' -Executable $tools.npm -Cwd $repoRoot `
                -Argv @('--offline', 'run', 'openspec:validate') -PinnedVersion $toolVersions.npm -OfflineEnvironment $offlineEnv
        }
        Invoke-Checked 'git-diff-check' {
            $null = Invoke-Recorded -LogicalTool 'git' -Executable $tools.git -Cwd $repoRoot `
                -Argv @('diff', '--check') -PinnedVersion $toolVersions.git -OfflineEnvironment $offlineEnv
        }

        $script:CurrentCheck = 'input-stability'
        Assert-HashManifestUnchanged -Before $inputHashes -After (Get-InputFileHashes -GitPath $tools.git)
        Write-Output 'check=input-stability state=PASS'

        $commandRecords = @($script:CommandRecords | ForEach-Object { $_ })
        $summary = [ordered]@{
            schema_version = 1
            report_kind = 'input-bound-golden-conformance'
            report_role = 'envelope'
            profile_id = $structural.profile_id
            verifier_revision = $inputHashes['scripts/verify-reference-harness.ps1']
            tool_versions = $toolVersions
            python_distribution_versions = $pythonDistributionVersions
            python_lock_sha256 = $inputHashes['reference/observers/requirements.lock.txt']
            python_hash_lock_sha256 = $inputHashes['reference/observers/requirements.hashes.txt']
            commands = $commandRecords
            input_file_sha256 = $inputHashes
            structural_report_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $structuralCandidatePath).Hash.ToLowerInvariant()
            structural_payload_role = 'payload-bound-by-hash'
            bootstrap_qualification_sha256 = $bootstrapSha
            verified_components = @(
                'control-tests-setup-compare-late-failure-telemetry-committed-inputs',
                'rust-structural-harness-tests',
                'go-structural-harness-tests',
                'go-vet',
                'go-bsb22-parser-only',
                'scrapling-observation-normalizer-tests',
                'python-transitive-lock-match',
                'python-hash-lock-match',
                'cross-language-vectors',
                'gate-roster-publication',
                'independent-cbor2-structural-bytes',
                'unsigned-observation-validation',
                'bootstrap-qualification-receipt',
                'openspec-strict',
                'git-diff-check'
            )
            roster_sha256 = $roster.sha256
            roster_cbor_bytes = $roster.cbor_bytes
            roster_blocker_entry_count = $roster.blocker_count
            roster_consensus_entry_count = $roster.consensus_gate_count
            open_activation_gate_count = $structuralState.open_activation_gate_count
            unresolved_consensus_gate_count = $structuralState.unresolved_consensus_gate_count
            gate_record_set_digest = $structural.gate_record_set_digest
            reset_mode = $structural.reset_mode
            same_event_replay_result = $structural.same_event_replay_result
            unrelated_event_replay_result = $structural.unrelated_event_replay_result
            producer_dag_valid = $structural.producer_dag_valid
            selected_profile = $structural.selected_profile
            outcome_classifier_row = $structuralState.outcome_classifier_row
            classifier_vector_label = $structural.classifier_vector_label
            observation_trust = 'unsigned-observation'
            observation_file_sha256 = $observationDigests
            cryptographic_verification = $false
            destination_execution_confirmed = $false
            structural_result = 'structural-pass'
            deployment_outcome = 'blocked'
            activation_eligible = $false
            final_exit_semantics = [ordered]@{
                success_exit_code = 0
                failure_exit_code = 1
                verification_status = 'pass'
            }
        }
        $conformanceCandidatePath = Join-Path $runRoot 'conformance-report-v1.json'
        Write-JsonFile -Path $conformanceCandidatePath -Value $summary

        Restore-Environment -Saved $savedEnvironment
        $savedEnvironment = $null

        $structuralDestination = Join-Path $repoRoot 'reference\evidence\structural-report-v1.json'
        $conformanceDestination = Join-Path $repoRoot 'reference\evidence\conformance-report-v1.json'
        $script:CurrentCheck = 'evidence-publication'
        if ($UpdateEvidence) {
            Publish-EvidencePair `
                -StructuralCandidate $structuralCandidatePath `
                -ConformanceCandidate $conformanceCandidatePath `
                -RepoRoot $repoRoot
            Write-Output 'check=evidence-publication state=UPDATED'
        } else {
            $current = Read-CurrentGeneration -RepoRoot $repoRoot
            Assert-ByteIdentical -Candidate $structuralCandidatePath -Committed $current.structural_path -Name 'structural-generation'
            Assert-ByteIdentical -Candidate $conformanceCandidatePath -Committed $current.conformance_path -Name 'conformance-generation'
            Assert-ByteIdentical -Candidate $structuralCandidatePath -Committed $structuralDestination -Name 'structural-mirror'
            Assert-ByteIdentical -Candidate $conformanceCandidatePath -Committed $conformanceDestination -Name 'conformance-mirror'
            if ($current.structural_sha256 -ne $summary.structural_report_sha256) {
                throw 'current-generation structural hash does not match candidate'
            }
            Write-Output 'check=evidence-publication state=PASS'
        }

        $successSummaryJson = $summary | ConvertTo-Json -Depth 30 -Compress
        $exitCode = 0
    } finally {
        Pop-Location
    }
} catch {
    [Console]::Error.WriteLine("verification failed: check=$script:CurrentCheck; $($_.Exception.Message)")
    $exitCode = 1
} finally {
    if ($savedEnvironment) {
        Restore-Environment -Saved $savedEnvironment
    }
    if ($runRoot -and (Test-Path -LiteralPath $runRoot)) {
        $resolvedRun = (Resolve-Path -LiteralPath $runRoot).Path
        $resolvedTemp = (Resolve-Path -LiteralPath ([IO.Path]::GetTempPath())).Path.TrimEnd([IO.Path]::DirectorySeparatorChar)
        if ($resolvedRun.StartsWith($resolvedTemp + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            try {
                Remove-Item -LiteralPath $resolvedRun -Recurse -Force
            } catch {
                [Console]::Error.WriteLine("warning: could not remove verification temp directory: $($_.Exception.Message)")
            }
        } else {
            [Console]::Error.WriteLine("refusing to remove verification directory outside TEMP: $resolvedRun")
            $exitCode = 1
        }
    }
}

if ($exitCode -eq 0 -and $successSummaryJson) {
    Write-Output $successSummaryJson
}
exit $exitCode
