## Evidence dossier

| Artifact | SHA-256 |
|----------|---------|
| proof-reader.md | 245601e4be25877038fc6e2f3b6591f9cfb0c1068b20b6760543bcd9e0c4f1eb |
| consensus-reader.md | b3110272046bffbb3e3a0f537d81911ebc52c925f38af50d0e053132f078e57a |
| operator-reader.md | 3cd112ed3de8725accbb8cca4dbddd47db4d0de5ef07c921a8c5eb34c7caf857 |
| codex request.xml | b4e7786588d0e2df01fb6e48319eaeac2019318f9ac9172c88a46eb080e674d7 |
| codex response.md | d85282af1cd4d200ecfcc7aa573114be1798fdff1b5e6e8f0cf3f78933931cd5 |
| codex transcript.jsonl | d3c924284665196c67ab490a09e38ecac5be2e7d5bfb77665334c4f63c1c22c3 |
| codex disposition.md | 795cd1555a1e732b91f4861625f68f24d4b037f11b6d958bb7c1815caeeec178 |

Combined verifier: `pwsh -NoProfile -File scripts/verify-reference-harness.ps1` exit 0.
Result: `structural_result=structural-pass`, `deployment_outcome=blocked`, `activation_eligible=false`, `cryptographic_verification=false`.
Roster SHA-256 `2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f`; 6 open activation gates; 8 unresolved consensus gates.

## Blocking questions

None remaining after remediation waves A–I and Codex C1/C2 fixes.

## Major questions

None remaining. Prior council Majors (CBOR schema, BSB22 sentinels, observation binding, Go index presence, telemetry, command provenance, Python hashes, generation publication, control tests, host probe) are dispositioned in the reader reports.

## Minor questions

Codex sandbox TEMP denial (audit environment only). Residual: generation fault-injection durability coverage can deepen in later sprints without changing current fail-closed pointer-last design.

## Dispositions

| Source | Id | Severity | Disposition |
|--------|----|----------|-------------|
| Operator | B-01 | Blocking | Fixed — telemetry opt-out before OpenSpec |
| Operator | M-01..M-05 | Major | Fixed — envelope contract, provenance, hashes, generations, control tests |
| Operator | m-01, m-02 | Minor | Fixed — WhatIf PLANNED; comparison tool versions |
| Proof | M1, M2 | Major | Fixed — CBOR schema + named BSB22 expectations |
| Consensus | M1, M2 | Major | Fixed in 54e8d36; retained |
| Codex | C1, C2 | Major | Fixed after interrupted audit — telemetry order + evidence_digest bytes |

## Verification

- `pwsh -NoProfile -File scripts/setup-reference-harness.ps1 -WhatIf` → PLANNED / ready=false
- Control tests (setup contract, compare, late-failure, telemetry) → PASS
- `cargo test --locked --offline --manifest-path reference/rust/Cargo.toml --all-targets` → PASS
- `go test ./...` and `go vet ./...` in `reference/go` → PASS
- Python observation unit tests → PASS
- `npm --offline run openspec:validate` → 13/13
- `pwsh -NoProfile -File scripts/verify-reference-harness.ps1 -UpdateEvidence` → UPDATED
- `pwsh -NoProfile -File scripts/verify-reference-harness.ps1` → PASS byte-identical
- Fresh proof/consensus/operator reports: Blocking=0 Major=0 each
