# Fable 5 Full Audit Prompt Design

**Status:** Approved for implementation on 2026-07-11

## Purpose

Create an XML prompt that directs Claude Fable 5 to audit the public-testnet proof-bridge planning work merged in commits `3db35fa` and `9f54456`. The audit must produce a single Markdown report containing evidence-backed corrections that Codex can implement afterward.

The audit covers the immutable range:

- Baseline, exclusive: `78bd432af06c9ef68e006ab2147da68fce29af6d`
- Target, inclusive: `9f5445659d1927510c6c29f0285a405ecda30767`
- Target tree: resolved and recorded by the auditor before review

This range changes 34 files and includes the program rebaseline, control plane, implementation plan, bridge design, predicate coverage, proof-system decisions, ceremony framework, and program-wiki graph.

## Goals

1. Find omissions, contradictions, unsupported claims, unsafe assumptions, and untestable acceptance gates.
2. Check the plan against repository evidence and authoritative external sources.
3. Distinguish document defects, implementation defects, environment failures, and unresolved chain-access gates.
4. Give Codex an ordered remediation queue with exact file references and verification steps.
5. Preserve the current working tree and all user-owned changes.

## Non-Goals

- Fable does not implement corrections.
- Fable does not deploy contracts or submit testnet transactions.
- Fable does not resolve open chain gates without authentic receipts.
- Fable does not edit source files, documentation, knowledge-graph data, Git metadata, or existing runlogs.
- Fable does not create a separate repository runlog. The report contains its command transcript and source ledger.

## Artifacts

The implementation will add the prompt at:

`docs/fable-5-audit.xml`

When executed, the prompt permits one write inside the source repository:

`docs/superpowers/reviews/2026-07-11-fable-5-full-audit.md`

Temporary files and an isolated clone may be written only below an auditor-owned directory under:

`C:\Users\charl\.fable-audit\midnight-cardano-bridge\{run_id}`

The auditor defines `run_id` as a filesystem-safe UTC timestamp followed by the target commit's short SHA. It is a runtime value, not an authoring placeholder.

The report is not staged or committed by Fable. Codex reviews the report, fixes accepted findings, runs verification, and commits the resulting remediation separately.

## Isolation Model

Fable begins in the existing repository but does not audit mutable working-tree bytes. It:

1. Captures `git status --porcelain=v2 --untracked-files=all` for the original repository.
2. Creates a unique audit root and verifies that it can create, read, and remove a probe file there.
3. Creates writable temporary and build-cache directories below that root.
4. Clones the local repository with `--no-hardlinks` into the audit root.
5. Checks out the target commit in detached-HEAD state.
6. Verifies the target commit and tree object before reading files or running tests.
7. Runs the entire audit in the isolated clone.
8. Writes only the final Markdown report to the original repository.
9. Compares the original repository's final status with its initial status, ignoring only the report path. Any other change is a blocker and must be reported.

This avoids mixing uncommitted edits into the evidence and prevents Go, Rust, Python, or Node tools from modifying the working repository.

## Environment Bootstrap

The XML prompt defines a PowerShell-first bootstrap suitable for the current Windows host. It sets writable paths before version discovery or test execution:

- `TEMP` and `TMP`
- `GOTMPDIR` and `GOCACHE`
- `CARGO_TARGET_DIR`
- `PYTHONPYCACHEPREFIX`

Existing package-manager caches may be read when required for offline verification, but audit commands must not update them. If a command requires writable dependency state, Fable uses an audit-specific cache below the run root. The auditor checks tool availability and versions after the writable-directory probe. A missing tool, unavailable dependency, or permission error is recorded as an environment finding, not misreported as a product failure.

The prompt prohibits silent substitution of tools, proof systems, chain data, or test results. A failed prerequisite narrows the audit scope and appears in the report's limitations section.

## Audit Pipeline

### 1. Scope and Requirement Inventory

Fable inventories every changed file in the pinned range and maps each normative statement to its acceptance evidence. It also follows repository-wide references needed to evaluate changed claims. Unrelated historical code is outside scope unless a changed document depends on it.

### 2. Program-Control Review

Fable checks the sprint graph, work-package identifiers, dependency edges, acceptance gates, evidence receipts, closure hashes, re-entry rules, and deployment-state language. It verifies that a package cannot close through circular, mutable, missing, or self-authored evidence.

### 3. Bridge and Proof Review

Fable examines:

- All 25 sections of the proof-bridge design.
- Cardano and Midnight roots of trust and minimum validator knowledge.
- The 42 Cardano and 52 Midnight predicate claims and their evidence states.
- Cardano-to-Midnight Halo2/KZG proof flow.
- Midnight-to-Cardano Groth16/BSB22 proof flow.
- Statement binding, public inputs, canonical encoding, domain separation, replay resistance, finality, rollback handling, proof freshness, and verifier-key governance.
- The separation between existing SRS material, later circuit-specific ceremonies, and future human MPC participation.
- Reference-harness boundaries and any gap between structural conformance and cryptographic or testnet proof.

### 4. Knowledge and Provenance Review

Fable validates graph schemas, node and edge references, append-only event history, derived wiki views, source receipts, contradictions, and status propagation. It flags claims that are stronger than their cited evidence or whose provenance cannot be reproduced.

### 5. Executable Verification

Fable discovers repository instructions before running commands. At minimum it attempts the repository's OpenSpec validation and reference-harness verification paths, including both evidence-update and default verification modes when supported. It records:

- Exact command and working directory.
- Start and end time.
- Exit code.
- Relevant standard output and error.
- Whether failure is attributable to the product, test fixture, toolchain, network, permissions, or an unresolved prerequisite.

Commands must not update committed evidence unless they run inside the isolated clone. Test success does not override missing chain receipts or unresolved deployment gates.

### 6. External Source Verification

All web retrieval uses Scrapling with `--ai-targeted`. The prompt first looks for the installed executable at `C:\Users\charl\midnight-cardano-bridge\.venv-scrapling\Scripts\scrapling.exe`, treats that environment as read-only, and writes retrieved content below the audit root. If that executable is unavailable, Fable may use another verified Scrapling installation but may not substitute another fetcher. Technical claims rely on primary sources such as protocol specifications, official documentation, standards, research papers, or upstream source repositories. The report records URL, retrieval date, relevant claim, and whether the source directly supports it.

If Scrapling cannot retrieve a required source, Fable records the gap. It does not switch to an unapproved fetcher or fill the gap from memory.

### 7. Adversarial Review

Fable performs a final challenge pass focused on:

- False closure and evidence forgery.
- Cross-chain equivocation and reorganization handling.
- Upgrade, key-rotation, and verifier-version ambiguity.
- Ceremony compromise and toxic-waste assumptions.
- Liveness failures, operator recovery, and partial deployment.
- Claims that confuse parser acceptance, structural verification, cryptographic verification, and on-chain acceptance.
- Work packages whose tests cannot falsify their acceptance criteria.

## Finding Contract

Every actionable finding receives a stable identifier:

- `F5-BLOCKER-NNN`: invalidates the plan, safety model, evidence closure, or auditability.
- `F5-MAJOR-NNN`: material correctness or completeness defect that should be fixed before implementation continues.
- `F5-MINOR-NNN`: bounded defect that does not invalidate the overall design.
- `F5-NOTE-NNN`: useful observation or deferred risk with no immediate correction required.

Each finding contains:

1. Title and severity.
2. Exact repository evidence using commit-relative file paths and line numbers.
3. External evidence where applicable.
4. Why the issue matters.
5. A concrete recommended correction.
6. Dependencies or affected work packages.
7. A verification command, test, or objective acceptance criterion.
8. Confidence and any remaining uncertainty.

Generic advice, style-only rewriting, unsupported cryptographic claims, and duplicate findings are excluded.

## Report Contract

The Markdown report contains:

1. Audit metadata and immutable source identifiers.
2. Executive verdict.
3. Severity counts.
4. Scope coverage matrix for changed files and audit domains.
5. Findings ordered by severity and dependency.
6. Ordered Codex remediation queue.
7. Verification results and command transcript.
8. External source ledger.
9. Environment findings and audit limitations.
10. Confirmed strengths that survived review.
11. Residual testnet and chain-access gates.
12. Original-working-tree integrity check.

The verdict distinguishes among document coherence, structural harness status, cryptographic implementation status, and public-testnet deployment readiness. It cannot report deployment readiness while authentic chain receipts or required chain tooling remain absent.

## Error Handling

- Failure to create a writable audit root stops execution before repository analysis.
- Failure to clone or resolve the target commit stops execution and produces no partial report in the repository.
- Individual test or retrieval failures do not stop the audit. They are recorded and the remaining independent stages continue.
- Malformed repository data is preserved as evidence and never repaired by the auditor.
- If the final integrity comparison detects an unauthorized repository change, the report receives a blocker and names the changed paths.

## Acceptance Criteria

The XML prompt is complete when:

1. It is well-formed XML, contains no unresolved authoring placeholders, and defines every runtime value.
2. It pins the exact baseline, target commit, report path, and write boundary.
3. It bootstraps writable temporary directories before tool discovery or execution.
4. It requires isolated-clone verification and original-tree integrity checks.
5. It covers all audit domains defined above.
6. Its report schema gives Codex enough detail to implement and verify every accepted correction.
7. It forbids Fable from editing or committing remediation.
8. Its prose is direct, specific, and free of performative review language.

## Model-Specific Use

Anthropic describes Claude Fable 5 as a long-running agent model that can plan across stages, delegate, and test its own work. The prompt uses staged checkpoints and self-verification, but does not depend on undocumented sampling controls, hidden system behavior, or simulated reviewer independence.

Primary model reference: <https://www.anthropic.com/claude/fable>
