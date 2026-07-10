# Sprint 2 Proof-Systems Reader (Closure)

## Snapshot SHA

Closure review against the Sprint 2 remediation tip (post Codex C1/C2 fixes).
Re-verify with `git rev-parse HEAD` on the branch before archive.

Prior council narration was not used as authority; verification commands and
current evidence were.

## Scope

Reviewed Rust/Go structural harnesses, BSB22 parser and named-sentinel tests,
structural CBOR schema fixture, cross-language comparison, combined verifier
evidence claims, and Sprint 2 delta specs for proof/CBOR boundaries.

## Commands And Results

- `git rev-parse HEAD` -> `4968a71a8373c6a38a6b37af6ca89df30627ed32`
- `go test ./internal/bsb22/` -> PASS, including equal-width named-sentinel swaps
- `pwsh -NoProfile -File scripts/verify-reference-harness.ps1` -> PASS
- Committed conformance evidence: `cryptographic_verification=false`,
  `destination_execution_confirmed=false`, `structural_result=structural-pass`,
  `deployment_outcome=blocked`, `activation_eligible=false`,
  roster SHA-256 `2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f`,
  6 open activation gates, 8 unresolved consensus gates

## Prior Major Dispositions

### M1 (CBOR field types) — fixed

- **Evidence:** `reference/fixtures/structural-cbor-schema-v1.json` freezes the
  hex-to-byte-string projection. Rust, Go, and the independent cbor2 path bind
  to that schema. Spec text in
  `openspec/changes/sprint-02-reference-harness-poc/specs/operations-governance/spec.md`
  and reference-harness delta align with the projection.

### M2 (BSB22 equal-width swaps) — fixed

- **File:line:** `reference/go/internal/bsb22/parser.go:22`,
  `reference/go/internal/bsb22/parser.go:98-127`,
  `reference/go/internal/bsb22/parser_test.go` (`TestNamedSentinelVectorDetectsEqualWidthSwaps`)
- **Disposition:** `ParseNamedExpectations` compares every registered field to
  named sentinels and returns `bsb22-field-mismatch` on equal-width swaps.
  Cryptographic verification remains false; gates
  `S01-BLOCK-04/full-decider` and `S01-BLOCK-06/cardano-execution` remain
  unresolved.

## Blocking

None.

## Major

None.

## Minor

None.

## Residual non-claims

Parser-only BSB22 layout checks are not cryptographic verification. Structural
pass is not a chain proof.

Blocking=0 Major=0 Minor=0
