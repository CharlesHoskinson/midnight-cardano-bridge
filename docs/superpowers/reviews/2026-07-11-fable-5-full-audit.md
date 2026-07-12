# Fable 5 Full Audit — Public Testnet Proof-Bridge Planning Work

## 1. Audit Metadata

| Field | Value |
| --- | --- |
| Auditor | Claude Fable 5 (`claude-fable-5`), independent proof-bridge program auditor |
| Audit contract | `docs/fable-5-audit.xml` v1.0, prepared 2026-07-11 |
| Run id | `20260712T005421Z-9f5445659d19` |
| Source repository | `C:\Users\charl\midnight-cardano-bridge` |
| Baseline commit (exclusive) | `78bd432af06c9ef68e006ab2147da68fce29af6d` |
| Baseline tree | `485f88b947ce956b0f8d592450369cc5e8fed923` |
| Target commit (inclusive) | `9f5445659d1927510c6c29f0285a405ecda30767` |
| Target tree | `9cdfc7a1568fb57a42e3545720c7abe0c57d2521` |
| Commits in range | 2 (`3db35fa9` "Rebaseline public testnet bridge program", `9f544565` "Plan the public testnet bridge program") |
| Diff statistics | 34 files changed, 4797 insertions, 316 deletions — matches the contract's expected counts exactly |
| Isolated clone | `C:\Users\charl\.fable-audit\midnight-cardano-bridge\20260712T005421Z-9f5445659d19\repo`, detached at target |
| Method | 8-stage pipeline per contract; 4 read-only subagents on disjoint domains, every retained finding re-verified by the lead auditor against committed bytes |

All file paths below are commit-relative; all line numbers are 1-based in the target-commit blob (not the CRLF working-tree rendering).

## 2. Executive Verdict

The pinned range adds a 14-sprint / 100-package public-testnet program plan, a Sprint 0 control-plane plan, a rebaseline design, a program review, and a receipt-backed program wiki with an append-only knowledge graph. The mechanical substrate is in unusually good shape: the graph's 273 events parse and validate against its own schema with zero defects, the immutable V1 prefix matches its pinned blob hash byte-for-byte, all 273 `source_sha256` values match committed git blob bytes, the materialized node/edge views reproduce exactly from the event stream, the 25-section design invariant holds, the 42+52=94 predicate gate is honestly blocked, the 6+8 gate roster recomputes correctly, and every external source receipt I could retrieve reproduces its recorded hash exactly.

Verdict by contract dimension:

1. **Document coherence — defective in three places, otherwise strong.** The canonical design contradicts itself on the PoC bootstrap root of trust (F5-MAJOR-002), the master plan and Sprint 0 plan disagree on re-entry rules that `ProgramPlanV1` must encode exactly (F5-MAJOR-003), and the repo's top-level README/checklist still describe the superseded 11-sprint program and abolished `degraded-lab` outcome tier (F5-MAJOR-008).
2. **Program-control closure safety — structurally sound, evidentially weak at the review gate.** The dependency graph is acyclic with a valid execution order (206 edges recounted), snapshots and closure envelopes are well specified, but sprint closure ultimately rests on 0/0/0 counts from self-authored, self-hosted model readers that the implementer iterates until zero (F5-MAJOR-004), the shipped plan review misattributes its own baseline (F5-MAJOR-001), and three Sprint 0 packages are implausibly large for their single-package closure granularity (F5-MAJOR-005).
3. **Reference-harness structural status — structural evidence reproduces; conformance evidence is checkout-dependent.** In the isolated clone the structural report reproduced byte-identically, but the default verifier run failed its `evidence-publication` check because golden conformance hashes bind platform-specific working-tree bytes with no repo-level line-ending pin (F5-MAJOR-007). The README's "clean checkout → structural-pass" claim fails on a default Windows Git installation.
4. **Cryptographic implementation status — nothing claimed, correctly.** No changed document claims proof generation, cryptographic verification, on-chain verification, or settlement. Parser acceptance, structural conformance, and observation evidence are consistently separated. The 42+52 predicate catalogs, the full Halo2/KZG decider, and both destination executions remain open and are stated as open.
5. **Public-testnet deployment readiness — blocked, and accurately reported as blocked.** All six `S01-BLOCK-*` and eight `CONS-*` gates remain open. No deployment-state language in the changed files exceeds the evidence; the one slip is a wiki page's present-tense "is implemented" for unbuilt machinery (F5-NOTE-006).

No finding invalidates the safety model or the ability to audit the plan; there are no BLOCKER findings. The eight MAJOR findings should be corrected before `PBT-S00-W02` freezes the 100-package plan, because several of them (bootstrap mode, re-entry rules, package splits) become much more expensive to fix after the plan digest is frozen.

## 3. Severity Summary

| Severity | Count | Ids |
| --- | --- | --- |
| BLOCKER | 0 | — |
| MAJOR | 8 | F5-MAJOR-001 … F5-MAJOR-008 |
| MINOR | 14 | F5-MINOR-001 … F5-MINOR-014 |
| NOTE | 10 | F5-NOTE-001 … F5-NOTE-010 |

## 4. Scope Coverage

All 34 changed files were audited. Coverage matrix (role → audit stages → findings):

| # | Path | Role | Stages | Findings |
| --- | --- | --- | --- | --- |
| 1 | `docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md` | Sprint 0 implementation plan (12 packages) | A,B,H | MAJOR-003/-004/-005, MINOR-008/-010/-011, NOTE-007 |
| 2 | `docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md` | Master 14-sprint / 100-package register | A,B,C,D,H | MAJOR-003/-006, MINOR-011 |
| 3 | `docs/superpowers/reviews/2026-07-10-public-testnet-proof-bridge-implementation-plan-review.md` | Council review record | A,B,H | MAJOR-001 |
| 4 | `docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md` | Program rebaseline design | A,B,C,D,H | MAJOR-006, MINOR-009 |
| 5 | `knowledge_base/bridges/midnight-cardano-recursive-bridge.md` | Canonical 25-section design (modified) | A,C,H | MAJOR-002, MINOR-002, NOTE-005/-008 |
| 6 | `knowledge_base/midnight/zero-knowledge-proofs.md` | Concept page (modified) | A,C | NOTE-004 |
| 7 | `knowledge_base/program-wiki/AGENTS.md` | Wiki/graph maintenance rules | A,E | clean; rules used as audit oracle |
| 8 | `knowledge_base/program-wiki/README.md` | Wiki purpose statement | A,E | clean |
| 9 | `knowledge_base/program-wiki/graph/edges.json` | Materialized edge view (136) | A,E | clean (reproduces from events) |
| 10 | `knowledge_base/program-wiki/graph/events.jsonl` | Append-only event stream (273) | A,E | MINOR-013 (no contradict events) |
| 11 | `knowledge_base/program-wiki/graph/nodes.json` | Materialized node view (134) | A,E | clean (reproduces from events) |
| 12 | `knowledge_base/program-wiki/graph/schema.json` | Event schema V1/V2 | A,E | clean (all 273 events conform) |
| 13 | `knowledge_base/program-wiki/raw/design-sessions/2026-07-10-graph-event-v2-transition.md` | V1→V2 transition record | A,E | clean (all claims verified against odb) |
| 14 | `knowledge_base/program-wiki/raw/design-sessions/2026-07-10-implementation-planning.md` | Planning session record | A,B,E | clean |
| 15 | `knowledge_base/program-wiki/raw/design-sessions/2026-07-10-program-rebaseline.md` | Rebaseline session record | A,B,E | clean |
| 16 | `knowledge_base/program-wiki/raw/source-receipts/gnark-bsb22-mpc-2026-07-10.md` | External source receipt | A,D,G | NOTE-001; hashes verified live |
| 17 | `knowledge_base/program-wiki/raw/source-receipts/karpathy-llm-wiki-2026-07-10.md` | External source receipt | A,E,G | clean; hash verified live |
| 18 | `knowledge_base/program-wiki/raw/source-receipts/proof-zk-recovery-mpc-2026-07-10.md` | External source receipt | A,D,G | MINOR-007; objects verified locally |
| 19 | `knowledge_base/program-wiki/reports/README.md` | Reports placeholder | A,E | clean |
| 20 | `knowledge_base/program-wiki/wiki/components/mpc-ceremony.md` | Ceremony component page | A,D,E | MINOR-012, NOTE-002 |
| 21 | `knowledge_base/program-wiki/wiki/components/program-control-plane.md` | Control-plane component page | A,B,E | NOTE-006 |
| 22 | `knowledge_base/program-wiki/wiki/contradictions.md` | Active contradiction register | A,E | MAJOR-008 (schedule conflict omitted), MINOR-013 |
| 23 | `knowledge_base/program-wiki/wiki/decisions/execution-model.md` | Decision page | A,B,E | clean |
| 24 | `knowledge_base/program-wiki/wiki/decisions/predicate-coverage.md` | Decision page | A,C,E | clean |
| 25 | `knowledge_base/program-wiki/wiki/decisions/program-outcome.md` | Decision page | A,B,E | clean |
| 26 | `knowledge_base/program-wiki/wiki/index.md` | Wiki index | A,E | clean (all links resolve) |
| 27 | `knowledge_base/program-wiki/wiki/log.md` | Chronological log | A,E | MINOR-014 (07-11 entries) |
| 28 | `knowledge_base/program-wiki/wiki/open-questions.md` | Open questions | A,D,E | MINOR-014, NOTE-009 |
| 29 | `knowledge_base/program-wiki/wiki/overview.md` | Program overview | A,E | clean |
| 30 | `knowledge_base/program-wiki/wiki/risks/public-chain-gates.md` | Risk register | A,E | clean |
| 31 | `knowledge_base/program-wiki/wiki/sprints/overview.md` | Sprint table | A,B,E | clean (counts reconcile with graph and plan) |
| 32 | `knowledge_base/proof-claims/predicate-catalog-status.md` | 94-record gate status (modified) | A,C | clean; counts recomputed |
| 33 | `knowledge_base/proof-systems/groth16-trusted-setup-ceremony.md` | Ceremony concept page (modified) | A,D,G | MINOR-003/-004/-005/-006, NOTE-003 |
| 34 | `knowledge_base/proof-systems/proof-systems-fundamentals.md` | Proof-system concept page (modified) | A,C | MINOR-001 |

Repository-wide dependencies audited because the changed files rely on them: `protocol/gate-roster-v1.json` (gate totals, canonical hash), `README.md` / `EXAMINATION-CHECKLIST.md` / `RESEARCH-PLAN.md` (program-state claims, MAJOR-008), `scripts/verify-reference-harness.ps1` + `reference/evidence/*` (closure evidence machinery, MAJOR-007), `openspec/` (strict validation), and the prior program design `docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md`. Unrelated historical code was not expanded into.

## 5. Findings

### F5-MAJOR-001 — Shipped plan review binds a baseline commit that cannot contain what it reviewed

- **Path:** `docs/superpowers/reviews/2026-07-10-public-testnet-proof-bridge-implementation-plan-review.md:5` (also lines 53–60)
- **Evidence:** Line 5 states `Source baseline: 3db35fa9a7e7257359f5def4bb216c60356643b8`. Verified with git: at `3db35fa9` neither reviewed plan exists (`docs/superpowers/plans/` contains only three 2026-07-09/10 legacy plans), `graph/events.jsonl` has 29 events (the review claims 273 events, 134 nodes, 136 edges), and the rebaseline design differs from its `3db35fa9` version by +235/−48 lines. All reviewed content and the review itself land together in the target commit.
- **Impact:** The program's only review artifact misattributes its provenance. Its mechanical evidence is reproducible only at the commit that also introduces the review, so the approval record cannot be distinguished from the content it approves. This violates the program's own rule (S00 plan line 25: a review binds a complete `ProgramSnapshotV1`, not a bare commit) and would be baked into `program/baselines/pbt-s00-start.json` by W01.
- **Correction:** Re-issue the review bound to the exact reviewed tree/blob digests (list per-document git blob ids), committed after the reviewed content — or explicitly relabel it a pre-control-plane bootstrap review whose baseline is the planning commit itself.
- **Affected packages:** `PBT-S00-W01` (baseline manifest), `PBT-S00-W10` (review machinery precedent).
- **Verification criterion:** For every document the review names, `git cat-file -e <stated-baseline>:<path>` succeeds and the blob digest matches the digest recorded in the review.
- **Confidence:** High. Uncertainty: none on the mechanical facts; the review may have been run against an uncommitted working tree, which the correction should make explicit.

### F5-MAJOR-002 — Canonical design contradicts itself on the PoC bootstrap root of trust

- **Path:** `knowledge_base/bridges/midnight-cardano-recursive-bridge.md:41` vs `:634–636`
- **Evidence:** Line 41 (changed in this range): "Bootstrap mode for the proof of concept | Exact public genesis, official chain rules, and independently verified official finality roots". Line 634 (unchanged): "The proof of concept uses approved checkpoint manifests. This is a weak-subjectivity choice." The rebaseline design (`docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md:317–319`) sides with line 41: "A project approval set cannot create the live source root. A checkpoint may accelerate verification only when the checkpoint and all retained state are proved from the official roots."
- **Impact:** The same document pins two different minimum roots of trust for the same proof of concept. Section 11 (line 1313–1314, "the selected genesis or certificate checkpoint profile in section 6") inherits the ambiguity. Bootstrap mode is the top of the trust chain; an implementer of `PBT-S02` cannot know which root to build.
- **Correction:** Rewrite section 6's opening to state the rebaselined bootstrap (exact public genesis + official finality roots); restrict `CertificateCheckpointRuleProfileV1` (lines 789–830) to the acceleration role the rebaseline permits, or mark checkpoint mode lab-only and non-qualifying for the public classifier.
- **Affected packages:** `PBT-S02-*` (bootstrap/feasibility), downstream `PBT-S05`/`PBT-S06` anchor packages.
- **Verification criterion:** Grep of section 6 contains no unqualified statement that the PoC "uses approved checkpoint manifests"; sections 1, 6, and 11 name the identical bootstrap mode.
- **Confidence:** High. Uncertainty: none; both statements are present tense and normative at the same commit.

### F5-MAJOR-003 — Master plan and Sprint 0 plan state incompatible re-entry rules

- **Path:** `docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md:28` vs `docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md:841`
- **Evidence:** The master constraint reads "**Only** endpoint-only drift or a fingerprint transition already authorized by the frozen runtime policy may re-enter at `PBT-S11` or the affected `PBT-S12` package." The S00 plan's invalidation contract, which Step 2 says must be asserted "exactly", adds a third S11 re-entry category: "deployed-copy or ABI-observation drift under unchanged authorized bytes repeats `PBT-S11` and public execution" — and then restates the exclusive "Only …" sentence in the same paragraph, contradicting itself as well.
- **Impact:** `PBT-S00-W02` requires exact agreement between the register and plan constraints, so `ProgramPlanV1` cannot encode both documents; whichever is implemented, one document's closure-safety rule is silently violated. Re-entry rules are the scoped-invalidation backbone of the whole control plane.
- **Correction:** Add "deployed-copy or ABI-observation drift under unchanged authorized bytes → `PBT-S11`" to the master plan line 28 and the rebaseline's re-entry paragraph (spec lines 530–531), and rephrase the "Only …" clause in both places to include the third category — or delete the category from S00 plan Task 7 Step 2.
- **Affected packages:** `PBT-S00-W02`, `PBT-S00-W07`, `PBT-S11-*`.
- **Verification criterion:** A single enumerated re-entry table appears identically (or by reference) in master plan, rebaseline, and S00 plan; the plan-validation contract test that asserts these boundaries passes against all three texts.
- **Confidence:** High. Uncertainty: whether the author intends "deployed-copy drift" as a species of "endpoint-only drift"; the texts as written do not support that reading.

### F5-MAJOR-004 — Every sprint closure before public receipts rests on self-authored, iterated-to-zero model output

- **Path:** `docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md:1084–1086` (also 1292); register rows "readers report 0/0/0" (`docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md:255, 268, 281, 295, 310, 351, 387–388`)
- **Evidence:** Closure requires exact Blocking/Major/Minor counts of zero from Codex (`gpt-5.6-sol`) and persona readers whose profiles, prompts, templates, and scopes are authored by the same program (W10), executed on the same host, under a controller whose signing key is self-generated (W03); the plan instructs the implementer to iterate ("create a new review candidate and snapshot, and repeat every affected reader") until counts reach zero. The only external anchor is the pushed remote SHA. The rebaseline itself reopened the prior sprint for exactly this evidence class (spec lines 58–62: saved Codex audit `changes-required`, council reports not binding, one synthesized command record).
- **Impact:** The closure evidence class is non-falsifiable by any party outside the operator's machine. The new design fixes binding and synthesis defects but keeps 0/0/0 model counts as the sprint-closing criterion, i.e., a package can close on evidence the closing party fully controls and regenerates until it passes.
- **Correction:** Either downgrade reader councils to internal quality controls (closure resting on the re-runnable contract suites plus externally confirmable receipts), or require an externally pinned reviewer configuration and out-of-host attestation (second operator or CI identity) for the sprint-closing review round.
- **Affected packages:** all sprint closures; concretely `PBT-S00-W10`, `PBT-S00-W12`, and every `readers report 0/0/0` register row.
- **Verification criterion:** The closure contract names at least one closure input that the implementing host cannot regenerate (external attestation, CI-identity run, or second-operator signature), or the plan text explicitly reclassifies reader output as non-closure evidence.
- **Confidence:** High on the mechanism; medium on severity judgment — process isolation, immutable snapshots, and remote publication are real mitigations, but they authenticate rather than independently evaluate.

### F5-MAJOR-005 — PBT-S00-W03, W05, and W12 are not plausibly single-sprint, single-agent packages

- **Path:** `docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md:297–345` (W03), `:560–655` (W05), `:1191–1237` (W12)
- **Evidence:** W03 alone comprises 16 JSON schemas, a native Rust Windows SCM service (broker protocol, repository methods, credential vault, CNG ECDSA identity, capability MAC/nonce protocol), dual reproducible clean-clone builds, elevated pinned-hash provisioning, and five contract suites with per-byte crash injection. W05 adds a universal command supervisor spanning Job Objects, per-attempt WSL distros, Docker, pack quarantine (NTFS reserved names, ADS, case-fold collisions), and a five-package bootstrap replay. W12 spans `GateRosterV2` schema + independent Rust and Go reproduction, CI integration, a full smoke harness, OpenSpec archive machinery, and the closure protocol. Each is several multiples of sibling packages such as W02 or W04. The contract's own scale check (one implementation sprint per package) fails for these three.
- **Impact:** Oversized packages defeat per-package evidence granularity — a single closure hash covers weeks of heterogeneous work — and make the stated sequential W01→W12 Sprint 0 schedule unrealistic, which pressures exactly the self-closure weakness in F5-MAJOR-004.
- **Correction:** Split W03 (broker protocol/reducer vs privileged repository+credential methods vs build/provisioning), W05 (supervisor vs transaction/quarantine vs bootstrap replay), and W12 (roster+reproduction vs CI/smoke vs closure protocol) into chained same-sprint packages. Renumber before `PBT-S00-W02` freezes the 100-package plan.
- **Affected packages:** `PBT-S00-W03`, `PBT-S00-W05`, `PBT-S00-W12`; the frozen `ProgramPlanV1` (`PBT-S00-W02`).
- **Verification criterion:** No package's Files/Create list spans more than one deliverable domain; the revised register still topologically orders; package count and sprint table update consistently across plan, wiki, and graph.
- **Confidence:** High on the enumeration; medium on the sizing judgment (deliberately conservative sizing is possible but then the sprint schedule claim should change instead).

### F5-MAJOR-006 — Contributor-independence tests are load-bearing exit evidence but undefined

- **Path:** `docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md:318`; `docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md:480–481`; `knowledge_base/program-wiki/wiki/open-questions.md:25–26`
- **Evidence:** `PBT-S08-W01`'s exit evidence freezes "minimum count, independence tests, contributor keys" and validates "independently controlled environments". The spec defines independence only conceptually ("separate control of entropy and operational environments, not distinct names or agent processes"). No document specifies how enrollment receipts establish that N contributor keys are N independently controlled humans rather than one operator with N keys — the Sybil case is the failure mode the human-participation gate exists to prevent. Open question 7 admits contributor recruitment is unresolved.
- **Impact:** The single most trust-critical control of the ceremony (1-of-N honest human) has a pass/fail gate with no defined test. As written, `PBT-S08-W01` could "validate" independence on evidence that cannot distinguish one operator from N humans.
- **Correction:** Add a participant policy specifying concrete independence evidence — organizational identity attestation, public per-contributor identity anchoring, environment-attestation diversity criteria, and the adjudicator — or reword `PBT-S08-W01` so that defining the independence policy is itself the Sprint 8 deliverable gated on open question 7.
- **Affected packages:** `PBT-S08-W01` through `PBT-S08-W05`; indirectly `PBT-S07` freeze.
- **Verification criterion:** `ceremony/runs/policy-v1.json` (or the spec) enumerates falsifiable independence checks; a reviewer can state what evidence would fail them.
- **Confidence:** High. Uncertainty: none on absence; the policy may be intended as future work, in which case the exit-evidence wording is the defect.

### F5-MAJOR-007 — Golden conformance evidence does not reproduce from a clean checkout on default Windows Git

- **Path:** `scripts/verify-reference-harness.ps1` (evidence-publication check) with `reference/evidence/current-generation.json`; claim at `README.md:74`
- **Evidence:** In the isolated clone (fresh checkout, Git for Windows `core.autocrlf=true`), the default harness run failed: "verification failed: check=evidence-publication; current generation d529f948… hashes do not match generation files" (exit 1) after all 24 functional checks passed. Diagnosis, verified byte-level: the harness hashes working-tree text bytes; the committed golden hashes (e.g., `9e63e079…` for `openspec/changes/sprint-02-reference-harness-poc/proposal.md`) match LF bytes, the fresh CRLF checkout hashes to `1cde7fcc…`. `structural_sha256` reproduced identically; only text-input-bound conformance hashes differ. The repository contains no `.gitattributes` (verified: `git ls-files '*.gitattributes'` is empty). The source repo's working tree happens to hold LF bytes, so the failure is invisible there. Contrast: the program wiki's own rule (`knowledge_base/program-wiki/AGENTS.md:9–12`) mandates hashing committed git blob bytes and warns against exactly this ("Do not hash a platform-specific working-tree text representation"), and the graph's 273 `source_sha256` values all verify under that rule.
- **Impact:** The README's documented flow ("From a clean checkout … A clean run reports `structural-pass`") fails on a default Windows Git installation; golden "input-bound" evidence is actually checkout-configuration-bound. Every future package that cites harness receipts as closure evidence (S00-W12 CI, S02 feasibility) inherits a verifier that is red for any independent party who clones the repo.
- **Failure classification (harness-default, exit 1):** product — the evidence binding hashes unpinned, platform-normalized bytes; the environment (default `autocrlf`) is merely the trigger. All tool-version checks passed, so this is not a dependency or environment-provisioning failure.
- **Correction:** Commit a `.gitattributes` pinning `* text eol=lf` (or `-text`) for all evidence-input paths, or change the harness to hash committed blob bytes (`git cat-file blob`) as the wiki rule already requires; then regenerate or re-confirm golden evidence and re-run the read-only verifier from a fresh clone.
- **Affected packages:** `PBT-S00-W12` (CI), `PBT-S02-*`, any package citing harness receipts.
- **Verification criterion:** `git clone <repo> fresh && pwsh -NoProfile -File fresh/scripts/verify-reference-harness.ps1` exits 0 on a machine with `core.autocrlf=true`.
- **Confidence:** High; reproduced and byte-verified in this audit.

### F5-MAJOR-008 — Top-level repository documents were not rebaselined and now contradict the changed program

- **Path:** `README.md:60, 90–91`; `EXAMINATION-CHECKLIST.md:27, 48, 52, 175, 194–196`; `RESEARCH-PLAN.md:58`; `knowledge_base/program-wiki/wiki/contradictions.md` (omission)
- **Evidence:** The range replaced `OutcomeClassifierV1` with `OutcomeClassifierV2` — the canonical design now emits only `blocked`/`live-pass` (design lines 1331–1332, 2857) — yet README:60, CHECKLIST:27/48/52/175, and RESEARCH-PLAN:58 still present `degraded-lab` as an attainable outcome tier. README:90 still describes "the 11-sprint program" superseded by the 14-sprint/100-package register. CHECKLIST:194–196 cites "§31" three times while the canonical design has exactly 25 sections (recounted; the range mandates exactly 25). `contradictions.md` records one README conflict but omits the live 11-vs-14-sprint conflict.
- **Impact:** A reader of the repo's front door would believe a lab run yields a positive classification the classifier no longer emits and that a superseded program is current. The wiki's contradiction register, whose purpose is exactly this, under-reports a known conflict.
- **Correction:** Update README, EXAMINATION-CHECKLIST, and RESEARCH-PLAN to the V2 outcome vocabulary and the 14-sprint register; re-point the §31 references to current section numbers; add the schedule conflict to `contradictions.md` until the README fix lands.
- **Affected packages:** program communication generally; wiki lint (`PBT-S00-W11`).
- **Verification criterion:** `git grep -l 'degraded-lab'` returns no top-level program document (or each hit carries an explicit supersession note); no `§3[0-9]` reference exceeds §25.
- **Confidence:** High; all hits verified at the target commit.

### F5-MINOR-001 — Broken YAML frontmatter introduced in proof-systems-fundamentals.md

`knowledge_base/proof-systems/proof-systems-fundamentals.md:3`. The range replaced the baseline em dash with an unquoted colon: `title: Proof-system fundamentals: NIZK, SNARKs, soundness, zero-knowledge` — invalid YAML (mapping value inside a scalar). Breaks any frontmatter-reading tooling (wiki lint, OKF). **Correction:** quote the scalar. **Affected:** `PBT-S00-W11` lint. **Verify:** `yaml.safe_load` of the frontmatter succeeds. Confidence: high (baseline/target bytes compared).

### F5-MINOR-002 — Stale pre-rebaseline sprint authority in the claim protocol

`knowledge_base/bridges/midnight-cardano-recursive-bridge.md:1043–1044`: "The wire profile remains a source-dependent Sprint 3 gate" — the same document retires legacy sprint numbering (lines 31–33) and the register places encoding schemas in `PBT-S04-W01..W04`. The gate has no resolvable owner. **Correction:** replace with the owning `PBT-S04` package or roster gate id. **Affected:** `PBT-S04`. **Verify:** no `Sprint [0-9]` legacy authority references remain in sections the rebaseline governs. Confidence: high.

### F5-MINOR-003 — Ceremony concept page states planned, mode-dependent controls as current and unconditional

`knowledge_base/proof-systems/groth16-trusted-setup-ceremony.md:81–85, 92–98`. Present tense: "Each distinct transcript **has** its own precommitted future randomness beacon…", "**Anyone can re-verify the whole ceremony**…" — but the pinned source uses a caller-supplied beacon known before contributions (`wiki/components/mpc-ceremony.md:22–23`), `CeremonyBeaconScheduleV1` is unbuilt Sprint-7/8 work, and no ceremony exists to re-verify. The page also states the precommitted-beacon rule unconditionally for "The KZG ceremony", while the design's `historical-qualified` mode explicitly "cannot add a new beacon to old bytes" (`mpc-ceremony.md:53`; spec lines 458–463). **Correction:** recast as requirements ("must have"), note that no bridge ceremony has been run, and qualify the beacon rule to `new-or-update` mode. **Affected:** `PBT-S07-W04`, `PBT-S08-W02`. **Verify:** the page distinguishes existing pinned-source behavior from planned bridge requirements in each safeguard bullet. Confidence: high.

### F5-MINOR-004 — Claims presented as receipt-bound exceed what the receipt records

`knowledge_base/proof-systems/groth16-trusted-setup-ceremony.md:33–34, 38–39, 53–55`. Line 33–34 declares the setup details "bound to the exact gnark MPC source receipt", but the delta-PoK sentence (lines 53–54, "across the G1 and G2 delta points and the inverse-scaled proving-key terms") is not among the receipt's recorded observations — I verified the claim is **true** of the pinned `phase2.go` (the `Verify` call covers `G1.Delta`, `G2.Delta`, and inverse-scaled `Z`/`PKK`), so this is a provenance defect, not a factual one. Line 38–39's "reviewed gnark fork" also exceeds the receipt, which states it "does not approve the fork". **Correction:** extend the receipt with the delta-PoK observation via a fresh retrieval record, and say "pinned (not yet reviewed) gnark fork". **Affected:** `PBT-S07-W01`. **Verify:** every "bound to the receipt" claim appears verbatim in a receipt observation list. Confidence: high (code verified against live-retrieved, hash-matching bytes).

### F5-MINOR-005 — "Reusable BSB22 Phase 1" mislabels circuit-independent Powers of Tau

`knowledge_base/proof-systems/groth16-trusted-setup-ceremony.md:119, 130–131`. Phase 1 contributes tau/alpha/beta — standard Groth16 Powers of Tau; the BSB22-specific additions are the Phase-2 sigma values and key sealing (per the page's own lines 51–55 and the receipt). "BSB22 Phase 1" invents a BSB22-specific universal phase and blurs the universal-SRS vs circuit-specific distinction the contract's Stage D checks. **Correction:** "a separate reusable Groth16 Phase 1 (Powers of Tau) plus a per-circuit commitment-aware (BSB22) Phase 2." **Affected:** documentation only. **Verify:** terminology consistent with the receipt's phase descriptions. Confidence: high.

### F5-MINOR-006 — No beacon source or required beacon properties specified after removing drand

`knowledge_base/proof-systems/groth16-trusted-setup-ceremony.md:81–85`; `docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md:306`; spec lines 450–456. The rewrite deleted the baseline's concrete beacon ("A public randomness beacon (drand)…") and no changed document names any beacon class or its required properties (public verifiability, unpredictability horizon vs close point, resolution authenticity). `CeremonyBeaconScheduleV1` fixes scheduling, not provenance. **Correction:** specify the beacon class and its verification, or record it as an explicit open design parameter with an owning package. **Affected:** `PBT-S07-W04`, `PBT-S08-W01`. **Verify:** the schedule schema or policy names the beacon source class and its verification rule. Confidence: high.

### F5-MINOR-007 — proof-zk-recovery receipt claims upstream authority but was acquired locally with upstream verification deferred

`knowledge_base/program-wiki/raw/source-receipts/proof-zk-recovery-mpc-2026-07-10.md:7–11, 48–50`. "Authority: upstream Git objects from `https://github.com/CharlesHoskinson/proof-zk-recovery`" vs "Acquisition: existing local Git object database at `C:/proof-zk-recovery`", with upstream fetch deferred to Sprint 7. Anything citing the receipt inherits an unconfirmed upstream identity. (This audit verified every recorded object — commit, parent, subtree, blob sizes, blob SHA-256s, archive bytes+hash — against the local object database; all match. Upstream equality remains unverified.) **Correction:** reword authority as "local clone of <URL>; upstream identity to be confirmed at PBT-S07-W01", or perform and record the upstream fetch. **Affected:** `PBT-S07-W01`. **Verify:** receipt authority line matches its acquisition method. Confidence: high.

### F5-MINOR-008 — Planning baseline is self-designated at runtime and pinned nowhere external

`docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md:38–40, 170`. W01 "records its full SHA at runtime": whatever HEAD is when W01 runs becomes the planning baseline; no external record pins which commit contains the approved plan, so a later commit that alters the plan could self-designate. All lineage checks chain from that runtime choice. **Correction:** record the planning-baseline SHA in an external operator-held record before W01 (the plan already uses this pattern for the build-qualification hash) and require W01 to verify equality. **Affected:** `PBT-S00-W01`. **Verify:** W01 contract test compares the resolved SHA to a pre-existing external value. Confidence: high.

### F5-MINOR-009 — "Approved design source commit" authenticates different bytes than the design it approves

`docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md:46–47`. The spec names `3db35fa9` as the approved design source commit, but the spec at the target commit differs from its `3db35fa9` version by +235/−48 lines (control-model, GateRosterV2, closure, bundle sections added post-"approval"). W01 would bake the misattribution into the baseline manifest. **Correction:** point the field at the commit containing the approved bytes, or state the post-`3db35fa9` revision and name its review. **Affected:** `PBT-S00-W01`. **Verify:** blob digest of the named commit's spec equals the digest of the spec text the field appears in, or the revision note exists. Confidence: high.

### F5-MINOR-010 — `classifier-readiness-v1.schema.json` is referenced as roster-bound evidence schema but no package creates it

`docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md:1232`. The base `GateRosterV2` must bind `program/schemas/classifier-readiness-v1.schema.json` as the classifier-readiness gate's accepted evidence schema, but no Files/Create list in either plan produces that file (W12's list omits it; W03's 16 schemas omit it) — repo-wide grep finds only this one reference. W12's own "evidence schema mismatch" fixture (line 1240) would have nothing committed to check against. **Correction:** add the schema to W12's Create list (schemas freeze with the roster) or carry a logical schema id whose file is explicitly assigned to a named later package. **Affected:** `PBT-S00-W12`, `PBT-S12-W07`. **Verify:** roster fixture test finds the schema file at the bound path. Confidence: high.

### F5-MINOR-011 — ClosureEnvelopeV1 permitted-content lists disagree on redaction receipts

`docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md:100–104` (permits "…inventories, seal receipts, and, only for `PBT-S13-W05`…") vs `docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md:1086` ("inventories, redaction/seal receipts") and `:1236` (FinalizeClosure materializes a "redaction receipt"). A validator implementing the master enumeration must reject the Sprint 0 closure tree the Sprint 0 plan requires. **Correction:** add redaction receipts to the master plan's and rebaseline's permitted-content enumerations. **Affected:** `PBT-S00-W12`. **Verify:** the three enumerations are identical or reference one schema. Confidence: high.

### F5-MINOR-012 — mpc-ceremony page attributes specific properties to the source branch that no in-repo record supports

`knowledge_base/program-wiki/wiki/components/mpc-ceremony.md:18–25`. "BGM17 wrappers… hash-linked transcripts… golden VK vectors… pinned gnark memory patch" and the defect list "caller-supplied beacon… mini circuit… caps payloads… reuses the same verifier stack" trace to no receipt observation, raw session, or in-repo excerpt; the proof-zk-recovery receipt records object identities only. This audit verified the claims are **accurate** against the hash-pinned `proto/ceremony` tree (e.g., `core.CompileMiniCircuit` in `cmd/contributor/main.go`, `maxPayload` cap in `core/transcript.go`, golden VK drift canary in `spec/drift_canary_test.go`, the gnark `replace` pin in `go.mod`) and partially against the assurance-review blob (beacon, single-operator Preview). The defect is traceability, not truth: the wiki's own rules require claims to trace to receipts. **Correction:** add a receipt (or receipt addendum) recording these observations with paths inside the pinned tree, or cite the archive receipt + file paths inline. **Affected:** `PBT-S07-W01`; wiki lint. **Verify:** each source-branch claim cites a receipt or a path within a hash-pinned artifact. Confidence: high.

### F5-MINOR-013 — Four active contradictions exist only in prose; the event stream contains zero `contradict` events

`knowledge_base/program-wiki/wiki/contradictions.md:13–39`; `graph/events.jsonl` (273 events: 134 add-node, 136 add-edge, 2 assert, 1 verify, 0 contradict/supersede/resolve); `graph/schema.json:41` defines the operations; `AGENTS.md:49–50` requires contradiction events. All four documented contradictions verify as real against repo state, but a graph-only consumer sees a conflict-free program even though the execution-model decision page calls the event stream the historical truth. **Correction:** append one `contradict` event per active item (subject = affected node, source = the receipts contradictions.md already cites) and `resolve` events when closed — or amend AGENTS.md to scope which contradictions must become events. **Affected:** `PBT-S00-W11`. **Verify:** count of active items in contradictions.md equals count of unresolved contradict events. Confidence: high.

### F5-MINOR-014 — Wiki provenance gaps: synthesis cited as source, missing owner edges, undocumented 07-11 log entries

(a) `wiki/open-questions.md:7–8` cites `risk.public-chain-gates` — a maintained synthesis page — as its sole source, violating AGENTS.md:14–15/37–38 ("repository path or source receipt id"; "never present synthesis as a primary source"). (b) `wiki/open-questions.md:28` claims every question has an owning gate, but `risk.predicate-catalogs` (question 5) has no `owned-by` edge and no Sprint-3 node exists among the aliases. (c) `wiki/log.md:56, 73` — two `[2026-07-11]` entries have no raw design-session record and postdate the last graph event (2026-07-10T23:58:00Z), so either the dates are wrong or two sessions bypassed the ingest rule. **Correction:** (a) source the page from the rebaseline session receipt plus the repo docs the risk page cites; (b) add the missing `owned-by` edge (and node if needed); (c) add raw session records or re-date/merge the entries. **Affected:** `PBT-S00-W11`. **Verify:** wiki lint checks pass for source classes, ownership claims, and log-entry backing. Confidence: high.

### F5-NOTE-001 — Normative requirement embedded in an immutable raw receipt

`knowledge_base/program-wiki/raw/source-receipts/gnark-bsb22-mpc-2026-07-10.md:47–48`: "The bridge must provide distinct future beacons…" is synthesis, not an observation of the retrieved source, inside a file the rules make immutable. Move the "must" sentence to `mpc-ceremony.md` or the spec via a superseding receipt when next touched.

### F5-NOTE-002 — Historical-qualification list in the wiki omits the contributor-policy element the plan requires

`knowledge_base/program-wiki/wiki/components/mpc-ceremony.md:51–52` lists precommitment/chronology/beacon/algebra/anchors/bytes; plan line 318 additionally pins "the original ceremony evidence **and contributor policy**". As written, the wiki leaves open whether a single-operator historical SRS could qualify. Add the contributor-policy element.

### F5-NOTE-003 — Rewritten ceremony page's frontmatter provenance not updated

`knowledge_base/proof-systems/groth16-trusted-setup-ceremony.md:4, 16`: timestamp `2026-07-09T14:27:04Z` and single source `src-0014` predate the rewrite that now derives load-bearing content from the gnark receipt (line 33–34). Add the receipt to sources and refresh the timestamp.

### F5-NOTE-004 — zero-knowledge-proofs.md bookkeeping inconsistencies

`knowledge_base/midnight/zero-knowledge-proofs.md:99–102`: the setup question is marked resolved "by the specific implementation sources" while the recursion question remains "Not addressed by this source" although the same source set (cited at line 77) pins recursion; and line 23's unqualified "trustless" predates the canonical design's restriction of the term to a specific trust profile. Align both.

### F5-NOTE-005 — `ArtifactAuthorizationV1` carries no issuance-authority binding

`knowledge_base/bridges/midnight-cardano-recursive-bridge.md:432–438`: the record that authorizes generated verifier-key bytes binds evidence and independent-verification digests but no approval policy or signer set, unlike `CheckpointApprovalPolicyV1`. The issuing authority is only implicit via roster-owner signatures elsewhere. Add an approval-policy digest field or name the governing preauthorized policy.

### F5-NOTE-006 — Present-tense "is implemented" for unbuilt machinery

`knowledge_base/program-wiki/wiki/components/program-control-plane.md:14–15`: "It is implemented by the 12 packages in `PBT-S00`" — none of `controller/`, `program/`, or roster-v2 artifacts exist at this commit. The only deployment-state-adjacent slip found. Use "will be implemented by".

### F5-NOTE-007 — W09 interface references a W10 artifact as already tested

`docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md:1012`: the W09 packet cites "the tested detached audit runner from Task 10", which does not exist during W09. Reword to bind the path constant and defer runner validation to W10.

### F5-NOTE-008 — Forward-declared normative OpenSpec change does not exist yet

`knowledge_base/bridges/midnight-cardano-recursive-bridge.md:43`: "`openspec/changes/pbt-s00-program-control-plane/` when created by PBT-S00-W01" — honestly conditional; verified absent at the target commit. Tracking note only: update the cell when W01 runs.

### F5-NOTE-009 — Tooling/data feasibility gates have no corresponding open question

`knowledge_base/program-wiki/wiki/risks/public-chain-gates.md:42–43` (Compact, `cardano-node`, `cardano-cli` unqualified; Midnight genesis/BEEFY data reproducibility) are feasibility gates with no entry in `open-questions.md`, which bills itself as the register of execution-blocking unknowns. Add a question or an explicit pointer.

### F5-NOTE-010 — Wiki page statuses have no graph representation

Frontmatter statuses (`blocked`, `active`) exist only in prose; nodes.json carries no status attribute and no assert events record them, so the lint concept "stale claims" cannot be evaluated from the graph. No written rule is violated at this commit; recorded as a deferred risk for `PBT-S00-W11`.

## 6. Codex Remediation Queue

Ordered by safety impact and dependency. All corrections stay inside the public-testnet proof-of-concept path. NOTE findings carry no immediate correction and are excluded.

| # | Finding | Paths | Prereq | Target WP / sprint | Correction summary | Verification criterion |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | F5-MAJOR-002 | `knowledge_base/bridges/midnight-cardano-recursive-bridge.md` §6 (634–636, 789–830), §11 | — | before `PBT-S00-W02` freeze; affects `PBT-S02` | Align §6 to genesis+official-roots bootstrap; restrict checkpoint profile to proved-from-official-roots acceleration or lab-only | §§1/6/11 name one identical PoC bootstrap mode |
| 2 | F5-MAJOR-003 | master plan:28; pbt-s00 plan:841; rebaseline spec:530–531 | — | before `PBT-S00-W02` | Single enumerated re-entry table, identical in all three documents, including deployed-copy/ABI drift → S11 | plan-validation contract test passes against all three texts |
| 3 | F5-MAJOR-005 | pbt-s00 plan W03/W05/W12 sections; master register | — | before `PBT-S00-W02` | Split W03/W05/W12 into chained same-sprint packages; renumber register, wiki, graph consistently | revised register topologically orders; counts reconcile across plan/wiki/graph |
| 4 | F5-MAJOR-004 | pbt-s00 plan:1084–1086, 1292; register 0/0/0 rows | after #3 (plan text settles) | `PBT-S00-W10`/`W12`; all closures | Add out-of-host attestation to sprint-closing reviews or reclassify reader output as non-closure evidence | closure contract names ≥1 input the implementing host cannot regenerate |
| 5 | F5-MAJOR-001 | review doc:5, 53–60 | after #1–#3 (reviewed text final) | pre-`PBT-S00-W01` | Re-issue review bound to exact reviewed blob digests, committed after reviewed content (or relabel as bootstrap review) | `git cat-file -e <baseline>:<path>` succeeds for every reviewed doc with matching digests |
| 6 | F5-MAJOR-007 | `.gitattributes` (new); `scripts/verify-reference-harness.ps1`; `reference/evidence/*`; README:74 | — | before `PBT-S00-W12` CI | Pin text eol or hash committed blob bytes; re-confirm golden evidence from a fresh clone | fresh clone with `autocrlf=true` → default verify exits 0 |
| 7 | F5-MAJOR-006 | master plan:318; rebaseline spec:480–481; mpc-ceremony.md | — | `PBT-S08-W01` (spec text now) | Define falsifiable contributor-independence evidence and adjudication, or make the policy itself the gated deliverable | policy enumerates checks a reviewer could fail |
| 8 | F5-MAJOR-008 | README:60,90; CHECKLIST:27,48,52,175,194–196; RESEARCH-PLAN:58; contradictions.md | — | immediate; wiki lint `PBT-S00-W11` | Rebaseline top-level docs to V2 outcomes + 14-sprint register; fix §31 pointers; record schedule conflict until fixed | no stale `degraded-lab`/11-sprint/§>25 references without supersession notes |
| 9 | F5-MINOR-009 | rebaseline spec:46–47 | with #5 | `PBT-S00-W01` | Point approved-design commit at the approved bytes or add revision note naming its review | named commit's spec blob equals the described bytes, or note present |
| 10 | F5-MINOR-008 | pbt-s00 plan:38–40, 170 | — | `PBT-S00-W01` | Pre-register the planning-baseline SHA externally; W01 verifies equality | W01 contract test compares against pre-existing external value |
| 11 | F5-MINOR-011 | master plan:100–104; rebaseline:239–240; pbt-s00:1086,1236 | — | `PBT-S00-W12` | Add redaction receipts to master/rebaseline ClosureEnvelopeV1 permit lists | three enumerations identical or one schema referenced |
| 12 | F5-MINOR-010 | pbt-s00 plan:1232 (W12 Files list) | with #3 | `PBT-S00-W12` | Add `classifier-readiness-v1.schema.json` to W12 Create list or assign producer explicitly | roster fixture finds schema at bound path |
| 13 | F5-MINOR-002 | bridge design:1043–1044 | — | doc fix now; owner `PBT-S04` | Replace "Sprint 3 gate" with owning `PBT-S04` package/gate id | no legacy sprint-authority references in rebaselined sections |
| 14 | F5-MINOR-001 | proof-systems-fundamentals.md:3 | — | immediate | Quote the title scalar | YAML frontmatter parses |
| 15 | F5-MINOR-003 | groth16-trusted-setup-ceremony.md:81–85, 92–98 | — | doc fix now; owner `PBT-S07-W04` | Recast planned safeguards as requirements; qualify beacon rule to new-or-update mode; state no ceremony has run | page separates pinned-source behavior from planned requirements |
| 16 | F5-MINOR-004 | groth16 page:33–34, 38–39, 53–55; gnark receipt | — | `PBT-S07-W01` | Extend receipt with delta-PoK observation (fresh retrieval record); drop "reviewed" for the fork | every receipt-bound claim appears in a receipt observation |
| 17 | F5-MINOR-005 | groth16 page:119, 130–131 | — | immediate | Rename to "Groth16 Phase 1 (Powers of Tau)" + "commitment-aware (BSB22) Phase 2" | terminology matches receipt phase descriptions |
| 18 | F5-MINOR-006 | groth16 page:81–85; master plan:306; spec:450–456 | — | `PBT-S07-W04` / `PBT-S08-W01` | Name the beacon class + verification rule, or record as owned open parameter | schedule/policy names beacon source class and verification |
| 19 | F5-MINOR-007 | proof-zk-recovery receipt:7–11 | — | `PBT-S07-W01` | Correct authority wording to local-clone acquisition with deferred upstream confirmation (superseding receipt) | authority line matches acquisition method |
| 20 | F5-MINOR-012 | mpc-ceremony.md:18–25; receipts | — | `PBT-S07-W01`; wiki lint | Record the source-branch observations in a receipt addendum with in-tree paths | each claim cites receipt or hash-pinned path |
| 21 | F5-MINOR-013 | graph/events.jsonl; contradictions.md | — | `PBT-S00-W11` | Append contradict events for the four active items (or scope the rule in AGENTS.md) | active prose items == unresolved contradict events |
| 22 | F5-MINOR-014 | open-questions.md:7–8, 28; log.md:56, 73; graph | — | `PBT-S00-W11` | Fix page sources; add owner edge/node; add raw records for (or re-date) 07-11 log entries | wiki lint passes source-class, ownership, and log-backing checks |

## 7. Verification Results

All commands ran in the isolated clone/audit root with the contract's bootstrap environment (TEMP/TMP, GOTMPDIR, GOCACHE, CARGO_TARGET_DIR, PYTHONPYCACHEPREFIX redirected below the audit root; OPENSPEC_TELEMETRY=0, DO_NOT_TRACK=1). Times are UTC.

| # | Command (working dir = audit clone unless noted) | Start | End | Exit | Outcome / class |
| --- | --- | --- | --- | --- | --- |
| 1 | Environment bootstrap script (audit-root creation, write probe, clone, detach, dependency copy, diff enumeration) | 2026-07-12T00:54:21Z | ~2026-07-12T00:55Z (end not logged to the second) | 0 | pass; write probe ok; both local dependencies present and copied |
| 2 | `git diff --shortstat 78bd432a..9f544565` | 00:55Z | 00:55Z | 0 | `34 files changed, 4797 insertions(+), 316 deletions(-)` — matches contract |
| 3 | `pwsh -NoProfile -File scripts\verify-reference-harness.ps1` (default) | 00:57:01.046Z | 00:57:41.258Z | **1** | 24 checks PASS (tool-versions, python-lock, control/rust/go/observation tests, go-vet, cross-language-vectors, roster-publication, independent-cbor, unsigned-observations, bootstrap-qualification, structural-candidate, openspec-strict, git-diff-check, input-stability), then `evidence-publication` FAILS: fresh conformance hashes ≠ committed golden. **Class: product** (line-ending-dependent evidence binding; see F5-MAJOR-007). Supports F5-MAJOR-007 |
| 4 | `…verify-reference-harness.ps1 -UpdateEvidence` | 00:57:41.301Z | 00:58:17.182Z | 0 | pass; regenerated evidence in audit clone only |
| 5 | `…verify-reference-harness.ps1` (post-update, read-only) | 00:58:17.186Z | 00:59:11.393Z | 0 | pass against regenerated evidence — confirms the only unstable input class is text-byte hashing |
| 6 | `npm --offline run openspec:validate` | 00:59:11.397Z | 00:59:11.961Z | 0 | `Totals: 13 passed, 0 failed (13 items)` |
| 7 | Structured graph validation (Python, venv `python -B`; schema conformance, sequence/id/time monotonicity, V1-prefix byte equality vs pinned blob, all 273 `source_sha256` vs target-commit blob bytes, view↔event reconciliation) | ~01:01Z | ~01:02Z | 0 | **0 defects.** V1 prefix sha256 `401d2fc4…e51e50` matches AGENTS.md pin; 273/273 source hashes match blob bytes; node set == add-node set; 136 edges == 136 add-edge events. Log: `logs/graph-validate.log` |
| 8 | Wiki frontmatter lint (12 pages; required fields, type/status vocab, id uniqueness) | ~01:05Z | ~01:05Z | 0 | 12/12 conformant, 12 unique ids |
| 9 | Gate/section/predicate/package recounts (gate-roster JSON parse; §-header scan; catalog count-lines; register id sweep; DAG cycle check on graph edges) | ~01:04–01:09Z | — | 0 | 6 `S01-BLOCK-*` + 8 `CONS-*` = 14; exactly 25 sections numbered 1–25; 42/52/94 consistent; 100 register ids == 100 graph package nodes; no cycles |
| 10 | CRLF hypothesis test (worktree vs blob vs golden hash for `sprint-02…/proposal.md`) | ~01:00Z | — | 0 | golden `9e63e079…` == source-repo LF worktree; fresh CRLF checkout `1cde7fcc…` ≠ golden. Supports F5-MAJOR-007 |
| 11 | `git status --porcelain=v2` of audit clone after -UpdateEvidence | 00:59Z | — | 0 | 2 modified files under `reference/evidence/` (conformance report, current-generation) — expected audit-clone evidence change, **not** a source-repository change |
| 12 | Scrapling retrievals + hash checks (see §8) | 01:03:28Z–01:12:25Z | — | 0 | 4/4 receipts reproduce exactly (one required the receipt's own `--ai-targeted` transport) |
| 13 | proof-zk-recovery local object verification (`git cat-file`/`rev-parse`/`archive` against `C:\proof-zk-recovery`) | ~01:04–01:07Z | — | 0 | commit `6c5dc257` (parent `adf4e9ae`), subtree `fbd85ba8`, go.mod blob 839 B sha256 `410a22fd…`, assurance blob 13,865 B sha256 `9fad6515…`, LICENSE 11,348 B sha256 `56437530…`, archive 133,120 B sha256 `8ad53431…` — all match the receipt |

Verification tally: **passed 12, failed 1, limited 0** (the single failure is command 3, classified product, and is itself finding F5-MAJOR-007).

## 8. External Source Ledger

All retrievals via Scrapling (venv 0.4.10) on 2026-07-12 (UTC), saved below the audit root under `sources/`. Support column: direct = bytes verified against a recorded hash; the retrieval verifies the receipt, and the receipt supports the repository claim.

| # | URL | Retrieved | Claim supported | Result |
| --- | --- | --- | --- | --- |
| 1 | `https://raw.githubusercontent.com/CharlesHoskinson/gnark/0dc3be8cad8af3943924fd36b190ebefc6094a4e/backend/groth16/bls12-381/mpcsetup/phase1.go` | 2026-07-12T01:03:28Z | gnark receipt row (8,973 B, `20376f62…`) | **match** (direct) |
| 2 | `…/mpcsetup/phase2.go` | 01:03:28Z | gnark receipt row (12,838 B, `8607f5d6…`); additionally confirms the delta-PoK verification covers G1/G2 delta and inverse-scaled Z/PKK terms (F5-MINOR-004 truth check) | **match** (direct) |
| 3 | `…/mpcsetup/setup.go` | 01:03:28Z | gnark receipt row (3,831 B, `e61eb9b2…`) | **match** (direct) |
| 4 | `https://gist.githubusercontent.com/karpathy/442a6bf555914893e9891c11519de94f/raw/llm-wiki.md` | 01:03:29Z and 01:12:25Z | karpathy receipt (11,992 B, `ef8342b7…`) | **match under the receipt's recorded transport** (`extract get --ai-targeted`, 11,992 B, exact hash). Raw `Fetcher.get` body is 11,985 B / different hash — a transport-mode difference, not content drift; receipts should ideally record revision-pinned gist URLs, but no defect is filed since the receipt names its transport |
| 5 | `https://github.com/CharlesHoskinson/proof-zk-recovery` (not fetched; receipt's own acquisition was the local object database) | — | proof-zk-recovery receipt | verified against local odb `C:\proof-zk-recovery` (7 object/hash checks, all match — see §7 cmd 13). Upstream identity remains unconfirmed (F5-MINOR-007) |

No other external technical claims in the changed files required retrieval: chain observations (Midnight/Mithril Preview samples, SRS hashes, transaction ids) are consistently labeled dated unsigned observations by the documents themselves, and the contract's rules forbid answering beyond what receipts establish.

## 9. Environment and Limitations

- Host: Windows 11 Pro 10.0.26200, PowerShell 7.6.3, Git for Windows with effective `core.autocrlf=true` (repo-level in both source repo and clone; global unset). This configuration is what surfaced F5-MAJOR-007; a machine with `autocrlf=false` and an LF worktree would not reproduce the default-run failure.
- The isolated clone received copies of `.venv-scrapling` and `node_modules` from the source repository per the bootstrap contract; `setup-reference-harness.ps1` was not re-run (the harness's own tool-version and python-lock checks passed, so provisioning was not a limiting factor).
- Rust/Go/Node toolchains resolve from user-global installs; build outputs were redirected below the audit root (`CARGO_TARGET_DIR`, `GOCACHE`).
- The audit-clone diff after `-UpdateEvidence` (2 evidence files) is expected behavior of that flag inside the audit clone and was not treated as a repository defect.
- Read-only subagents inspected disjoint domains (program control, bridge/proof design, ceremony/MPC, wiki–graph consistency). Every retained finding was re-verified by the lead auditor against the committed bytes at the target commit; subagent votes were not treated as consensus, and two subagent candidates were eliminated by disconfirming evidence (the Karpathy "hash drift", refuted by re-retrieving with the receipt's recorded transport; the delta-PoK "unsupported claim", downgraded after code verification proved it true).
- The upstream `github.com/CharlesHoskinson/proof-zk-recovery` remote was not fetched (receipt acquisition was local by its own statement); upstream/local equality is deferred to `PBT-S07-W01` and marked in F5-MINOR-007.
- `pyyaml` was unavailable in the pinned venv, so F5-MINOR-001 was verified by YAML grammar analysis (unquoted colon in a plain scalar) plus byte comparison with the baseline, not by a parser run.
- No cryptographic verification, proof generation, chain interaction, ceremony participation, or receipt fabrication was performed or attempted.

## 10. Confirmed Strengths

Evidence-backed observations, not praise:

1. **The knowledge graph is mechanically sound.** All 273 events parse, conform to the V1/V2 schema split (29 V1 / 244 V2), are contiguous and time-monotonic; the V1 prefix is byte-identical to its pinned blob (`401d2fc4…`); all 273 `source_sha256` values match committed blob bytes; nodes.json/edges.json reproduce exactly from the event stream; the V1→V2 transition record's every claim verifies against the object database. Append-only held across both commits touching the stream.
2. **External source receipts reproduce.** All four independently retrievable hash claims match exactly, and all seven locally verifiable proof-zk-recovery object claims (commit, parent, subtree, blob ids, sizes, SHA-256s, archive hash) match. The receipt discipline — hash exact bytes, name the transport — worked: it allowed byte-level third-party verification months of edits later.
3. **Counts reconcile everywhere they were recomputed.** 25 design sections (numbered 1–25, none content-free); 42+52=94 predicate contract stated identically in design, status file, and gate; 6+8=14 gate roster entries with the published canonical hash (`2f0383d6…`) and 7,705-byte length reproducing; 100 packages and 14 sprints identical across register, wiki tables, and graph; 206 dependency edges forming a DAG whose register order is a valid topological order.
4. **Evidence-level separation is disciplined.** The changed texts repeatedly and correctly distinguish parser acceptance, structural conformance, proof generation, cryptographic verification, on-chain verification, and settlement (e.g., "a native-byte parser, not a verifier"; "Submitted … is not confirmed"; every report fixes `activation_eligible=false`).
5. **The MPC boundary is honestly drawn.** No document claims a ceremony occurred; agents are consistently confined to testing ceremony software ("Agents never substitute for required humans"); synthetic contributions are nowhere admissible as deployment evidence; the predicate catalogs are honestly blocked with explicit no-filler-row rules.
6. **The structural half of the harness reproduces byte-identically** in a fresh clone (`structural_sha256` stable), and the post-update read-only run confirms the pipeline is deterministic once its text-byte input instability (F5-MAJOR-007) is removed.

## 11. Residual Testnet and Chain Gates

Recomputed from `protocol/gate-roster-v1.json` at the target commit; all 14 remain open, none is a finding (they are accurately documented as unresolved):

| Gate | Substance |
| --- | --- |
| `S01-BLOCK-01/catalog-completeness` | 42 Cardano + 52 Midnight predicate catalogs not recovered |
| `S01-BLOCK-02/public-scls-availability` | Public Mithril certification of the exact CIP-0165 SCLS entity not observed |
| `S01-BLOCK-03/event-inclusion` | Midnight event→header→MMR inclusion path absent from the relay object |
| `S01-BLOCK-04/full-decider` | Full Halo2/KZG decider not constrained/measured inside the BSB22 wrapper |
| `S01-BLOCK-05/midnight-execution` | No deployed Midnight operation accepts the external Cardano proof atomically |
| `S01-BLOCK-06/cardano-execution` | No public Cardano validator verifies the complete wrapped BEEFY/MMR claim |
| `CONS-BOOT-01`, `CONS-CARDANO-01`, `CONS-BEEFY-01`, `CONS-CHECKPOINT-01`, `CONS-MIDNIGHT-ID-01`, `CONS-DOMAIN-01`, `CONS-FRESH-01`, `CONS-FREEZE-01` | Eight consensus-evidence gates (bootstrap roots, Cardano finality profile, BEEFY authority evidence, checkpoint rule, Midnight identity, deployment domains, freshness, freeze rules) — open pending authentic chain receipts |

What would close them is specified in the roster's `required_evidence` fields; nothing in this audit shortens that list. Additional non-roster feasibility gates named in the wiki risk register (host tool qualification for Compact/`cardano-node`/`cardano-cli`; Midnight genesis/BEEFY data reproducibility) remain open and should gain open-question coverage (F5-NOTE-009).

## 12. Working Tree Integrity

- Initial source-repository status (captured at bootstrap, 2026-07-12T00:54:21Z, `initial-status.txt`): 7 pre-existing entries — working-tree modifications to `README.md` and `docs/grok-4.5-handoff.xml`, and 5 untracked files under `runlogs/` (`README.md`, 4 schema files). These predate the audit, match the carryover working state the repository's own handoff notes describe, and were not touched, reverted, or attributed by this audit.
- The audit wrote exactly one path into the source repository: `docs/superpowers/reviews/2026-07-11-fable-5-full-audit.md` (this report). That path did not exist in the initial snapshot.
- Final source-repository status was captured after publication and compared with the initial snapshot with the allowed report path filtered from both: **the filtered snapshots are identical (7 entries each, zero delta)** — comparison output recorded below the audit root (`initial-status.txt`, `final-status.txt`).
- No git state-changing operation (stage, commit, merge, rebase, reset, clean, push, config, hook, remote, ref, worktree) was performed against the source repository. The `-UpdateEvidence` mutation occurred only in the isolated audit clone, as the contract requires, and is recorded in `audit-clone-final-status.txt`.
- Integrity verdict: **pass**.
