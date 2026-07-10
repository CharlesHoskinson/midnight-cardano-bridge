# Sprint 2 Consensus and Trust Review

## Snapshot SHA

`4d985a702fd48a1e7d82ceb9d5304f758544af99`

The worktree was clean at the start of the review. This review used only the current repository snapshot and did not inspect prior council reports or conversation history.

## Scope

Reviewed `protocol/gate-roster-v1.json`, its schema and published CBOR; the Rust and Go structural harnesses, codecs, classifiers, tests, fixtures, and verification scripts; `reference/observers/`, the two captured unsigned observations, and `reference/evidence/`; the Sprint 2 design and four delta specs; `reference/README.md`; and the canonical design passages governing the executable structural slice, deployment-root ownership, continuity migration, dated probes, deterministic outcome, and current-probe limitations.

The review checked closed-schema and producer-DAG enforcement; root, domain, and reset ownership; continuity replay behavior; the exact ordered 14-record classifier and its six `S01-BLOCK-*` plus eight `CONS-*` unresolved base state; immutable unsigned observation provenance; non-inference of SCLS, finality, event inclusion, proof verification, or destination execution; exact gate IDs; and whether any deployment or trust conclusion exceeded the evidence.

No live network request was made.

## Commands and Results

- `git rev-parse HEAD` returned `4d985a702fd48a1e7d82ceb9d5304f758544af99`; initial `git status --short` was empty.
- `npx --no-install openspec list --json` and `npx --no-install openspec status --change "sprint-02-reference-harness-poc" --json` succeeded. The change was `in-progress`, with 5 of 6 tasks complete and the review artifact ready.
- `pwsh -NoProfile -File scripts/verify-reference-harness.ps1` exited 0. It passed tool and Python-lock checks; 8 Rust structural tests; all Go tests and `go vet`; 17 Python observation tests; cross-language vectors; exact roster publication; independent cbor2 bytes and framed preimages; unsigned-observation checks; strict OpenSpec validation (13 passed, 0 failed); input stability; and byte-identical committed evidence. The regenerated base result remained roster SHA-256 `2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f`, 14 gate records, 6 open activation gates, 8 unresolved consensus gates, classifier row 2, `deployment_outcome=blocked`, and `activation_eligible=false`.
- A temporary missing-field mutation removed `source_action_or_event_index` from the base `SourceEventIdentityV1`. The Go CLI exited 0 with `structural-pass` and continuity key `3ccb64f1b29329a37ce0bebfc8b845fefc3d3a5122a53cde728555b053bb2a5f`; the Rust CLI exited 1 with `source-event-schema: missing field source_action_or_event_index`. The temporary files and build directory were outside the repository and removed after the check.
- A read-only Python check reconstructed each committed observation from its embedded capture. Both current `data` objects matched the raw response bytes. Incrementing Midnight's reported block number or Mithril's certificate count without changing any capture field was nevertheless accepted by `validate_observation` for both records.

## Blocking

None.

## Major

1. **Normalized observation data is not bound to the preserved response bytes.**

   - **File:line:** `reference/observers/observe.py:333`, `reference/observers/observe.py:337`, `reference/observers/observe.py:364`, `reference/observers/observe.py:384`, `reference/observers/observe.py:406`; contract at `openspec/changes/sprint-02-reference-harness-poc/specs/conformance-testnet/spec.md:4`.
   - **Failure mode:** `validate_observation` reconstructs and validates only the capture subset, then applies shape and fixed negative-claim checks to `data`. It never re-derives the endpoint-reported head, block number, state root, certificate count, or entity-type names from `response_body_hex`. Because `capture_sha256` covers the capture subset rather than normalized `data`, a record can pair immutable raw bytes with invented normalized values and still pass the observation validator. The default golden comparison notices a changed file, but `-UpdateEvidence` can publish a newly hashed, internally inconsistent observation because the semantic validation still passes.
   - **Evidence:** The focused check first confirmed that both committed records currently match their embedded raw responses. It then changed only `data.endpoint_reported_block_number` in the Midnight record and only `data.certificate_count` in the Mithril record; `validate_observation` accepted both. The regular 17-test observation suite and full verifier also passed, demonstrating that the negative case is currently uncovered. This does not currently infer finality, SCLS, or event inclusion, but it breaks the claimed byte-preserved provenance of the reported endpoint facts.
   - **Required disposition:** Refactor normalization into a pure derivation from an already validated capture and make `validate_observation` compare every derived field, including aggregate digests and the complete `data` object, with that derivation. Alternatively bind the complete normalized record under a separate digest whose preimage includes the capture digest and derived data. Add committed-observation mutations for every derived Midnight and Mithril field and require rejection before evidence update.

2. **The Go closed schema accepts an absent proof-bound event index as index zero.**

   - **File:line:** `reference/go/internal/harness/model.go:39`, `reference/go/internal/harness/model.go:44`, `reference/go/internal/harness/harness.go:298`, `reference/go/internal/harness/harness.go:303`, `reference/go/internal/harness/harness.go:380`; contract at `openspec/changes/sprint-02-reference-harness-poc/specs/reference-harness/spec.md:4` and canonical field definition at `knowledge_base/bridges/midnight-cardano-recursive-bridge.md:1874`.
   - **Failure mode:** `source_action_or_event_index` is a plain `uint64`. Go's JSON decoder initializes a missing member to zero, while `DisallowUnknownFields` only rejects extra members. `parseSourceEvent` validates the other fields but does not check key presence, so an incomplete event identity becomes byte-identical to an explicit index-0 identity and receives the same continuity key. This violates the requirement that both independent commands enforce a closed `SourceEventIdentityV1` and creates a cross-language acceptance disagreement on a replay-critical field.
   - **Evidence:** Removing only `source_action_or_event_index` from the valid base fixture made the Go CLI exit 0 with `structural-pass` and the original continuity key. The Rust CLI rejected the same fixture because its required Serde field was missing. The normal cross-language verifier passes because the committed fixture contains the field, so the missing-field behavior is not covered by current tests.
   - **Required disposition:** Make required-member presence explicit in Go, either by validating the exact key set before typed decoding or by using a presence-aware/custom decoder. Reject absent fields before continuity encoding. Add the same missing-member vector to both language suites and to the cross-language comparison so both commands fail with the same stable schema error.

## Minor

None.

Blocking=0 Major=2 Minor=0
