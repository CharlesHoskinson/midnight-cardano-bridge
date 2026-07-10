# Codex closure audit (interrupted; findings extracted from transcript)

Audit id: `closure-sprint2-4968a71`
Model: gpt-5.6-sol
Mode: read-only / approval-policy never / ephemeral CLI
Note: Session was terminated after sandbox TEMP denials blocked Go/Rust execution. Findings below are taken from completed agent_message items in `transcript.jsonl`.

## Blocking

None completed as Blocking in the transcript.

## Major

### C1. OpenSpec version discovery ran before telemetry opt-out

- **File:line (at audit HEAD 4968a71):** `scripts/verify-reference-harness.ps1` `Get-ToolVersions` called before `Set-RunEnvironment`.
- **Violated requirement:** OpenSpec telemetry disabled before every OpenSpec invocation, including version discovery.
- **Consequence:** `openspec --version` could attempt telemetry/config before opt-out.
- **Reproduction:** Static order inspection of verifier main path.
- **Minimum disposition:** Assign `OPENSPEC_TELEMETRY=0` and `DO_NOT_TRACK=1` before any OpenSpec call.

### C2. Schema marks `gate_record.evidence_digest` as CBOR bytes; payload encoded text

- **File:line:** `reference/fixtures/structural-cbor-schema-v1.json` (`evidence_digest: bytes`); Rust/Go gate-record encoding treated digest as text.
- **Violated requirement:** Field/type binding of structural CBOR schema.
- **Consequence:** Cross-language agreement did not prove schema conformance for this field.
- **Reproduction:** Decode `gate_record_set_cbor_hex` and observe Python `str` rather than `bytes` for `evidence_digest`.
- **Minimum disposition:** Encode canonical digests as CBOR major type 2 in Rust, Go, and independent cbor2 check; refresh goldens.

## Minor

### c1. Sandbox could not run Go/Rust/control suites

- TEMP mkdir Access denied under Codex read-only sandbox. Treated as audit-environment limitation, not a product defect.

## Counts

Blocking=0 Major=2 Minor=1 (at interrupted transcript state)

## Verdict

changes-required (against 4968a71). See disposition for fixes applied after this audit.
