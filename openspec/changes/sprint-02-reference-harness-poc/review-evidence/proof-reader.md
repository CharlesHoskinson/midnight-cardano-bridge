# Sprint 2 Proof-Systems Reader

## Snapshot SHA

`4d985a702fd48a1e7d82ceb9d5304f758544af99`

The worktree was clean before review and after all read-only test runs. The
snapshot resolved exactly to the requested commit.

## Scope

Reviewed the current snapshot only: `reference/rust`, `reference/go`,
`reference/fixtures`, `scripts/compare-reference-harness.ps1`,
`scripts/verify-reference-harness.ps1`, their relevant script tests, the Sprint
2 proposal/design/specs/tasks, the stable specifications needed to resolve the
BSB22 layout and classifier contract, the authoritative gate-roster
publication, and committed structural/conformance evidence. Prior council
reports and prior conversation history were not used.

The review traced deterministic-CBOR construction, every framed SHA-256
preimage, Rust/Go implementation separation, expected digests, reset and replay
vectors, all 336-byte proof and 672-byte VK offsets, BLS12-381 Fr boundaries and
endianness, exact gate ids, and parser-versus-verifier claim boundaries.

Static inspection confirmed the following conforming behavior:

- Rust and Go have separate encoders, hash implementations, schema validation,
  graph validation, and classifier code; they share no implementation library.
- Hash framing is exactly `u64_be(|domain|) || UTF8(domain) || u64_be(|body|) || body`,
  and deployment-domain bodies are the raw 32-byte root digests.
- Proof offsets are `A 0/48`, `B 48/96`, `C 144/48`, `D 192/96`, and
  `PoK 288/48`. VK offsets are `alpha 0/48`, `beta 48/96`, `gamma 144/96`,
  `delta 240/96`, `IC0 336/48`, `IC1 384/48`, `K2 432/48`, `CK.G 480/96`,
  and `CK.GSigmaNeg 576/96`.
- The Fr modulus is the correct
  `73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001`;
  the parser interprets fixed-width input as little-endian and rejects values
  at or above `r` without reduction.
- The BSB22 command uses exact ids `S01-BLOCK-04/full-decider` and
  `S01-BLOCK-06/cardano-execution`, leaves both `unresolved`, and emits
  `cryptographic_verification=false`.
- Committed evidence is input-hash-bound and makes only structural claims:
  `cryptographic_verification=false`, `destination_execution_confirmed=false`,
  `deployment_outcome=blocked`, and `activation_eligible=false`.

## Commands And Results

- `git rev-parse HEAD` ->
  `4d985a702fd48a1e7d82ceb9d5304f758544af99`; `git status --short` -> empty.
- `openspec status --change sprint-02-reference-harness-poc --json` -> the global
  `openspec` command was not on `PATH`. The repository-local OpenSpec binary was
  subsequently exercised successfully by the combined verifier.
- `pwsh -NoProfile -File scripts/verify-reference-harness.ps1` -> PASS in 37.7s.
  Rust ran 8 integration tests; all Go packages, including BSB22, passed;
  `go vet`, cross-language comparison, the independent `cbor2` reproduction,
  roster checks, strict OpenSpec validation (13/13), input-stability checks, and
  byte-identical evidence comparison all passed.
- `pwsh -NoProfile -File scripts/tests/compare-reference-harness.Tests.ps1` ->
  PASS; it produced a temporary candidate and did not change committed evidence.
- `pwsh -NoProfile -File scripts/tests/verify-reference-harness.integration.ps1`
  -> `late-failure-preserves-committed-evidence` PASS.
- Independent text-preserving `cbor2` encoding of the JSON fixture produced a
  1,381-byte root body with digest
  `9261286843ded05e19c562b4d404788130d99cf780240355d49897eda175d734`
  and a 418-byte event body with digest
  `4e205f40823fa74f0f9703a2eead3cbd0df7156dd2abf88a9f43ab38f95ae09b`;
  these differ from the committed byte-string projection and demonstrate the
  normative type ambiguity in Major M1.
- A direct `mcb-go bsb22-check` comparison between a named-sentinel proof and the
  same proof with complete 48-byte `A` and `C` blocks swapped returned success
  for both and byte-identical JSON reports. Both reports remained safely
  non-cryptographic and kept the exact two gates unresolved, but the required
  offset mutation was not detected (Major M2).

## Blocking

None.

## Major

### M1. The structural CBOR field types are not normatively specified and conflict with the diagnostic-profile text

- **File:line:**
  `openspec/changes/sprint-02-reference-harness-poc/specs/operations-governance/spec.md:10`,
  `openspec/changes/sprint-02-reference-harness-poc/specs/operations-governance/spec.md:12`,
  `reference/rust/src/harness.rs:461`,
  `reference/go/internal/harness/harness.go:318`, and
  `scripts/verify-reference-harness.ps1:301`.
- **Failure mode:** The Sprint 2 contract says digest-like fixture members remain
  lowercase hexadecimal text and are not production typed byte strings, but
  Rust, Go, and the nominally independent Python check all apply an undocumented
  field-by-field `hex -> CBOR byte string` projection. An independent reader
  following the stated text representation obtains different canonical bodies,
  preimages, and digests. The agreement therefore proves three implementations
  of one in-repository interpretation, not an unambiguous OpenSpec wire contract.
- **Evidence:** Rust's `digest_value` constructs `CborValue::Bytes`; Go's
  `rootSetCBORValue` uses `mustDecodeHex`; the verifier's `typed_root` and
  `typed_event` repeat the same conversion. Committed
  `reference/evidence/structural-report-v1.json:11` contains `5820` byte-string
  markers for digest fields. Preserving the fixture strings instead yields the
  independently computed 1,381/418-byte bodies and alternate digests recorded
  above, rather than the committed 916/322-byte bodies and their hashes.
- **Required disposition:** Freeze a field-by-field structural CBOR schema in the
  Sprint 2 spec, including the exact CBOR major type for every root-set, event,
  and gate-record member, and resolve the text-versus-byte-string contradiction.
  Then update Rust, Go, the third checker, fixture goldens, and committed evidence
  to that approved schema. If byte strings are intended, the spec must explicitly
  authorize this diagnostic hex-to-bytes projection rather than imply the
  opposite.

### M2. The required equal-width BSB22 offset-mutation vector is absent, and the command accepts swaps indistinguishably

- **File:line:**
  `openspec/changes/sprint-02-reference-harness-poc/specs/groth16-proof-path/spec.md:15`,
  `reference/go/internal/bsb22/parser.go:67`,
  `reference/go/internal/bsb22/parser_test.go:80`, and
  `reference/go/cmd/mcb-go/main.go:55`.
- **Failure mode:** A complete equal-width field swap is accepted as another
  exact-length blob. The current test checks each parsed field against the bytes
  currently present at the same offset, so swapping named input blocks changes
  both sides of that assertion and still passes. The CLI emits only static
  layout metadata, making the base and swapped reports identical. This does not
  satisfy the required byte-sentinel detection scenario.
- **Evidence:** `Parse` performs only length and scalar-range checks before fixed
  slicing. `TestEveryRegisteredFieldHasExactCompleteSliceAndMetadata` has no
  named expected sentinel per field and performs no swap mutation. The direct
  `A <-> C` mutation run returned exit 0 for both inputs with
  `reports_equal=true`; the same gap applies to the other equal-width proof and
  VK families.
- **Required disposition:** Add a versioned named-sentinel proof/VK vector with
  expected bytes or hashes for every named field, mutate every complete field
  into each relevant equal-width offset, and require a stable mismatch result.
  Run that validator from the combined verifier and bind its results in evidence;
  keep the result explicitly parser-only and non-cryptographic.

## Minor

### m1. Committed conformance evidence does not bind execution of the late-failure regression

- **File:line:**
  `openspec/changes/sprint-02-reference-harness-poc/specs/reference-harness/spec.md:45`,
  `scripts/verify-reference-harness.ps1:774`,
  `scripts/tests/verify-reference-harness.integration.ps1:171`, and
  `reference/evidence/conformance-report-v1.json:50`.
- **Failure mode:** The default verifier and its recorded command list omit the
  only regression that injects a failure after cross-language comparison and
  checks label suppression, cleanup, and byte-identical committed evidence. A
  regression in that required failure path would not invalidate the committed
  conformance report.
- **Evidence:** The standalone integration script contains the required
  assertions and passed when run during this review, but neither the verifier's
  command list nor the committed report records its execution.
- **Required disposition:** Invoke the late-failure integration regression from
  the combined verifier before evidence publication and add it to `commands` and
  `verified_components`, or explicitly narrow the committed evidence claim so it
  does not purport to cover that failure-path scenario.

Blocking=0 Major=2 Minor=1
