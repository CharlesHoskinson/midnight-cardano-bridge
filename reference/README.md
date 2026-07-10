# Reference harness

This directory contains an executable structural harness for the bridge
contracts. It checks encodings, root and domain derivation, reset behavior,
proof byte layout, observation provenance, and fail-closed outcome reporting.
It does not verify a chain proof or submit a transaction.

## Run the full check

From the repository root:

```powershell
pwsh -NoProfile -File scripts/verify-reference-harness.ps1
```

The command runs:

1. Rust unit and integration tests.
2. Go tests and `go vet`.
3. Python observation tests without network access.
4. Rust and Go report comparison against the shared vectors.
5. Gate-roster byte, digest, id, and count checks.
6. Validation of the two captured unsigned observations.
7. Strict validation of every OpenSpec spec and active change.
8. `git diff --check`.

The verifier writes
`reference/evidence/conformance-report-v1.json`. A successful run must contain:

```json
{
  "cryptographic_verification": false,
  "destination_execution_confirmed": false,
  "structural_result": "structural-pass",
  "deployment_outcome": "blocked",
  "activation_eligible": false
}
```

`structural-pass` means the implemented codecs, parsers, vectors, and safety
checks agree. It is not evidence that Cardano accepted a Midnight proof or that
Midnight accepted a Cardano proof.

## Toolchains

The checked Windows host uses Rust 1.90, Go 1.25.7, PowerShell 7.6, and Python
3.14 with Scrapling 0.4.10. The scripts use `cargo` and `go` from `PATH` when
available. They also recognize these host-local fallbacks:

```text
C:\Users\charl\.cargo\bin\cargo.exe
C:\Users\charl\.local\toolchains\go1.25.7\go\bin\go.exe
```

The Python checks use `.venv-scrapling\Scripts\python.exe`. Run the PowerShell
scripts with `pwsh`; the machine's Windows PowerShell execution policy blocks
unsigned scripts.

## What is implemented

The Rust and Go harnesses independently encode the bounded JSON subset as
deterministic CBOR. Both reproduce the published 7,705-byte gate roster and its
SHA-256 digest, then derive the structural root set, deployment domain, reset
domain, and continuity key. The shared profile is
`mcb.structural-lab.sha256-cbor.v1`. It is fixed to
`activation_eligible=false`.

The Go BSB22 command parses exact proof, verification-key, and public-scalar
lengths. It checks the public scalar against the BLS12-381 scalar-field modulus
and exposes the accepted byte offsets. It does not decode curve points, perform
subgroup checks, evaluate pairings, verify the Halo2/KZG decider, or execute a
Plutus validator. Its result always carries
`cryptographic_verification=false`, with `S01-BLOCK-04` and `S01-BLOCK-06`
unresolved.

The Python adapter uses Scrapling for all public HTTP requests. It records the
endpoint, request method, request-body digest, observation time, raw-response
digest, adapter revision, and `trust=unsigned-observation`. The validator
rejects any attempt to change that trust label. Live reads are not part of the
offline verifier.

## Component commands

```powershell
C:\Users\charl\.cargo\bin\cargo.exe test --manifest-path reference/rust/Cargo.toml --all-targets

Push-Location reference/go
C:\Users\charl\.local\toolchains\go1.25.7\go\bin\go.exe test ./...
C:\Users\charl\.local\toolchains\go1.25.7\go\bin\go.exe vet ./...
Pop-Location

.\.venv-scrapling\Scripts\python.exe -m unittest discover -s reference/observers/tests -v
pwsh -NoProfile -File scripts/compare-reference-harness.ps1
npm run openspec:validate
```

The structural CLIs accept the same shared fixture:

```powershell
C:\Users\charl\.cargo\bin\cargo.exe run --quiet --manifest-path reference/rust/Cargo.toml --bin mcb-rust -- run reference/fixtures/structural-v1.json .

Push-Location reference/go
C:\Users\charl\.local\toolchains\go1.25.7\go\bin\go.exe run ./cmd/mcb-go run ../fixtures/structural-v1.json ../..
Pop-Location
```

## Scrapling observations

These commands perform explicit live reads and overwrite the named evidence
files with new timestamps and response digests:

```powershell
.\.venv-scrapling\Scripts\python.exe reference/observers/observe.py live-midnight reference/evidence/observations/midnight-preview-unsigned.json
.\.venv-scrapling\Scripts\python.exe reference/observers/observe.py live-mithril reference/evidence/observations/mithril-preview-unsigned.json
```

The committed observations came from Midnight Preview RPC and the official
Mithril pre-release Preview aggregator. They show endpoint availability and
response shape. They do not authenticate finality, certify an SCLS entity, or
prove event inclusion.

Fixtures can be normalized without a network request:

```powershell
.\.venv-scrapling\Scripts\python.exe reference/observers/observe.py fixture midnight reference/observers/fixtures/midnight-finalized-v1.json midnight-observation.json 2026-07-10T00:00:00Z
```

## Open gates and host limits

All six activation blockers remain open:

- `S01-BLOCK-01/catalog-completeness`: the source-backed 42 Cardano and 52
  Midnight predicate catalogs are missing.
- `S01-BLOCK-02/public-scls-availability`: the public Mithril SCLS profile has
  not been observed.
- `S01-BLOCK-03/event-inclusion`: the authenticated Midnight event-to-header-to-MMR
  path is incomplete.
- `S01-BLOCK-04/full-decider`: the full Halo2/KZG decider inside BSB22 has not
  been implemented or measured.
- `S01-BLOCK-05/midnight-execution`: no Midnight operation has accepted the
  external Cardano proof and committed the state transition.
- `S01-BLOCK-06/cardano-execution`: no Cardano validator has accepted the
  wrapped Midnight relation and committed the state transition.

The eight `CONS-*` gates are also unresolved. Docker is not installed, and WSL
cannot start a distribution until its Windows component is enabled. Compact and
the Midnight proof server therefore cannot run on this host. The harness does
not turn either limitation into fixture-backed deployment evidence.
