# Reference harness

This directory contains an executable structural harness for the bridge
contracts. It checks encodings, root and domain derivation, reset behavior,
proof byte layout, observation provenance, and fail-closed outcome reporting.
It does not verify a chain proof or submit a transaction.

## Bootstrap a clean checkout

From the repository root:

```powershell
pwsh -NoProfile -File scripts/setup-reference-harness.ps1
```

Setup runs `npm ci`, recreates `.venv-scrapling`, installs the exact Windows
Python 3.14 transitive lock in
`reference/observers/requirements.lock.txt`, and runs `cargo fetch --locked`.
`requirements.txt` remains the short top-level intent: it requests Scrapling's
`fetchers` extra and cbor2, without the unrelated `ai` or `shell` extras. The
lock is the minimal resolved closure of that intent. Setup verifies both pins,
and the verifier normalizes Python distribution names and requires the installed
set to equal the lock exactly. Setup may contact package registries for
dependencies. It never calls a
Midnight, Mithril, Cardano, or other public data endpoint. Use `-WhatIf` to
validate the host and print planned operations without changing it.

The supported Windows toolchain is exact:

| Tool | Version |
| --- | --- |
| PowerShell | 7.6.3 |
| Rust / Cargo | 1.90.0 |
| Go | 1.25.7 |
| Python | 3.14.6 |
| Node.js / npm | 24.18.0 / 11.16.0 |
| Git | 2.55.0.windows.1 |
| OpenSpec | 1.5.0 |
| Scrapling / cbor2 | 0.4.10 / 5.7.1 |

Tools are resolved from `PATH`. Custom installations can be selected with
`MCB_CARGO`, `MCB_RUSTC`, `MCB_GO`, `MCB_PYTHON`, `MCB_NODE`, `MCB_NPM`, and
`MCB_GIT`. Cargo and rustc also recognize the standard `$HOME/.cargo/bin`
installation. The verifier always uses the repository venv created by setup.
Go also recognizes the prepared-host
`$HOME/.local/toolchains/go1.25.7/go/bin` installation.

Run scripts with `pwsh`, not Windows PowerShell.

## Run the offline check

After bootstrap:

```powershell
pwsh -NoProfile -File scripts/verify-reference-harness.ps1
```

The command runs:

1. Rust unit and integration tests with `--locked --offline` and a temporary target directory.
2. Go tests and `go vet`.
3. Python observation tests with bytecode writes disabled.
4. Rust and Go comparison into a temporary structural report.
5. Exact gate-roster, classifier, and unsigned-observation checks.
6. Independent cbor2 reproduction of roster, root/reset, event, and gate-record bytes.
7. Strict offline validation of every OpenSpec spec and active change.
8. `git diff --check`, input-stability checks, and byte comparison with committed evidence.

The default verifier is read-only. Cargo, Go, npm, and candidate evidence use a
new directory under the system temporary directory. A failure publishes no
`structural-pass` or deployment label and leaves committed evidence untouched.

The files under `reference/evidence/` are input-bound golden evidence, not a
mutable status file for the last invocation. The conformance report binds the
candidate structural-report hash, every deterministic input hash, verifier
revision, exact commands and tool versions, and exit semantics. A successful
default run requires regenerated candidates to be byte-identical to both
committed reports.

After reviewing an intentional input change, update both reports only with a
fully successful run:

```powershell
pwsh -NoProfile -File scripts/verify-reference-harness.ps1 -UpdateEvidence
```

The update stages both candidates and replaces the committed pair only after
every check passes. Successful conformance evidence contains:

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

## What is implemented

The Rust and Go harnesses independently encode the bounded JSON subset as
deterministic CBOR. Both reproduce the published 7,705-byte gate roster and its
SHA-256 digest, then derive the structural root set, deployment domain, reset
domain, and continuity key. Root-set and source-event inputs use closed schemas;
the root producer DAG rejects cycles, missing producers, and post-domain
dependencies. Each digest preimage is emitted with an unsigned 64-bit big-endian
domain length, domain bytes, unsigned 64-bit big-endian body length, and body
bytes so cbor2 can reproduce it independently.

The reset vector is a `state-bearing-continuity-migration`: changing the fresh
deployment id changes root/domain values, the imported consumed event remains
rejected, and an unrelated event remains unused. The synthetic classifier
derives its selected row and labels from the complete gate-record set,
destination-transition confirmations, independent successor reads, retention,
and selected profile. These are structural fixture labels, never observations of
a deployed bridge. The shared profile is
`mcb.structural-lab.sha256-cbor.v1` and is fixed to
`activation_eligible=false`.

The Go BSB22 command parses exact proof, verification-key, and public-scalar
lengths. It checks the public scalar against the BLS12-381 scalar-field modulus
and exposes the accepted byte offsets. It does not decode curve points, perform
subgroup checks, evaluate pairings, verify the Halo2/KZG decider, or execute a
Plutus validator. Its result always carries
`cryptographic_verification=false`, with `S01-BLOCK-04/full-decider` and
`S01-BLOCK-06/cardano-execution` unresolved.

The Python adapter uses Scrapling for all public HTTP requests. It records the
endpoint, request method, request-body digest, observation time, raw-response
digest, adapter revision, and `trust=unsigned-observation`. The validator
rejects any attempt to change that trust label. Live reads are not part of the
offline verifier.

## Component commands

```powershell
cargo test --locked --offline --manifest-path reference/rust/Cargo.toml --all-targets

Push-Location reference/go
go test ./...
go vet ./...
Pop-Location

.\.venv-scrapling\Scripts\python.exe -B -m unittest discover -s reference/observers/tests -v
$candidate = Join-Path $env:TEMP 'mcb-structural-candidate.json'
pwsh -NoProfile -File scripts/compare-reference-harness.ps1 -EvidencePath $candidate
npm --offline run openspec:validate
```

If `cargo` or `go` is not on `PATH`, invoke the path configured in
`MCB_CARGO` or `MCB_GO` instead.

The structural CLIs accept the same shared fixture:

```powershell
cargo run --locked --offline --quiet --manifest-path reference/rust/Cargo.toml --bin mcb-rust -- run reference/fixtures/structural-v1.json .

Push-Location reference/go
go run ./cmd/mcb-go run ../fixtures/structural-v1.json ../..
Pop-Location
```

## Scrapling observations

These are the only documented commands that perform live public reads. They
overwrite the named unsigned capture envelopes with new timestamps, exact
request/response bytes, statuses, and digests:

```powershell
.\.venv-scrapling\Scripts\python.exe reference/observers/observe.py live-midnight reference/evidence/observations/midnight-preview-unsigned.json
.\.venv-scrapling\Scripts\python.exe reference/observers/observe.py live-mithril reference/evidence/observations/mithril-preview-unsigned.json
```

The committed observations came from Midnight Preview RPC and the official
Mithril pre-release Preview aggregator. They show endpoint availability and
response shape. They do not authenticate finality, certify an SCLS entity, or
prove event inclusion.

Captured envelopes can be normalized without a network request:

```powershell
.\.venv-scrapling\Scripts\python.exe reference/observers/observe.py fixture reference/observers/fixtures/midnight-finalized-v1.json midnight-observation.json
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
