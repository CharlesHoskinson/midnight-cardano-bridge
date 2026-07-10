# Reference Harness PoC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build independently testable Rust and Go bridge-contract harnesses plus Scrapling observation adapters while keeping every unproved chain and execution gate open.

**Architecture:** Rust and Go independently implement the bounded deterministic-CBOR and structural hash contracts against shared JSON fixtures. Go also owns a parser-only BSB22 byte-layout check. Python owns all public HTTP access through Scrapling and normalizes responses into explicitly unsigned observation records. PowerShell composes the test suites and compares parsed reports.

**Tech Stack:** Rust 1.90 (`serde`, `serde_json`, `sha2`, `hex`), Go 1.25.7 standard library, Python 3.10+ with Scrapling 0.4.10 and `unittest`, PowerShell 7, OpenSpec 1.5.0.

## Global Constraints

- Use only `mcb.structural-lab.sha256-cbor.v1`; every structural result carries `activation_eligible=false`.
- Public endpoint requests use Scrapling. Rust and Go perform no network requests.
- Keep all six `S01-BLOCK-*` gates and all source-dependent `CONS-*` evidence open.
- Never emit `live-pass` or `degraded-lab`; structural success still has deployment outcome `blocked`.
- Missing 42/52 predicate rows may not be invented.
- Follow red-green-refactor for each implementation task.

---

### Task 1: Shared fixtures and Rust structural harness

**Files:**
- Create: `reference/fixtures/structural-v1.json`
- Create: `reference/fixtures/invalid-post-domain-v1.json`
- Create: `reference/rust/Cargo.toml`
- Create: `reference/rust/src/cbor.rs`
- Create: `reference/rust/src/model.rs`
- Create: `reference/rust/src/harness.rs`
- Create: `reference/rust/src/lib.rs`
- Create: `reference/rust/src/main.rs`
- Create: `reference/rust/tests/structural.rs`

**Interfaces:**
- Consumes: `protocol/gate-roster-v1.json`, `protocol/gate-roster-v1.cbor.hex`, shared fixture JSON.
- Produces: `mcb-rust run <fixture>` emitting `StructuralReportV1` JSON with `roster_sha256`, `root_set_digest`, `deployment_domain`, `continuity_key`, `structural_result`, `deployment_outcome`, and `activation_eligible`.

- [ ] **Step 1: Add bounded fixture values**

Use one domain-neutral root object with `bridge_program_id`, `fresh_deployment_instance_id`, ordered source identity/fingerprint pairs, checkpoint manifest digests, semantic/artifact roots, ABI template digests, deployment recipes, and policy template digests. Add one `SourceEventIdentityV1` with no domain-bound field. The invalid fixture adds `deployment_domain` inside the root object.

- [ ] **Step 2: Write failing Rust tests**

```rust
#[test]
fn published_roster_reencodes_byte_exactly() {
    let report = mcb_harness::run_fixture(fixture("structural-v1.json")).unwrap();
    assert_eq!(report.roster_sha256, "2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f");
}

#[test]
fn post_domain_root_field_is_rejected() {
    let err = mcb_harness::run_fixture(fixture("invalid-post-domain-v1.json")).unwrap_err();
    assert_eq!(err.code(), "forbidden-post-domain-field");
}

#[test]
fn structural_profile_never_activates() {
    let report = mcb_harness::run_fixture(fixture("structural-v1.json")).unwrap();
    assert!(!report.activation_eligible);
    assert_eq!(report.deployment_outcome, "blocked");
}
```

- [ ] **Step 3: Run the Rust tests and observe RED**

Run: `cargo test --manifest-path reference/rust/Cargo.toml --all-targets`

Expected: compilation fails because `mcb_harness::run_fixture` does not exist.

- [ ] **Step 4: Implement the minimal deterministic encoder and harness**

Implement CBOR major types 0, 3, 4, and 5. Sort map keys by encoded length and then bytewise order. Reject booleans, null, negative/floating numbers, and numbers above the safe unsigned fixture bound. Hash with:

```rust
fn digest(domain: &str, body: &[u8]) -> [u8; 32] {
    let mut h = sha2::Sha256::new();
    h.update(domain.as_bytes());
    h.update(body);
    h.finalize().into()
}
```

Derive root and domain with fixed strings `mcb/deployment-root-set/v1` and `mcb/deployment-domain/v1`. Walk every root-set JSON field recursively and reject the forbidden set from the stable operations spec.

- [ ] **Step 5: Run Rust tests and observe GREEN**

Run: `cargo test --manifest-path reference/rust/Cargo.toml --all-targets`

Expected: all Rust unit and integration tests pass.

- [ ] **Step 6: Commit the Rust slice**

```powershell
git add reference/fixtures reference/rust
git commit -m "Add Rust structural bridge harness"
```

### Task 2: Independent Go harness and BSB22 parser

**Files:**
- Create: `reference/go/go.mod`
- Create: `reference/go/internal/canon/cbor.go`
- Create: `reference/go/internal/harness/harness.go`
- Create: `reference/go/internal/harness/harness_test.go`
- Create: `reference/go/internal/bsb22/parser.go`
- Create: `reference/go/internal/bsb22/parser_test.go`
- Create: `reference/go/cmd/mcb-go/main.go`

**Interfaces:**
- Consumes: the same fixture and roster files as Rust.
- Produces: `mcb-go run <fixture>` with the same normalized report; `mcb-go bsb22-check <proof-hex> <vk-hex> <pub-hex>` with parser-only results.

- [ ] **Step 1: Write failing Go structural tests**

```go
func TestStructuralReportMatchesGolden(t *testing.T) {
    report, err := harness.RunFixture("../../fixtures/structural-v1.json")
    if err != nil { t.Fatal(err) }
    if report.DeploymentOutcome != "blocked" || report.ActivationEligible {
        t.Fatalf("unsafe report: %+v", report)
    }
}
```

- [ ] **Step 2: Write failing BSB22 parser tests**

```go
func TestRejectsScalarAtModulus(t *testing.T) {
    pub := FrModulusLittleEndian()
    if _, err := Parse(make([]byte, 336), make([]byte, 672), pub); !errors.Is(err, ErrScalarRange) {
        t.Fatalf("expected scalar range error, got %v", err)
    }
}

func TestVKOffsets(t *testing.T) {
    parsed, err := Parse(make([]byte, 336), make([]byte, 672), make([]byte, 32))
    if err != nil { t.Fatal(err) }
    if len(parsed.VK.CKG) != 96 || len(parsed.VK.CKGSigmaNeg) != 96 { t.Fatal("bad offsets") }
}
```

- [ ] **Step 3: Run Go tests and observe RED**

Run from `reference/go`: `go test ./...`

Expected: compilation fails because the harness and BSB22 APIs do not exist.

- [ ] **Step 4: Implement independent CBOR, hashes, and parser**

Use only the Go standard library. Compare the little-endian scalar by reversing a copy into a `big.Int` and requiring `value.Cmp(frModulus) < 0`. Slice proof and VK fields only after exact-length checks. Return a result containing `cryptographic_verification=false` and both proof gates unresolved.

- [ ] **Step 5: Run Go tests and observe GREEN**

Run: `go test ./...`

Expected: all Go tests pass.

- [ ] **Step 6: Commit the Go slice**

```powershell
git add reference/go
git commit -m "Add Go bridge harness and BSB22 parser"
```

### Task 3: Cross-language report comparison

**Files:**
- Create: `scripts/compare-reference-harness.ps1`
- Modify: `reference/fixtures/structural-v1.json`
- Test: Rust and Go integration tests from Tasks 1 and 2.

**Interfaces:**
- Consumes: both CLIs and the structural fixture.
- Produces: exit-zero comparison plus normalized `reference/evidence/structural-report-v1.json`.

- [ ] **Step 1: Add a failing digest comparison**

Have the script parse both JSON reports and compare every named field. Temporarily require the fixture's empty `expected` object to contain all report fields so the first run fails with `missing expected.root_set_digest`.

- [ ] **Step 2: Run comparison and observe RED**

Run: `powershell -NoProfile -File scripts/compare-reference-harness.ps1`

Expected: nonzero with a missing or mismatched expected digest.

- [ ] **Step 3: Record independently reproduced expectations**

Populate the fixture only after Rust and Go agree. The script writes a sorted diagnostic JSON report, marks `structural_result=structural-pass`, and hard-codes no computed digest.

- [ ] **Step 4: Run comparison and observe GREEN**

Run: `powershell -NoProfile -File scripts/compare-reference-harness.ps1`

Expected: both implementations and fixture expectations agree.

- [ ] **Step 5: Commit fixtures and comparison**

```powershell
git add reference/fixtures reference/evidence scripts/compare-reference-harness.ps1
git commit -m "Add cross-language bridge vectors"
```

### Task 4: Scrapling observation adapters

**Files:**
- Create: `reference/observers/observe.py`
- Create: `reference/observers/tests/test_observe.py`
- Create: `reference/observers/fixtures/midnight-finalized-v1.json`
- Create: `reference/observers/fixtures/mithril-certificates-v1.json`

**Interfaces:**
- Consumes: raw JSON responses or Scrapling-fetched public endpoint responses.
- Produces: `UnsignedObservationV1` JSON with request/response hashes and fixed trust label.

- [ ] **Step 1: Write failing `unittest` cases**

```python
def test_normalized_observation_is_unsigned(self):
    record = normalize_midnight(self.raw_midnight, self.meta)
    self.assertEqual(record["trust"], "unsigned-observation")

def test_authenticated_relabel_is_rejected(self):
    record = normalize_mithril(self.raw_mithril, self.meta)
    record["trust"] = "authenticated"
    with self.assertRaisesRegex(ValueError, "trust-label"):
        validate_observation(record)
```

- [ ] **Step 2: Run Python tests and observe RED**

Run: `.\.venv-scrapling\Scripts\python.exe -m unittest discover -s reference/observers/tests -v`

Expected: import failure because `observe.py` does not exist.

- [ ] **Step 3: Implement normalization and Scrapling transport**

Use `Fetcher.get` for Mithril and `Fetcher.post` for Midnight JSON-RPC. Hash exact request and response bytes with SHA-256. Accept `--fixture` for offline tests and `--live` for explicit endpoint access. Never infer finality from the transport response.

- [ ] **Step 4: Run Python tests and observe GREEN**

Run the same `unittest` command.

Expected: all observation tests pass without network access.

- [ ] **Step 5: Exercise live reads through Scrapling**

Run the observer once for Midnight Preview and once for the official Mithril Preview aggregator. Store redacted unsigned reports under `reference/evidence/observations/`. A transport failure remains recorded and does not fail offline conformance.

- [ ] **Step 6: Commit adapters and captured evidence**

```powershell
git add reference/observers reference/evidence/observations
git commit -m "Add Scrapling bridge observations"
```

### Task 5: Combined verifier and operator documentation

**Files:**
- Create: `scripts/verify-reference-harness.ps1`
- Create: `reference/README.md`
- Modify: `README.md`
- Modify: `EXAMINATION-CHECKLIST.md`
- Modify: `openspec/changes/sprint-02-reference-harness-poc/tasks.md`

**Interfaces:**
- Consumes: every test suite and comparison command.
- Produces: one structural report and reproducible developer commands.

- [ ] **Step 1: Write the verifier with an intentionally missing evidence assertion**

Require the structural report file before Task 3 creates it. Run the verifier and confirm it fails at `structural evidence missing`.

- [ ] **Step 2: Implement ordered verification**

Run Rust, Go, Python, cross-language comparison, independent roster reproduction, `npm run openspec:validate`, `git diff --check`, and a gate-state assertion. Stop on nonzero. Emit:

```json
{"structural_result":"structural-pass","deployment_outcome":"blocked","activation_eligible":false}
```

- [ ] **Step 3: Document exact commands and limitations**

State that the BSB22 tool is a parser, endpoint records are unsigned, the domain profile is structural, Compact/proof server are unavailable on this host, and all six blockers remain open.

- [ ] **Step 4: Run the combined verifier**

Run: `powershell -NoProfile -File scripts/verify-reference-harness.ps1`

Expected: all component checks pass; structural result passes; deployment outcome remains blocked.

- [ ] **Step 5: Commit integration and docs**

```powershell
git add scripts/verify-reference-harness.ps1 reference/README.md README.md EXAMINATION-CHECKLIST.md openspec/changes/sprint-02-reference-harness-poc/tasks.md
git commit -m "Integrate reference harness verification"
```

### Task 6: Independent review and closure

**Files:**
- Create: `openspec/changes/sprint-02-reference-harness-poc/review.md`
- Modify: implementation files only when a finding requires a fix.

**Interfaces:**
- Consumes: complete current implementation, reports, and OpenSpec artifacts.
- Produces: proof, consensus, and operator reader hashes with zero blocking and zero unresolved major findings.

- [ ] **Step 1: Run three current-document/code-only readers**

Proof reviews byte/hash/scalar and non-claim boundaries. Consensus reviews trust labels, root/domain/reset, and gate status. Operator reviews reproducibility, failure behavior, and live/offline separation.

- [ ] **Step 2: Fix findings with TDD**

For each behavior change, add a failing test reproducing the finding, run it red, implement the smallest fix, and rerun all component tests green.

- [ ] **Step 3: Record closure and run final verification**

Run the combined verifier, `npm run openspec:validate`, and `git diff --check`. Record reader output SHA-256 values and exact zero counts in `review.md`.

- [ ] **Step 4: Commit reviewed change**

```powershell
git add openspec/changes/sprint-02-reference-harness-poc reference scripts README.md EXAMINATION-CHECKLIST.md
git commit -m "Complete reference harness proof of concept"
```
