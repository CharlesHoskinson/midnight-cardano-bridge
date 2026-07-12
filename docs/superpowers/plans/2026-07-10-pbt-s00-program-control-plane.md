# PBT-S00 Program Control Plane Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and close the repository control plane that can execute, recover, audit, and reproduce the remaining 13 public-testnet bridge sprints without losing provenance or weakening a failed gate.

**Architecture:** A native Rust service host running with the dedicated `MCBBridgeController` service SID owns the ACL-protected fenced journal at `C:\Users\charl\.mcb-controller\mcb.public-testnet-livepass.v2`. Package and model processes run under stripped restricted tokens that can modify only an assigned full clone and scratch root. They cannot open controller storage or the canonical repository's `.git` directory for write, delete, rename, ownership, or DACL changes. The broker gives each attempt a private inherited channel and an unforgeable capability bound to its lease and fence. The broker atomically publishes immutable event objects, validates commits from independent clone object databases, and serializes accepted attempt segments into canonical Git. Modules own deterministic plan validation, leases and fencing, process supervision, runlog validation, snapshots, repository transactions, sprint-packet generation, review execution, and wiki lint. JSON Schema defines persisted records. Raw process captures stay under `C:\Users\charl\.mcb-scratch` until deterministic scanning permits publication. OpenSpec defines the normative lifecycle, and the staged `GateRosterV2` maps public roots, destination surfaces, later direction-family execution, and classifier-readiness gates to package evidence.

**Tech Stack:** PowerShell 7.6, .NET process and cryptography APIs, JSON Schema draft-07 through PowerShell `Test-Json`, Git 2.55, GitHub Actions, OpenSpec 1.5.0, deterministic JSON and CBOR, Rust 1.90, Go 1.25.7, Python 3.14 with `cbor2`, Windows 11 and WSL2.

## Global Constraints

- Implement packages in dependency order across `PBT-S00-W01` through `PBT-S00-W18`. The numeric suffix records identity, not execution order; W13-W18 split work formerly assigned to W03, W05, and W12.
- Before each task, invoke `superpowers:test-driven-development`. On a failure, invoke `superpowers:systematic-debugging` before changing implementation.
- Use standalone PowerShell contract scripts, matching the repository's current test style. Do not add Pester as a dependency.
- Every persistent JSON file is UTF-8 without BOM, ends in one LF, rejects unknown fields, and has a checked schema.
- Hash repository text from the Git blob at the named snapshot, not from a line-ending-converted working tree.
- Publish each program and run event as an immutable JSON object through one fenced controller. Create the temporary object with `CreateNew` on the destination volume, call `Flush(true)`, atomically rename with write-through semantics, durably acknowledge parent-directory metadata after the rename, reopen and verify the final bytes, then return success. A filesystem that cannot pass the crash and durability probe blocks Sprint 0. JSONL files are deterministic derived views, not history.
- Store process stdout and stderr as exact bytes. Write the command-start event before launch and one terminal event after confirmed host Job Object, dedicated WSL-distro boundary, or Docker container termination.
- All commands have finite timeouts and required-output contracts. Exit zero alone is not success.
- Put unsanitized command captures, tool caches, dependencies, and audit scratch under an explicit external scratch root. Never use an implicit read-only `TEMP` path for test-bearing audits.
- Do not serialize a complete environment. Persist only schema-allowlisted keys after secret-value rejection.
- Never store private reasoning, model thought streams, credentials, cookies, authorization headers, private keys, or seed phrases.
- Use full per-attempt clones with independent object databases for mutating agent packages. Linked worktrees are not a security boundary because their index, refs, and objects live under the shared canonical `.git` directory. The broker and restricted worker have disjoint ACLs, the controller and canonical Git roots are never mounted into WSL or Docker, and package children receive a private capability channel rather than a controller path. The broker validates and imports accepted clone commits and event segments serially, then pushes normally only after a recorded fetch matches the expected remote SHA and fencing epoch.
- A review round is immutable and binds a complete `ProgramSnapshotV1` rather than a bare commit. `ClosureEnvelopeV1` may add only attestation artifacts after review. Any other scoped drift invalidates the snapshot and affected reviews.
- Preserve the existing uncommitted `README.md`, `docs/grok-4.5-handoff.xml`, and `runlogs/` bytes in the baseline inventory before revising or adopting them.
- Keep deployment outcome `blocked` and `activation_eligible=false`. Sprint 0 proves control behavior, not public-chain readiness.
- Each commit command stages only the files named by its task. Existing unrelated worktree changes remain untouched until their owning task reconciles them.

<!-- re-entry-contract:v2:start -->
| Drift class | Required re-entry |
| --- | --- |
| network identity, official-root, finality, or runtime-semantic drift | `PBT-S02`; invalidate dependent circuits, setup, deployment, and public receipts |
| catalog or proof-template-family drift | `PBT-S03` |
| claim, encoding, registry, or validation-semantics drift | `PBT-S04` |
| circuit, verifier, setup-interface, or ceremony-verifier drift | `PBT-S07` |
| human policy, contribution, beacon, or transcript drift under an unchanged frozen interface | `PBT-S08` |
| endpoint-only drift under unchanged authenticated network and runtime identities | `PBT-S11` |
| fingerprint transition already authorized by the frozen runtime policy | the affected `PBT-S12` package |
| deployed-copy or ABI-observation drift under unchanged authorized bytes | `PBT-S11`, then repeat affected public execution in `PBT-S12` |
<!-- re-entry-contract:v2:end -->

---

## Bootstrap boundary

`PBT-S00-W01` through `PBT-S00-W05`, together with their split continuations
`PBT-S00-W13` through `PBT-S00-W16`, create the machinery that would normally
record their work. They form one bounded bootstrap window:

1. Before any repository work, an operator publishes `ProgramBaselinePrecommitmentV1`
   outside the repository and supplies its path through
   `MCB_PBT_S00_BASELINE_PRECOMMITMENT`. It binds the intended planning commit,
   branch, remote, worktree-status digest, operator identity, and issue time. W01
   rejects a missing, stale, self-authored, or mismatched precommitment. The
   named commit containing this plan and its wiki records is then the planning
   baseline. W01 records its full SHA at runtime, inventories the canonical
   checkout with `git status --porcelain=v2 -z --untracked-files=all`, and then
   creates a detached worktree at that exact commit. Every staged, unstaged, and
   untracked regular file is listed separately. Reparse points, unreadable
   entries, collapsed untracked directories, and unknown pre-staged content
   block execution.
2. W01 and W02 preserve exact commands, byte streams, target commits, and test
   hashes in external scratch. Every commit first proves that the cached path set
   exactly equals the package allowlist.
3. W03 creates the event model and reducer. W13 implements privileged repository
   and credential methods, W14 reproduces and provisions the controller service,
   and W04 adds attempts, renewal, release, monotonic fencing, and recovery.
4. W05 commits the command supervisor, W15 adds transaction and quarantine
   policy, and W16 publishes the package entrypoint without claiming completion.
   A detached clean-checkout replay at that implementation commit then uses the
   supervisor to rerun W01-W05 and W13-W16 checks. It writes nine package-scoped
   receipts under `program/evidence/<package-id>/<attempt-id>/`, each naming its
   original package commit and the cumulative replay commit.
5. A separate control transaction imports those receipts, appends
   `bootstrap-window-closed`, and marks W01-W05 and W13-W16
   `implementation-complete`.
   Bootstrap imports are illegal afterward.

From W06 onward, except for the already completed bootstrap continuations,
`scripts/invoke-program-package.ps1` asks the controller broker
to create the full clone, transaction, lease, attempt, scratch and run roots. It
launches every declared child through `Invoke-RecordedCommand` under the
restricted worker identity, verifies expected outputs, and submits the
implementation commit and immutable event segment through the broker API.
Commands shown below are logical child commands. Direct execution is a test
failure, and package commits never stage canonical program events or derived
state.

Within Sprint 0, `implementation-complete` satisfies a dependency declared with
required state `implementation-complete`. No package becomes `closed` until the
Sprint 0 snapshot passes its deterministic closure contracts and required
external receipts. `PBT-S01` remains unreachable
until all 18 Sprint 0 packages are `closed`.

## Self-hosted package invocation

W16 creates `program/commands/pbt-s00/` with one schema-checked command manifest
per package. W06-W12 and W17-W18 use this exact invocation, changing only
`-PackageId`:

This block is the controller/operator launcher and never appears in a Grok,
Codex, reader, or package-child prompt. The launcher connects to the
operator-authorized broker endpoint, creates the attempt, then starts the model
inside the restricted clone with only its inherited capability handle and a
command shim. The model cannot open the administrative pipe or create another
attempt.

```powershell
$repoRoot = 'C:\Users\charl\midnight-cardano-bridge'
$scratchRoot = 'C:\Users\charl\.mcb-scratch'
$cloneRoot = 'C:\Users\charl\.mcb-clones'
$controllerEndpoint = '\\.\pipe\MCBBridgeController'
$planningBaseline = (Get-Content -Raw "$repoRoot\program\baselines\pbt-s00-start.json" | ConvertFrom-Json).planning_baseline_commit

$executionResult = & pwsh -NoProfile -File "$repoRoot\scripts\invoke-program-package.ps1" `
  -Action Execute `
  -PackageId PBT-S00-W06 `
  -Plan "$repoRoot\program\plans\public-testnet-livepass-v2.json" `
  -CommandManifest "$repoRoot\program\commands\pbt-s00\pbt-s00-w06.json" `
  -PlanningBaseline $planningBaseline `
  -RepositoryRoot $repoRoot `
  -ControllerEndpoint $controllerEndpoint `
  -ScratchRoot $scratchRoot `
  -CloneRoot $cloneRoot `
  -Remote origin `
  -Branch resolve-checklist-full-sweep | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'package entrypoint failed' }
$executionContextPath = $executionResult.execution_context_path
```

The entrypoint writes a schema-valid execution context containing resolved
attempt, lease, fencing epoch, capability digest and inherited-handle id, run
root, independent clone and Git directory, controller identity, snapshot,
transaction, remote, public credential-handle id, timeouts, commands, and
expected outputs. The broker signs the context; it contains no capability or
credential secret. No step relies on an ambient
`$runRoot` or `$snapshotRoot`. Publication uses the same entrypoint with
`-Action Publish -ExecutionContext $executionContextPath`; all remaining
arguments come from that signed context and are revalidated against the current
fence and remote.

The entrypoint resolves the remote ref inside the leased transaction through
`Invoke-RecordedCommand`, checks exit status and one exact branch ref, and asks
the broker to bind the resulting `CommandRecordV2` digest and observed SHA into
the execution context. An absent, duplicated, malformed, or changed ref stops
the package. No caller-supplied remote SHA is authoritative.

The repeated invocation uses these exact package and manifest pairs:

| Package | Command manifest |
| --- | --- |
| `PBT-S00-W06` | `program/commands/pbt-s00/pbt-s00-w06.json` |
| `PBT-S00-W07` | `program/commands/pbt-s00/pbt-s00-w07.json` |
| `PBT-S00-W08` | `program/commands/pbt-s00/pbt-s00-w08.json` |
| `PBT-S00-W09` | `program/commands/pbt-s00/pbt-s00-w09.json` |
| `PBT-S00-W10` | `program/commands/pbt-s00/pbt-s00-w10.json` |
| `PBT-S00-W11` | `program/commands/pbt-s00/pbt-s00-w11.json` |
| `PBT-S00-W12` | `program/commands/pbt-s00/pbt-s00-w12.json` |
| `PBT-S00-W17` | `program/commands/pbt-s00/pbt-s00-w17.json` |
| `PBT-S00-W18` | `program/commands/pbt-s00/pbt-s00-w18.json` |

Each manifest contains every command id shown in its task, exact argv, working
directory, execution kind, timeout, allowlisted environment, expected outputs,
and failure policy. `program-register.contract.ps1` checks the manifest ids and
timeouts against `ProgramPlanV1`.

Tasks 10 through 18 start by running the self-hosted block with the exact row's
package id and command manifest. The entrypoint, not the operator, runs every
subsequent `Run:` and commit command shown in that task.

### Task 1: `PBT-S00-W01` Preserve the Baseline and Establish the OpenSpec Change

**Files:**
- Create: `.gitattributes`
- Create: `program/baselines/pbt-s00-start.json`
- Create: `program/schemas/program-baseline-precommitment-v1.schema.json`
- Create: `openspec/changes/pbt-s00-program-control-plane/proposal.md`
- Create: `openspec/changes/pbt-s00-program-control-plane/design.md`
- Create: `openspec/changes/pbt-s00-program-control-plane/tasks.md`
- Create: `openspec/changes/pbt-s00-program-control-plane/review.md`
- Create: `openspec/changes/pbt-s00-program-control-plane/specs/operations-governance/spec.md`
- Create: `openspec/changes/pbt-s00-program-control-plane/specs/conformance-testnet/spec.md`
- Create: `scripts/tests/program-baseline.contract.ps1`
- Create: `scripts/assert-cached-paths.ps1`

**Interfaces:**
- `ProgramBaselinePrecommitmentV1` is created and signed outside Git before W01. The W01 bootstrap reads the absolute path from `MCB_PBT_S00_BASELINE_PRECOMMITMENT`, verifies the detached operator signature and freshness, and requires its planning commit, branch, remote, and worktree-status digest to match the independently observed inputs. The repository stores only its digest and verification receipt, never an artifact it could rewrite to authorize itself.
- `program/baselines/pbt-s00-start.json` records the planning baseline commit, design-source commit `3db35fa9a7e7257359f5def4bb216c60356643b8`, historical harness target `78bd432af06c9ef68e006ab2147da68fce29af6d`, branch, remote, capture time, and every porcelain-v2 entry with index/worktree status, byte count, working-byte SHA-256, Git blob id when tracked, content-object id, reconciliation owner, and `adopted=false`.
- Before any package edit, the operator-side W01 bootstrap copies each dirty or untracked regular file as exact bytes into the non-inherited ACL root `C:\Users\charl\.mcb-bootstrap\mcb.public-testnet-livepass.v2\baseline-objects\<sha256>`. W03 imports and byte-verifies those objects into the controller-owned root before the restricted worker identity is enabled. W06, W09, and W12 adopt only from the controller-owned immutable objects after hash comparison; they never recopy a later canonical-worktree value.
- `assert-cached-paths.ps1 -AllowedPath <array>` reads `git diff --cached --name-only -z`, compares exact ordinal path sets, and fails on any missing or extra staged path before commit.
- The OpenSpec task file contains exactly the 18 Sprint 0 package ids and points to this implementation plan.
- The operations spec defines plan authority, append-only reduction, attempts, leases, command supervision, snapshots, repository transactions, bounded agent packets, review immutability, and wiki maintenance.
- The conformance spec defines deterministic text, runlog, `GateRosterV2`, clean-checkout, no-secret, and non-activation behavior.

- [ ] **Step 1: Capture the pre-edit worktree outside Git**

Require the canonical index to contain no staged path after the planning-baseline commit. Resolve the canonical root, record its full SHA, then run `git status --porcelain=v2 -z --untracked-files=all` from that exact root. Hash and classify every regular-file entry, not a predefined path list. Reject a reparse point, unreadable entry, directory-only untracked record, or path that escapes after resolution. Publish exact content objects under the bootstrap ACL root before writing the repository manifest. Known carryovers are assigned to W06 (`runlogs/`), W09 (`docs/grok-4.5-handoff.xml`), and W12 (`README.md`). Any other entry blocks W01 until it receives an explicit owner; nothing is discarded or read later from a mutable source.

Create the implementation worktree with an argument-array Git invocation
equivalent to `git -C <canonical> worktree add --detach <bootstrap-worktree>
<planning-baseline>`. Fail unless the command exits zero, `git rev-parse
--show-toplevel` equals the resolved worktree path, `git rev-parse HEAD` equals
the planning baseline, `git status --porcelain=v2 -z --untracked-files=all` is
empty, and the current working directory is that worktree. Record the command,
resolved paths, Git identity, and cleanup result in W01 scratch evidence.

- [ ] **Step 2: Write the failing baseline contract**

The test must require the external baseline precommitment and reject a missing, self-authored, stale, wrongly signed, or observation-mismatched record. It also requires the baseline manifest, complete porcelain capture, exact reconciliation owners, cached-path guard, and an LF policy for JSON, JSONL, Markdown, XML, PowerShell, Python, Go, Rust, TOML, YAML, CDDL, lock, and hex-vector files. Its RED fixture uses the recorded planning baseline and proves it has no policy. Its GREEN path uses a temporary index containing the new `.gitattributes`, checks `git check-attr`, and proves `git hash-object --path=<path>` produces the intended LF blob without changing the canonical index or worktree.

- [ ] **Step 3: Run the contract and observe RED**

Run:

```powershell
pwsh -NoProfile -File scripts/tests/program-baseline.contract.ps1
```

Expected: nonzero with `baseline manifest missing` or `line-ending policy missing`.

- [ ] **Step 4: Add deterministic attributes and the baseline manifest**

Use `* text=auto`, explicit `eol=lf` rules for the listed text formats, and `-text` only for known binary formats. Build the manifest from the outside capture. Verify each dirty entry against the live bytes before writing. Do not mark any dirty input adopted.

- [ ] **Step 5: Write and validate the OpenSpec change**

The proposal names `operations-governance` and `conformance-testnet`. The two delta specs contain at least one `WHEN`/`THEN` scenario per requirement, including crash, timeout, secret, line-ending, drift, concurrency, review-target, and false-activation rejection. `tasks.md` lists all 18 package ids as unchecked checkboxes with their verification command.

Run:

```powershell
$env:OPENSPEC_TELEMETRY='0'
$env:DO_NOT_TRACK='1'
npm --offline run openspec:validate
```

Expected: all stable specs and `pbt-s00-program-control-plane` validate strictly.

- [ ] **Step 6: Run the baseline contract and observe GREEN**

Run the Step 3 command again.

Expected: the manifest matches the preserved dirty inputs, detached blob bytes reproduce under the policy, and the test removes its worktree and scratch data.

- [ ] **Step 7: Commit only the baseline and specification slice**

```powershell
git add -- .gitattributes program/baselines/pbt-s00-start.json program/schemas/program-baseline-precommitment-v1.schema.json openspec/changes/pbt-s00-program-control-plane scripts/tests/program-baseline.contract.ps1 scripts/assert-cached-paths.ps1
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -AllowedPath .gitattributes,program/baselines/pbt-s00-start.json,program/schemas/program-baseline-precommitment-v1.schema.json,openspec/changes/pbt-s00-program-control-plane/proposal.md,openspec/changes/pbt-s00-program-control-plane/design.md,openspec/changes/pbt-s00-program-control-plane/tasks.md,openspec/changes/pbt-s00-program-control-plane/review.md,openspec/changes/pbt-s00-program-control-plane/specs/operations-governance/spec.md,openspec/changes/pbt-s00-program-control-plane/specs/conformance-testnet/spec.md,scripts/tests/program-baseline.contract.ps1,scripts/assert-cached-paths.ps1
git diff --cached --check
git commit -m "Specify the public testnet program control plane"
```

Expected: the existing README, Grok XML, and runlog changes remain present but unstaged.

- [ ] **Step 8: Verify the committed policy in a clean worktree**

Create a detached worktree at the new Task 1 commit and run the contract with
`-CommittedPolicyCheck`. Compare selected checked-out bytes with their committed
blobs, then remove the worktree. A failure requires a new fix commit; do not
amend or hide the failed result.

### Task 2: `PBT-S00-W02` Define `ProgramPlanV1` and Publish the 106-Package Plan

**Files:**
- Create: `program/schemas/program-plan-v1.schema.json`
- Create: `program/plans/public-testnet-livepass-v2.json`
- Create: `scripts/program/ProgramCommon.psm1`
- Create: `scripts/program/ProgramPlan.psm1`
- Create: `scripts/validate-program-plan.ps1`
- Create: `scripts/tests/program-plan.contract.ps1`
- Create: `scripts/tests/program-register.contract.ps1`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- `Read-ProgramPlan -Path <path>` returns a schema-checked object with a computed canonical SHA-256.
- `Test-ProgramPlan -Plan <object>` returns `{ valid, errors, sprint_count, package_count, topological_order }` and never mutates its input.
- `Write-DeterministicJson -Path <path> -Value <object>` sorts object keys ordinally, preserves array order, writes UTF-8 without BOM plus one LF, and refuses non-finite numbers.
- The plan schema requires program id, outcome classifier, sprint records, package ids, owner roles, packet stage (`discovery|resolved`), full dependency ids with required states, allowed paths, primary artifacts, command ids, command timeouts, expected outputs, gates, retry policy, stop policy, invalidation scopes, and required readers. A separate `external_input_requirements` collection requires authority class, expected object or discovery query when known, allowed endpoints, timeout, verification command id, and unavailable-input policy. Resolved snapshot and receipt bindings belong to the attempt execution context, not this requirement collection.

- [ ] **Step 1: Write failing schema and graph tests**

Cover wrong program id, 13 or 15 sprints, 105 or 107 packages, duplicate package id, id/sprint mismatch, unknown dependency, invalid required dependency state, a cross-sprint dependency weaker than `closed`, dependency cycle, missing artifact, path traversal, empty stop rule, unbounded retry, resolved binding embedded in a discovery requirement, resolved packet without verified discovery receipts, discovery packet containing a non-discovery package, and a package that can emit `live-pass` before `PBT-S13-W05`.

- [ ] **Step 2: Run the tests and observe RED**

Run:

```powershell
pwsh -NoProfile -File scripts/tests/program-plan.contract.ps1
```

Expected: import failure because `ProgramPlan.psm1` and the canonical plan do not exist.

- [ ] **Step 3: Implement deterministic JSON and plan validation**

Perform structural schema checking with `Test-Json`, then semantic checks in `ProgramPlan.psm1`. Use Kahn's algorithm with ordinal package-id ordering for cycle detection and deterministic topological order. Do not infer dependencies from array position.

- [ ] **Step 4: Encode all 14 sprints and 106 packages**

Parse ids, titles, full dependencies, required states, primary artifacts, and exit or stop evidence from `2026-07-10-public-testnet-proof-bridge-program.md`. Give every package explicit packet stage, allowed path prefixes, command ids, timeouts, expected outputs, retry limits, external-wait policy, invalidation scopes, and reader roles. Same-sprint implementation edges may require `implementation-complete`; cross-sprint edges require `closed`. Put non-package prerequisites in `external_input_requirements`; resolved bindings enter only an attempt context. Mark PBT-S02-W01 and PBT-S03-W01 through W05 as bounded discovery packages. Set only `PBT-S00-W01` ready at genesis; all other packages derive readiness from dependencies.

- [ ] **Step 5: Run focused and CLI validation**

```powershell
pwsh -NoProfile -File scripts/tests/program-plan.contract.ps1
pwsh -NoProfile -File scripts/tests/program-register.contract.ps1
pwsh -NoProfile -File scripts/validate-program-plan.ps1 -Plan program/plans/public-testnet-livepass-v2.json
```

Expected: both commands exit zero and report `sprints=14 packages=106 cycles=0` plus the canonical plan digest.

- [ ] **Step 6: Commit the plan slice**

```powershell
git add -- program/schemas/program-plan-v1.schema.json program/plans/public-testnet-livepass-v2.json scripts/program/ProgramCommon.psm1 scripts/program/ProgramPlan.psm1 scripts/validate-program-plan.ps1 scripts/tests/program-plan.contract.ps1 scripts/tests/program-register.contract.ps1 openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W02
git diff --cached --check
git commit -m "Add the canonical bridge program plan"
```

### Task 3: `PBT-S00-W03` Define Append-Only Events and Deterministic State Reduction

**Files:**
- Create: `program/schemas/program-event-v1.schema.json`
- Create: `program/schemas/program-event-segment-v1.schema.json`
- Create: `program/schemas/program-state-v1.schema.json`
- Create: `scripts/program/ProgramEventLog.psm1`
- Create: `scripts/reduce-program-state.ps1`
- Create: `scripts/export-program-journal.ps1`
- Create: `scripts/tests/program-event-log.contract.ps1`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- `Add-ProgramEvent -ControllerRoot <path> -ExpectedHead <digest> -FencingEpoch <integer> -Event <object>` uses `CreateNew`, `Flush(true)`, a write-through atomic rename, post-rename directory durability, and final-byte verification before returning the new head digest. Only the controller broker identity can call it.
- `Read-ProgramEvents -EventRoot <path>` validates immutable object names and bytes, contiguous global sequence, monotonic fencing epoch, unique event id, prior-event digest, and event digest.
- `Export-ProgramJournal -ControllerRoot -RepositoryEventRoot -ExpectedFence` writes a content-addressed immutable segment and deterministic JSONL view through a serialized controller transaction. The view is never treated as history.
- `Reduce-ProgramState -Plan <plan> -Events <events>` returns a schema-valid derived state with package, attempt, lease, command, artifact, review, gate-evaluation, deployment, and classifier views. The gate view is keyed by entry-origin roster digest, entry digest, and entry id and retains the effective evaluation, evidence digest, expiry, supersession, and invalidation history without changing roster bytes.
- Event types cover program initialization and the bounded bootstrap window; package readiness and lease; attempt start, retry, resume, cancel, crash, supersede, external wait, and terminal status; command start and result; artifact publication and invalidation; roster-bound gate evaluation, supersession, expiry, and invalidation; review and finding lifecycle; deployment and classifier facts.

- [ ] **Step 1: Write failing event-history tests**

Build fixtures for a valid initialization and for invalid JSON, unknown field, sequence gap, duplicate id, wrong prior digest, modified object, stale fencing epoch, illegal package transition, checked task without receipt, artifact published before command success, gate evaluation for an unknown roster or entry, duplicate current gate evaluation, gate evidence with the wrong schema or snapshot, expired gate evidence left effective, and `closed` before review. Inject crashes before flush, during every write byte boundary, after file flush but before rename, after write-through rename but before directory durability, and after directory durability. Recovery may delete only uncommitted temporary objects and must never truncate or rewrite a published event.

- [ ] **Step 2: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/program-event-log.contract.ps1
```

Expected: import failure because `ProgramEventLog.psm1` does not exist.

- [ ] **Step 3: Implement the event writer and reducer**

Create one temporary event object with exclusive sharing and `CreateNew`; no API appends to
a published file. Hash canonical event content without `event_sha256`, store
that digest and the prior event digest, call `Flush(true)`, rename with the
qualified platform's write-through primitive, then durably acknowledge the
parent directory and verify the final object. The reducer accepts only the state
transitions fixed in the approved design and emits errors with event id, package
id, prior state, requested state, and violated rule.

- [ ] **Step 4: Run event and reducer contracts**

```powershell
$fixtureRoot = 'C:\Users\charl\.mcb-scratch\pbt-s00-w03-contract'
pwsh -NoProfile -File scripts/tests/program-event-log.contract.ps1 -FixtureRoot $fixtureRoot -KeepFixture
$scratchEventRoot = Join-Path $fixtureRoot 'events'
$scratchStatePath = Join-Path $fixtureRoot 'state.json'
pwsh -NoProfile -File scripts/reduce-program-state.ps1 -Plan program/plans/public-testnet-livepass-v2.json -EventRoot $scratchEventRoot -Check $scratchStatePath
```

Expected: valid history reduces byte-identically on repeated runs; every invalid fixture fails for its named reason.

- [ ] **Step 5: Commit the event slice**

```powershell
git add -- program/schemas/program-event-v1.schema.json program/schemas/program-event-segment-v1.schema.json program/schemas/program-state-v1.schema.json scripts/program/ProgramEventLog.psm1 scripts/reduce-program-state.ps1 scripts/export-program-journal.ps1 scripts/tests/program-event-log.contract.ps1 openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W03
git diff --cached --check
git commit -m "Add append-only program state reduction"
```

### Task 4: `PBT-S00-W13` Implement Privileged Repository and Credential Methods

**Files:**
- Create: `program/schemas/controller-request-v1.schema.json`
- Create: `program/schemas/controller-identity-v1.schema.json`
- Create: `program/schemas/attempt-capability-v1.schema.json`
- Create: `program/schemas/canonical-repository-initialization-v1.schema.json`
- Create: `program/schemas/pack-quarantine-receipt-v1.schema.json`
- Create: `program/schemas/git-credential-handle-v1.schema.json`
- Create: `program/schemas/git-credential-probe-receipt-v1.schema.json`
- Create: `program/schemas/remote-confirmation-receipt-v1.schema.json`
- Create: `program/schemas/remote-confirmation-bundle-v1.schema.json`
- Create: `program/schemas/command-record-v2.schema.json`
- Create: `controller/windows-service/Cargo.toml`
- Create: `controller/windows-service/Cargo.lock`
- Create: `controller/windows-service/src/`
- Create: `scripts/program/ControllerBroker.psm1`
- Create: `scripts/tests/controller-access-boundary.contract.ps1`
- Create: `scripts/tests/controller-privileged-methods.contract.ps1`

W13 compiles the complete privileged interface needed by the frozen Sprint 0
plan: canonical repository seed, full-clone export, bounded pack import,
controller-owned publication, credential provision/probe/lookup/revoke,
noninteractive fetch and push, signing, and remote-confirmation publication.
Every request is typed, size-bounded, capability-bound, fenced, and rooted under
controller-owned paths. The native service has no arbitrary path, executable,
plugin, or script-loading method.

`ControllerIdentityV1` binds an ECDSA P-256 public key, CNG provider,
non-exportable machine-key name, service SID, creation receipt, validity interval,
and rotation predecessor. The private-key ACL admits only the service SID and
`SYSTEM`. Rotation requires a planned event plus old/new cross-signatures. Loss
or unexplained replacement blocks execution.

`AttemptCapabilityV1` binds a random 256-bit capability digest to one attempt,
package, lease, fence, snapshot, method set, expiry, and nonce policy. The broker
passes the secret through a private inherited channel, never argv, environment,
disk, or logs. `Invoke-ControllerRequest` verifies schema, size, connection,
capability, lease, fence, method, snapshot, expiry, and monotonic nonce before
state access. Cross-attempt use and replay reject.

The Rust binary implements each privileged method needed through W18 with a
bounded request in `protocol.rs`, fixed controller-owned roots, and method-level
tests. Its schemas match the Rust wire and persisted types. A later package
cannot extend the privileged interface. A required method, schema, or binary
change invalidates W13, W14, and every dependent attempt.

- [ ] **Step 1: Write failing protocol and access-boundary contracts**

Fixtures reject unknown methods, schema extension, arbitrary paths, hostile
packs, caller-supplied executables, stale fences, wrong snapshots, capability
replay, and direct mutation of canonical or sibling Git storage.

- [ ] **Step 2: Implement and test the native broker methods**

```powershell
cargo test --locked --offline --manifest-path controller/windows-service/Cargo.toml
pwsh -NoProfile -File scripts/tests/controller-privileged-methods.contract.ps1
pwsh -NoProfile -File scripts/tests/controller-access-boundary.contract.ps1
```

- [ ] **Step 3: Commit only W13 sources and contracts**

The cached-path assertion permits only the files listed for W13. Any privileged
interface change after this commit invalidates W13, W14, and dependent attempts.

### Task 5: `PBT-S00-W14` Reproduce, Qualify, and Provision the Controller Build

**Files:**
- Create: `program/schemas/controller-build-receipt-v1.schema.json`
- Create: `program/schemas/controller-build-qualification-v1.schema.json`
- Create: `program/schemas/controller-service-receipt-v1.schema.json`
- Create: `scripts/build-controller-service.ps1`
- Create: `scripts/qualify-controller-build.ps1`
- Create: `scripts/provision-controller-service.ps1`
- Create: `scripts/tests/controller-build.contract.ps1`
- Create: `scripts/tests/controller-service.contract.ps1`

`Build-ControllerService` runs without elevation in two clean full clones at the
committed W13/W14 source. `ControllerBuildReceiptV1` binds the source commit and
tree, manifest and lock blobs, provisioner blob and SHA-256, Rust and Cargo
binaries and versions, target, profile, features, allowlisted environment,
command transcripts, binary bytes, and reproducible equality.

`Qualify-ControllerBuild` verifies both clean-clone outputs, Git blob bytes,
owners, ACLs, binary, and provisioner before writing
`ControllerBuildQualificationV1`. The operator records that complete file's
SHA-256 through an independent channel for the later elevated session.

`Provision-ControllerService` requires the independently supplied qualification
hash and every embedded source, receipt, binary, and provisioner pin. It never
invokes Cargo. It installs the verified content-addressed binary as
`MCBBridgeController` under `NT AUTHORITY\LocalService`, configures the service
SID and recovery actions, applies controller/SYSTEM ownership and DACLs, and
records configuration, identity, hashes, health challenge, and cleanup in
`ControllerServiceReceiptV1`.

- [ ] **Step 1: Write failing reproducibility and provisioning contracts**

Reject dirty or mismatched source commits, changed locks or toolchains,
undeclared build inputs, unequal binaries, unpinned provisioners, incorrect
service ACLs, exportable keys, failed health challenges, and self-elevation.

- [ ] **Step 2: Reproduce and qualify the committed W13 build**

Build in two clean full clones with independent object databases. Compare exact
binary bytes and publish `ControllerBuildReceiptV1` and
`ControllerBuildQualificationV1` under the protected bootstrap root. An operator
carries the qualification file's SHA-256 through an independent channel.

- [ ] **Step 3: Provision and verify the service**

An already elevated PowerShell 7 session verifies the independently carried
qualification digest, source, binary, receipt, and committed provisioner before
installing `MCBBridgeController`. The provisioner never builds and never opens a
UAC prompt. The installed-mode contract verifies service SID, owner, DACL,
non-exportable CNG identity, restart recovery, health signature, and cleanup.

- [ ] **Step 4: Commit W14 and preserve external receipts**

Commit only W14 source and tests. Build, qualification, installation, and health
receipts remain immutable external inputs. W04 cannot start until all four
receipts validate against the committed W13/W14 source.

### Task 6: `PBT-S00-W04` Implement Attempts, Leases, Retry, Recovery, and Resume

**Files:**
- Modify: `scripts/program/ProgramEventLog.psm1`
- Create: `scripts/program/ProgramAttempt.psm1`
- Create: `scripts/new-program-attempt.ps1`
- Create: `scripts/resume-program-attempt.ps1`
- Create: `scripts/tests/program-attempt-recovery.contract.ps1`
- Create: `scripts/tests/fixtures/program-attempt/unknown-submission.json`
- Modify: `program/schemas/program-event-v1.schema.json`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- `Acquire-PackageLease -PackageId -Owner -SnapshotSha256 -AllowedPaths -TtlSeconds -ExpectedHead` returns a unique lease id, UTC expiry, and controller-assigned monotonic fencing epoch.
- `Renew-PackageLease -LeaseId -FencingEpoch -TtlSeconds` and `Release-PackageLease -LeaseId -FencingEpoch` require the current owner and epoch. Renewal loss makes the attempt stale immediately.
- `New-ProgramAttempt -PackageId -LeaseId -Reason initial|retry|crash-recovery|superseding|review-remediation -PriorAttemptId <optional>` returns a unique attempt id.
- `Get-RecoveryAction -State -AttemptId` returns exactly one of `continue`, `reconcile-command`, `reconcile-submission`, `retry-safe`, `wait-external`, or `manual-disposition` with a reason.
- `Assert-CurrentFence` is required at command start and terminal result, artifact publication, signing, external submission, controller integration, and push.
- `Resume-ProgramAttempt` refuses expired, foreign, path-mismatched, snapshot-mismatched, or concurrently advanced leases. Persisted UTC supports restart reconciliation; in-process expiry uses a monotonic clock.

- [ ] **Step 1: Write failing lifecycle tests**

Cover exclusive acquisition, renewal, release, expiry during a child command, renewal loss, wrong owner, stale fencing epoch, wall-clock jump, changed snapshot, changed allowed path set, unique attempt ids, required prior attempt on non-initial runs, retry limit, immutable prior attempt, late command result, late artifact writer, late signer, late push, crash after command start, crash after command result, and external wait with a missing resume receipt.

- [ ] **Step 2: Add unknown-submission tests**

The fixture represents a chain-style command whose request body was persisted but whose terminal response was lost. The expected action is `reconcile-submission`; a second launch is forbidden until a reconciliation event records absent or terminal status for the canonical request id.

- [ ] **Step 3: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/program-attempt-recovery.contract.ps1
```

Expected: import failure because `ProgramAttempt.psm1` does not exist.

- [ ] **Step 4: Implement lifecycle functions as event producers**

Functions may propose events to the fenced controller but may not mutate derived state directly. Use GUID-based ids with package prefixes, UTC timestamps plus an injectable monotonic clock, bounded TTLs, renewal cadence shorter than one third of TTL, and plan-owned retry counts. The supervisor stops the execution boundary on lease loss. Require canonical request digests for commands with non-idempotent effects; after an expiry, reconcile that request before any retry.

- [ ] **Step 5: Run focused and reducer regression tests**

```powershell
pwsh -NoProfile -File scripts/tests/program-attempt-recovery.contract.ps1
pwsh -NoProfile -File scripts/tests/program-event-log.contract.ps1
```

Expected: all recovery branches pass and illegal retry or resume events still fail the reducer.

- [ ] **Step 6: Commit the recovery slice**

```powershell
git add -- scripts/program/ProgramEventLog.psm1 scripts/program/ProgramAttempt.psm1 scripts/new-program-attempt.ps1 scripts/resume-program-attempt.ps1 scripts/tests/program-attempt-recovery.contract.ps1 scripts/tests/fixtures/program-attempt/unknown-submission.json program/schemas/program-event-v1.schema.json openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W04
git diff --cached --check
git commit -m "Add recoverable program attempts and leases"
```

### Task 7: `PBT-S00-W05` Implement the Universal Command Supervisor

**Files:**
- Create: `scripts/program/RecordedCommand.psm1`
- Create: `scripts/program/ExecutionBoundary.psm1`
- Create: `scripts/invoke-recorded-command.ps1`
- Create: `scripts/tests/recorded-command.contract.ps1`
- Create: `scripts/tests/helpers/recorded-command-child.ps1`
- Create: `scripts/tests/helpers/recorded-command-grandchild.ps1`
- Modify: `program/schemas/program-event-v1.schema.json`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- Every W05 PowerShell module is an unprivileged client of the W13 native broker. Event persistence and signing execute only inside the installed content-addressed Rust binary whose hash matches `ControllerBuildReceiptV1`. The service never loads these scripts.
- `Invoke-RecordedCommand -AttemptId -LeaseId -FencingEpoch -CommandId -ExecutionKind host|wsl|docker -Executable -ArgumentList -WorkingDirectory -Environment -TimeoutSeconds -ExpectedOutputs -CapabilityHandle <inherited-handle> -ScratchRoot` returns `CommandRecordV2` only after confirmed boundary termination and a connection-bound broker fence check. It never receives or discovers the controller root, canonical Git directory, public broker endpoint, or capability secret.
- `CommandRecordV1` remains a legacy schema for pre-S00 runlogs. Every new command uses V2. V2 binds lease and fence, execution kind, executable bytes, raw argv, cwd, allowlisted environment, optional source hash, optional target commit and complete input-tree digest for snapshot commands, expected outputs, timestamps, timeout and lease expiry, exit code, exact stdout and stderr byte hashes/counts, host/WSL/container termination result, and final status. When either snapshot-input field is present both are required, the wrapper verifies them before launch and after exit, and a dirty or mismatched tree rejects the record.
- The supervisor publishes stdout, stderr, `CommandRecordV2`, and its terminal event as a recoverable bundle. Each file uses flush plus same-volume atomic rename. A crash after child exit but before the terminal event leaves the start event and quarantined bundle; recovery reconciles the recorded pid/cid, exact captures, fence, and outputs before publishing a `recovered-terminal` event. It never invents a command that was not launched by the wrapper.
- Status is `passed` only when launch succeeds, lease and timeout remain valid, exit code is zero, every required output is reopened without following a reparse point or hardlink swap and matches its contract, and terminal event publication succeeds under the same fence.

- [ ] **Step 1: Write failing process tests**

The helpers support success, nonzero exit, launch failure, separate stdout/stderr, invalid UTF-8, NUL bytes, no final LF, missing output, delayed output, infinite sleep, spawned host grandchild, WSL `setsid` escape, WSL double fork, labeled Docker container, and large bounded streams. Assert the start event exists before the helper observes its launch sentinel. Inject crashes after child exit, after each stream flush, after command-record rename, and before terminal-event rename. Inject timeout and lease expiry into each execution kind and verify no host process, dedicated WSL distro, or labeled container survives.

- [ ] **Step 2: Add provenance and environment negatives**

Reject an unresolved executable, executable hash drift between resolution and launch, secret in argv/cwd/environment, path traversal, output symlink/junction/hardlink swap, full-environment capture, unknown environment key, synthesized post-execution record, duplicate command id, stale fence, source hash not matching invoked bytes, only one of target commit or input-tree digest, dirty snapshot command, target commit or tree drift before launch or after exit, a package token that can write the controller or canonical Git root, shared clone metadata, a capability disclosed in argv/environment/disk/logs, cross-attempt capability use, nonce replay, and any controller path disclosed to a child. Prove stdout and stderr hashes cover exact `BaseStream` bytes without text decoding. Signing commands accept opaque key handles only and consult the current fence before signing.

- [ ] **Step 3: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/recorded-command.contract.ps1
```

Expected: import failure because `RecordedCommand.psm1` does not exist.

- [ ] **Step 4: Implement process execution with .NET**

Use `System.Diagnostics.Process` with argument-list APIs, shell execution disabled, explicit environment, asynchronous `BaseStream` copies, and a finite wait bounded by both command timeout and lease expiry. Put host processes running under the restricted worker token in a Windows Job Object with kill-on-close. Run WSL commands in a dedicated per-attempt distro or equivalent broker-owned cgroup boundary with Windows automount disabled. Copy the snapshot and inputs through a bounded broker pipe into the distro's native filesystem; do not expose any Windows drive. On completion or failure terminate the whole distro and prove no `setsid` or double-fork survivor remains. A process group alone is insufficient. Start containers with only the assigned clone and scratch mounts, plus a controller label and cidfile; never mount controller or canonical Git storage. Stop and kill by cid on failure. Verify all three boundaries are empty before publishing a terminal event. Write raw captures only below `ScratchRoot`; do not publish them yet.

- [ ] **Step 5: Run focused and regression tests**

```powershell
pwsh -NoProfile -File scripts/tests/recorded-command.contract.ps1
pwsh -NoProfile -File scripts/tests/program-attempt-recovery.contract.ps1
pwsh -NoProfile -File scripts/tests/controller-access-boundary.contract.ps1
```

Expected: exact-byte captures reproduce, all command outcomes produce one start and one terminal event, timeout or lease loss removes the selected execution boundary, stale writers reject, and failed commands never emit a success label. A real WSL-native-filesystem detached checkout and a real labeled Docker timeout pass on the qualified local host; lack of either capability blocks S00 rather than silently skipping it.

- [ ] **Step 6: Commit the supervisor implementation without completion evidence**

```powershell
git add -- scripts/program/RecordedCommand.psm1 scripts/program/ExecutionBoundary.psm1 scripts/invoke-recorded-command.ps1 scripts/tests/recorded-command.contract.ps1 scripts/tests/helpers/recorded-command-child.ps1 scripts/tests/helpers/recorded-command-grandchild.ps1 program/schemas/program-event-v1.schema.json openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W05 -Phase implementation
git diff --cached --check
git commit -m "Add supervised package execution"
```

Record this full commit as the supervisor input to W15 and W16. W05 is still
`running` until the bootstrap replay proves it at W16.

### Task 8: `PBT-S00-W15` Implement Transaction and Pack Quarantine

**Files:**
- Create: `program/schemas/repository-transaction-v1.schema.json`
- Create: `scripts/program/RepositoryTransaction.psm1`
- Create: `scripts/program/PackQuarantine.psm1`
- Create: `scripts/start-repository-transaction.ps1`
- Create: `scripts/integrate-repository-transaction.ps1`
- Create: `scripts/tests/repository-transaction-core.contract.ps1`
- Create: `scripts/tests/pack-quarantine.contract.ps1`

`Start-RepositoryTransaction` asks the broker for a full per-attempt clone from
a broker-generated bundle. The clone has its own index, refs, object database,
and reflogs, with no alternates, hardlinks, or shared Git directory.
`Integrate-RepositoryTransaction` verifies the allowlist, parent, tree,
implementation commit, fence, and pack receipt before serialized import.

`Test-QuarantinedPack` receives each worker pack in a fresh no-execute
quarantine. It enforces byte, object-count, expanded-size, blob-size, tree-depth,
delta-depth, and path-count limits; runs strict index and object checks with
replace refs, grafts, alternates, hooks, filters, submodules, and network
protocols disabled; and rejects gitlinks, symlinks, `.git` aliases, Windows
reserved names, alternate data streams, trailing dots or spaces, case-fold and
Unicode-normalization collisions, multiple parents, or paths outside the
package allowlist.

- [ ] **Step 1: Write failing transaction and quarantine contracts**

Require full clones with independent Git storage. Reject alternates, hardlinks,
shared metadata, wrong parents, multiple parents, path escapes, hostile names,
gitlinks, symlinks, hidden refs, replacement objects, oversize or deep deltas,
and any pack whose expanded object set differs from its manifest.

- [ ] **Step 2: Implement broker-mediated transaction policy**

`Start-RepositoryTransaction` obtains a broker-generated bundle and creates an
independent clone. `Integrate-RepositoryTransaction` validates the exact parent,
tree, allowlist, object limits, and implementation commit before the W13 broker
atomically imports the quarantined pack. W08 later adds remote concurrency.

- [ ] **Step 3: Run the focused suite and commit W15**

```powershell
pwsh -NoProfile -File scripts/tests/repository-transaction-core.contract.ps1
pwsh -NoProfile -File scripts/tests/pack-quarantine.contract.ps1
```

### Task 9: `PBT-S00-W16` Close Bootstrap and Publish the Package Entrypoint

**Files:**
- Create: `program/schemas/package-command-manifest-v1.schema.json`
- Create: `program/schemas/package-execution-context-v1.schema.json`
- Create: `program/commands/pbt-s00/pbt-s00-w01.json` through `program/commands/pbt-s00/pbt-s00-w18.json`
- Create: `scripts/invoke-program-package.ps1`
- Create: `scripts/new-canonical-repository-seed.ps1`
- Create: `scripts/initialize-canonical-repository.ps1`
- Create: `scripts/verify-canonical-repository-initialization.ps1`
- Create: `scripts/tests/program-package-entrypoint.contract.ps1`
- Create: `scripts/tests/canonical-repository-initialization.contract.ps1`
- Create: `program/evidence/<bootstrap-package-id>/<attempt-id>/bootstrap-import-v1.json`
- Create: `program/events/public-testnet-livepass-v2/<segment-id>/`
- Create: `program/state/public-testnet-livepass-v2.json`

`New-CanonicalRepositorySeed` runs each Git subprocess through the committed W05
supervisor and records the bundle, `bundle verify`, head, object-list, and
`cat-file` commands. It returns a deterministic object manifest and exact command
records. The broker receives byte streams and never traverses the user's source
repository.

`Initialize-CanonicalRepository` is a one-shot administrative request.
`CanonicalRepositoryInitializationV1` binds the planning baseline, complete
bootstrap lineage through W16, branch, normalized remote, bundle digest, Git
binary, object inventory, seed command records, service identity, and resulting
broker roots. A repeated initialization, missing ancestor, hidden ref,
replacement or shallow metadata, alternate object store, wrong tree, or remote
mismatch rejects.

`invoke-program-package.ps1` implements `Initialize`, `BootstrapReplay`,
`Execute`, `Reconcile`, and `Publish`. `Execute` creates the attempt, lease,
private capability channel, independent clone, scratch, and run roots; invokes
only plan-authorized manifests through W05; verifies outputs; commits the exact
allowlist; and submits the pack and immutable event segment through W15 and the
broker. `Publish` accepts the signed execution context and no ambient path,
branch, credential, or remote value.

- [ ] **Step 1: Write the failing entrypoint and initialization contracts**

Reject ambient controller paths, unknown packages, manifests outside the plan,
shared Git storage, mutable source bindings, repeated canonical initialization,
wrong lineage, hidden refs, incomplete object inventories, and bootstrap imports
outside W01-W05 or W13-W16.

- [ ] **Step 2: Implement the package entrypoint and all 18 manifests**

`invoke-program-package.ps1` implements `Initialize`, `BootstrapReplay`,
`Execute`, `Reconcile`, and `Publish`. It accepts only a signed execution context
and inherited capability handle, delegates every child command to W05, and every
repository mutation to W15 and the W13 broker.

- [ ] **Step 3: Commit the W16 implementation without closure evidence**

The W16 commit contains the entrypoint, schemas, manifests, initialization
tools, and contracts. Bootstrap receipts, events, and derived state are a later
control transaction and are not fabricated in the implementation commit.

- [ ] **Step 4: Replay and close the bootstrap window from the committed entrypoint**

Install or verify the canonical broker. Before it can generate a worker bundle,
seed its empty canonical Git store through the one-shot administrative channel.
The operator resolves the committed W16 implementation commit, tree, branch,
normalized remote, and planning-baseline manifest from the source repository,
creates a full Git bundle containing the planning baseline through W16, verifies
it locally, and writes a deterministic manifest with every reachable object id,
type, and size. `initialize-canonical-repository.ps1` opens the bundle and
manifest as byte streams and sends them through the authenticated admin pipe;
the service never opens or traverses the source repository or caller path. The
broker creates a fresh quarantine, applies all initialization and object limits,
verifies the exact lineage and refs, seeds its bare repository and integration
clone, and returns a signed `CanonicalRepositoryInitializationV1`. The operator
verifies the receipt against the committed source values. A one-shot state bit
and content digest make repeated or altered initialization illegal.

Only after that receipt passes may `BootstrapReplay` ask the broker for a bundle
at the W16 implementation commit and create a unique full clone. The entrypoint
verifies resolved source root, clone root, independent Git directory and object
database, no alternates or hardlinks, exact HEAD, empty porcelain status with
`--untracked-files=all`, restricted worker identity, broker endpoint, and cwd
before launching a child. Use the supervisor to initialize the canonical
external journal and rerun every W01-W05 and W13-W16 verification command. Write nine
package-scoped import receipts containing the original package commit,
cumulative replay commit, allowed paths, command-record hashes, and test-result
hashes. Export the immutable bootstrap event segment, append
`bootstrap-window-closed`, and regenerate state through the broker. Always
record verified clone removal. Mutation tests reject a changed receipt, wrong
target commit, a tenth package, a second import, any later bootstrap event, or a
replay child running from the canonical checkout.

The caller's `$implementationCommit` is only a candidate. `BootstrapReplay`
resolves the source repository's W16 HEAD through a recorded supervisor command,
requires equality before clone creation, and binds that command record into
all nine receipts.

```powershell
$sourceRoot = 'C:\Users\charl\midnight-cardano-bridge'
$branch = 'resolve-checklist-full-sweep'
$remote = 'https://github.com/CharlesHoskinson/midnight-cardano-bridge.git'
$implementationCommit = (git -C $sourceRoot rev-parse "$branch^{commit}").Trim()
$implementationTree = (git -C $sourceRoot rev-parse "$implementationCommit^{tree}").Trim()
$seedRoot = 'C:\Users\charl\.mcb-bootstrap\mcb.public-testnet-livepass.v2\canonical-seed'
$seedResult = pwsh -NoProfile -File scripts/new-canonical-repository-seed.ps1 `
  -ControllerEndpoint '\\.\pipe\MCBBridgeController.Admin' `
  -RepositoryRoot $sourceRoot `
  -PlanningBaseline program/baselines/pbt-s00-start.json `
  -ExpectedCommit $implementationCommit `
  -ExpectedTree $implementationTree `
  -Branch $branch `
  -Remote $remote `
  -OutputRoot $seedRoot | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'canonical seed creation failed' }
$initializationReceipt = pwsh -NoProfile -File scripts/initialize-canonical-repository.ps1 `
  -ControllerEndpoint '\\.\pipe\MCBBridgeController.Admin' `
  -Bundle $seedResult.bundle_path `
  -Manifest $seedResult.manifest_path `
  -SeedCommandRecord $seedResult.command_record_paths | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'canonical repository initialization failed' }
pwsh -NoProfile -File scripts/verify-canonical-repository-initialization.ps1 `
  -Receipt $initializationReceipt.receipt_path `
  -Manifest $seedResult.manifest_path `
  -ExpectedCommit $implementationCommit `
  -ExpectedTree $implementationTree `
  -ExpectedBranch $branch `
  -ExpectedRemote $remote
if ($LASTEXITCODE -ne 0) { throw 'canonical repository initialization receipt failed' }
$bootstrapResult = pwsh -NoProfile -File scripts/invoke-program-package.ps1 `
  -Action BootstrapReplay `
  -PackageId PBT-S00-W16 `
  -BootstrapPackageId PBT-S00-W01,PBT-S00-W02,PBT-S00-W03,PBT-S00-W04,PBT-S00-W05,PBT-S00-W13,PBT-S00-W14,PBT-S00-W15,PBT-S00-W16 `
  -ImplementationCommit $implementationCommit `
  -Plan program/plans/public-testnet-livepass-v2.json `
  -RepositoryRoot 'C:\Users\charl\midnight-cardano-bridge' `
  -ControllerEndpoint '\\.\pipe\MCBBridgeController' `
  -ScratchRoot 'C:\Users\charl\.mcb-scratch' `
  -CloneRoot 'C:\Users\charl\.mcb-clones' | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'bootstrap replay failed' }
$executionContextPath = $bootstrapResult.execution_context_path
```

- [ ] **Step 5: Commit the separate bootstrap evidence control transaction**

```powershell
pwsh -NoProfile -File scripts/invoke-program-package.ps1 `
  -Action Reconcile `
  -ExecutionContext $executionContextPath `
  -Phase bootstrap-evidence
```

Expected: the broker verifies the signed replay context, stages exactly the nine
package evidence roots plus the event segment, state, and task receipt in its
integration clone, commits them, and returns the integration commit. Raw `git
add` or `git commit` from the bootstrap worker is a required rejection fixture.

### Task 10: `PBT-S00-W06` Validate Runlogs, Inventories, and Redaction

**Files:**
- Modify: `runlogs/README.md`
- Modify: `runlogs/schemas/run-inventory-v1.schema.json`
- Modify: `runlogs/schemas/run-event-v1.schema.json`
- Modify: `runlogs/schemas/grok-run-manifest-v1.schema.json`
- Create: `runlogs/schemas/run-event-v2.schema.json`
- Create: `runlogs/schemas/program-run-manifest-v1.schema.json`
- Create: `runlogs/schemas/redaction-receipt-v1.schema.json`
- Create: `runlogs/security/secret-patterns-v1.json`
- Create: `scripts/program/RunlogValidation.psm1`
- Create: `scripts/validate-grok-runlog.ps1`
- Create: `scripts/scan-committable-artifacts.ps1`
- Create: `scripts/tests/validate-grok-runlog.contract.ps1`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- `Test-Runlog -RunPath -RepositoryRoot -SnapshotId -RequireTerminal` validates schemas plus every cross-file invariant and returns structured findings. V1 events and `CommandRecordV1` are accepted only for baseline-listed legacy runs; new runs require immutable V2 event objects, a derived JSONL view, and `CommandRecordV2`.
- `Invoke-ArtifactSecretScan -Paths -Ruleset -OutputPath` writes a deterministic receipt with scanner hash, ruleset hash, normalized path, byte hash, rule id, and redacted location. It never echoes a matching secret value.
- `Publish-ScannedCapture -Source -Destination -Receipt` requires zero matches, path containment, a matching source hash, and a destination listed in the attempt inventory.
- Inventory includes every regular run file except `manifest.json` and `inventory.json`, sorted by ordinal relative path, with exact byte count and SHA-256. The event-object directory is history; `events.jsonl` must reproduce from it exactly.

- [ ] **Step 1: Preserve the partial runlog files in the baseline**

Before editing, rerun the Task 1 manifest check. Materialize all inventoried `runlogs/` files from their content-addressed baseline objects into the W06 clone and verify byte counts and hashes. Mark them adopted only in a new program event after this task passes; do not alter the immutable baseline manifest or consult later canonical-worktree bytes.

- [ ] **Step 2: Write schema-valid cross-file negatives**

Generate isolated fixtures for escaped paths, missing files, wrong bytes or hashes, incomplete or duplicate inventory entries, torn event temporary, modified published event, derived JSONL mismatch, duplicate command id, command without one start and one end event, stream mismatch, duplicate council role, wrong review snapshot, nonexistent Git object, fake Codex thread id, failed terminal verification, forbidden environment key, secret in argv/cwd/environment/stream, planted test token, missing redaction receipt, nonzero secret match, event gap, stale fence, and missing final event.

- [ ] **Step 3: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/validate-grok-runlog.contract.ps1
```

Expected: the existing schema-only checks accept at least one cross-file-invalid fixture, causing the contract to fail.

- [ ] **Step 4: Implement containment, inventory, event, review, and redaction checks**

Resolve every path from a final opened handle and require it to remain below the run root without a reparse or hardlink escape. Validate Git objects with `git cat-file -e`. Rebuild the JSONL view from immutable event objects and compare bytes. Parse preserved Codex JSONL line by line and require exactly one real `thread.started` id equal to the manifest. Require exact review roles declared by the sprint snapshot; do not hard-code three when security is required. Scan every committable run artifact independently, including structured command fields and raw byte captures.

- [ ] **Step 5: Run all runlog and supervisor tests**

```powershell
pwsh -NoProfile -File scripts/tests/validate-grok-runlog.contract.ps1
pwsh -NoProfile -File scripts/tests/recorded-command.contract.ps1
```

Expected: complete running, blocked, and sealed fixtures pass; each negative fixture fails for its intended invariant; no planted value appears in test output.

- [ ] **Step 6: Commit the adopted runlog slice**

```powershell
git add -- runlogs/README.md runlogs/schemas runlogs/security scripts/program/RunlogValidation.psm1 scripts/validate-grok-runlog.ps1 scripts/scan-committable-artifacts.ps1 scripts/tests/validate-grok-runlog.contract.ps1 openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W06
git diff --cached --check
git commit -m "Add validated agent runlogs and redaction"
```

Expected: `runlogs/` is now tracked; no run instance is sealed by this task.

### Task 11: `PBT-S00-W07` Define Program Snapshots and Scoped Invalidation

**Files:**
- Create: `program/schemas/program-snapshot-v1.schema.json`
- Create: `program/schemas/invalidation-receipt-v1.schema.json`
- Create: `scripts/program/ProgramSnapshot.psm1`
- Create: `scripts/new-program-snapshot.ps1`
- Create: `scripts/compare-program-snapshot.ps1`
- Create: `scripts/tests/program-snapshot.contract.ps1`
- Modify: `program/schemas/program-event-v1.schema.json`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- `New-ProgramSnapshot -Plan -State -Commit -ActiveChange -RepositoryRoot -OutputPath -CredentialHandleReceipt <optional> -CredentialProbeReceipt <optional>` binds implementation commit, plan and packet digests, stable and active OpenSpec inputs, source receipts, wiki graph head and synthesis digest, controller service binary and `ControllerIdentityV1` public-key digest, toolchain, host, network, proof, setup, registry, ABI, deployment artifacts, and public evidence prefix. A publication snapshot also binds the immutable public credential-handle id and receipt digest, normalized remote and branch, provider hash, service SID, scopes, expiry, effective credential-lifecycle event head and revocation result, and one immutable review-time `GitCredentialProbeReceiptV1` digest. It never binds a capability secret or credential secret. Later pre-fetch and pre-sign probes are distinct append-only receipts in the external remote-confirmation bundle and do not mutate the snapshot or handle.
- `Compare-ProgramSnapshot -Before -After -ScopeMap` returns changed fields, affected reader scopes, invalidated packages, invalidated artifacts, and earliest re-entry package.
- Repository file entries contain Git object id, byte count, and SHA-256 over `git cat-file blob` bytes at the named commit.

- [ ] **Step 1: Write failing snapshot tests**

Cover deterministic ordering, missing committed object, dirty-only file, CRLF checkout, changed plan, active spec, stable spec, source receipt, wiki event, toolchain, credential-handle receipt, provider hash, credential expiry or revocation, network identity, circuit, setup, registry, ABI, deployment, public receipt, and review-only file.

- [ ] **Step 2: Define expected invalidation boundaries**

Assert the byte-identical `re-entry-contract:v2` table above. No prose rule may add, remove, or narrow one of its drift classes. A runlog prose correction does not stale proof evidence unless it changes a declared behavioral input. Attestation-only closure artifacts are handled by `ClosureEnvelopeV1`; anything else creates a new snapshot.

- [ ] **Step 3: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/program-snapshot.contract.ps1
```

Expected: import failure because `ProgramSnapshot.psm1` does not exist.

- [ ] **Step 4: Implement committed-blob snapshots and scope comparison**

Reject a snapshot if any declared input is absent from the target commit. Normalize logical paths but never rewrite source bytes. Compute the snapshot id from deterministic JSON without the `snapshot_sha256` field, then store and revalidate the digest.

- [ ] **Step 5: Run snapshot, plan, and event tests**

```powershell
pwsh -NoProfile -File scripts/tests/program-snapshot.contract.ps1
pwsh -NoProfile -File scripts/tests/program-plan.contract.ps1
pwsh -NoProfile -File scripts/tests/program-event-log.contract.ps1
```

Expected: all drift and invalidation cases produce their exact scope and earliest owner.

- [ ] **Step 6: Commit the snapshot slice**

```powershell
git add -- program/schemas/program-snapshot-v1.schema.json program/schemas/invalidation-receipt-v1.schema.json scripts/program/ProgramSnapshot.psm1 scripts/new-program-snapshot.ps1 scripts/compare-program-snapshot.ps1 scripts/tests/program-snapshot.contract.ps1 program/schemas/program-event-v1.schema.json openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W07
git diff --cached --check
git commit -m "Add snapshot-bound program invalidation"
```

### Task 12: `PBT-S00-W08` Harden Repository Integration and Remote Publication

**Files:**
- Create: `scripts/program/RepositoryLease.psm1`
- Create: `scripts/publish-repository-transaction.ps1`
- Create: `scripts/verify-remote-confirmation.ps1`
- Create: `scripts/provision-git-credential.ps1`
- Create: `scripts/tests/repository-lease.contract.ps1`
- Create: `scripts/tests/git-credential-boundary.contract.ps1`
- Create: `scripts/tests/remote-confirmation-publication.contract.ps1`
- Modify: `program/schemas/program-event-v1.schema.json`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- Every W08 PowerShell script is an unprivileged client and policy validator. Credential vault access, Git credential-helper responses, remote Git subprocesses under the service identity, receipt signing, and atomic confirmation-bundle publication execute only in the unchanged W13 Rust binary. W08 begins by verifying the installed binary, source commit, and service receipt; mismatch invalidates W13 and W14 rather than installing client code into the service.
- `Test-RepositoryTransaction` hardens the W05 core by rejecting untracked or modified paths outside the package allowlist, symlinks or junctions escaping the clone, shared Git directories, alternates, hardlinked objects, missing expected artifacts, stale lease, changed base or snapshot, and any restricted-worker access to the controller or canonical Git roots.
- `Integrate-RepositoryTransaction -ExecutionContext -ImplementationCommit -EventSegment` runs only through the broker, verifies the current fence, serializes one accepted implementation commit and immutable segment, regenerates state, and records both source and integration commit ids. Concurrent package results integrate one at a time; a losing result never rebases or rewrites its event segment.
- `GitCredentialHandleV1` is immutable. It contains only a handle id, normalized HTTPS remote and branch allowlist, provider executable and hash, service SID, scopes, creation time, expiry, and creation-event digest. It embeds neither a probe nor mutable revocation state. The current active or revoked result is reduced from append-only controller lifecycle events. The secret lives in the provider's service-account-protected vault. `provision-git-credential.ps1` reads it with `Read-Host -AsSecureString`, passes it over the authenticated operator-to-service channel, and emits only the public handle. Unattended execution without a qualified handle records `waiting-external`.
- `GitCredentialProbeReceiptV1` is a separate immutable, content-addressed object. It binds a unique probe id, handle-receipt digest, purpose `review|pre-fetch|pre-sign`, remote and branch, provider hash, service SID, required scopes, expiry, effective lifecycle-event head and revocation result, challenge nonce, observation time, result, controller identity, and signature. A probe always writes a new `-OutputReceipt`; it never rewrites the handle or an earlier probe.
- `Publish-RepositoryTransaction -ExecutionContext -CredentialHandle <id>` sets `GIT_TERMINAL_PROMPT=0`, `GCM_INTERACTIVE=Never`, and an explicit broker credential helper. It performs its pre-push fetch through `Invoke-RecordedCommand`, requires exact remote, credential, and fence equality, rejects merge or force behavior, pushes normally, fetches again through the supervisor, and requires the branch to equal the context's integration commit. The helper answers only for the handle's allowlisted normalized remote and is excluded from command stream capture.
- `RemoteConfirmationBundleV1` lives externally at `<controller-root>/remote-confirmations/<program-id>/<sprint-id>/<envelope-sha256>/<receipt-id>/`. It contains command directories for `pre-fetch`, ordered `push-0001` and optional recovery `push-0002`, and `post-fetch`; each directory contains `record.json`, exact `stdout.bin`, exact `stderr.bin`, and `stream-manifest.json`. It also contains the signed `receipt.json`, snapshot-bound `controller-identity.json`, immutable public `credential-handle.json`, `credential-probes/review.json`, `credential-probes/pre-fetch.json`, `credential-probes/pre-sign.json`, and `bundle-manifest.json`. The manifest inventories and hashes every payload member except itself and `receipt.json`. The receipt binds schema version, receipt id, creation time, program and sprint ids, envelope digest, normalized remote and branch, fencing epoch, credential-handle receipt digest, snapshot-bound review-probe digest, ordered review, pre-fetch, and pre-sign probe digests, expected pre-push SHA, pushed SHA, observed post-fetch SHA, the ordered command ids and record digests, every raw-stream digest and byte count, identity digest, bundle-manifest digest, `ecdsa-p256-sha256-p1363`, fixed-width signature, and receipt digest. Signature input is canonical receipt JSON with `signature` and `receipt_sha256` omitted. `receipt_sha256` hashes canonical receipt JSON after inserting the fixed-width signature and omitting only `receipt_sha256`.
- The broker builds the bundle in a unique sibling directory on the destination volume. Every file is opened with `CreateNew`, written, flushed, reopened, and hash-checked. The broker secret-scans all records and stream bytes, signs the receipt, verifies the complete bundle against its schema and manifest, flushes the temporary directory, then publishes it with one same-volume non-replacing directory rename using write-through semantics. It reopens and verifies the published directory before appending `remote-confirmed`. Recovery deletes or quarantines an unpublished temporary directory; it never treats partial bytes as a receipt.
- `verify-remote-confirmation.ps1` validates exact directory membership, every bundle object, the pre-fetch, ordered one or two push attempts, post-fetch, all raw streams and manifests, canonical signed bytes, identity trust anchor, immutable public credential-handle receipt, all three append-only probes and their purposes, review-probe snapshot binding, path, digest, fence, remote and branch, exact SHA equality, and predecessor envelope. Before each package lease, the controller derives the cumulative transitive set of cross-sprint dependencies required at `[closed]` by that package's current discovery or resolved packet. It copies each required but not yet imported predecessor bundle byte-for-byte into `program/remote-confirmations/<predecessor-sprint>/<receipt-id>/` and emits one `remote-confirmation-imported` event per predecessor. Imports are monotonic. The reducer requires the imported set to equal the package's cumulative required set, with no missing or unapproved bundle, and rejects the lease until every import passes. This lets early S03 discovery depend only on S01 while making the later S03 admission packages hold both the already imported S01 bundle and the newly required S02 bundle.

- [ ] **Step 1: Write failing local-remote tests**

Create a temporary source repository, ACL-protected controller integration clone, two restricted-worker full clones from one snapshot, and local bare remote. Test deterministic serialized integration of both immutable segments, independent object databases, clean publish, recorded remote resolution, absent or duplicate ref, dirty clone, package attempts to edit canonical refs, indexes, objects, reflogs, journal, or sibling clones, duplicate global sequence proposal, out-of-scope change, untracked secret-like file, stale fence, stale expected remote, concurrent second commit, non-fast-forward history, expired lease, wrong owner, and remote SHA mismatch after a fake push wrapper. Bundle fixtures reject wrong envelope, path, remote, branch, fence, credential handle, review probe, publication probe purpose or digest, expected SHA, pushed SHA, observed SHA, any missing, extra, reordered, or altered command record, raw stream, or stream manifest, identity mismatch, noncanonical signed bytes, bad signature, duplicate publication, a missing transitive predecessor, incomplete staged S03 imports, an incomplete join-sprint predecessor set, an unapproved extra predecessor, successor lease before complete import, and changed bytes during import.

Inject a crash before and after every bundle file write and flush, the secret scan, receipt signing, bundle self-verification, directory flush, atomic rename, published-directory durability check, and `remote-confirmed` event. Simulate a lost push response with the remote at the expected old SHA, the pushed SHA, and an unrelated SHA. If the remote already names the pushed SHA, recovery completes the bundle from immutable command captures without another push. If it remains at the expected old SHA, policy may authorize one recorded retry of the exact normal push under the unchanged fence and credential handle. The bundle then carries both ordered push command records and streams, including the first record's `unknown-submission` state. Any other SHA cancels the attempt. Recovery never blindly repeats a push.

Credential fixtures use a fake provider and a disposable real provider profile.
They cover success without a prompt, absent handle, wrong service SID, wrong
remote, insufficient scope, expiry, revocation before fetch, revocation between
fetch and push, helper prompt, provider hash drift, and secret canaries in argv,
environment, stdout, stderr, command records, receipts, and Git trace output.

- [ ] **Step 2: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/repository-lease.contract.ps1
```

Expected: import failure because `RepositoryLease.psm1` does not exist.

- [ ] **Step 3: Provision and qualify the noninteractive Git credential**

Run the operator command from an administrative shell that can reach the private
controller provisioning channel. The script prompts once with
`Read-Host -AsSecureString`; the secret is sent only over that authenticated
channel and is stored in the service identity's protected provider vault. The
receipt path contains public metadata only.

```powershell
$provider = (Get-Command git-credential-manager.exe -ErrorAction Stop).Source
$expiresAt = (Get-Date).ToUniversalTime().AddHours(8).ToString('o')
$credentialReceipt = 'C:\Users\charl\.mcb-bootstrap\mcb.public-testnet-livepass.v2\git-credential-handle-v1.json'
$reviewProbeReceipt = 'C:\Users\charl\.mcb-bootstrap\mcb.public-testnet-livepass.v2\git-credential-probe-review-v1.json'
pwsh -NoProfile -File scripts/provision-git-credential.ps1 `
  -Action Provision `
  -ControllerEndpoint '\\.\pipe\MCBBridgeController.Admin' `
  -Provider $provider `
  -Remote 'https://github.com/CharlesHoskinson/midnight-cardano-bridge.git' `
  -Branch 'resolve-checklist-full-sweep' `
  -Scopes 'contents:write' `
  -ExpiresAt $expiresAt `
  -Receipt $credentialReceipt
pwsh -NoProfile -File scripts/provision-git-credential.ps1 `
  -Action Probe `
  -ControllerEndpoint '\\.\pipe\MCBBridgeController.Admin' `
  -HandleReceipt $credentialReceipt `
  -Purpose review `
  -ExpectedRemote 'https://github.com/CharlesHoskinson/midnight-cardano-bridge.git' `
  -ExpectedBranch 'resolve-checklist-full-sweep' `
  -OutputReceipt $reviewProbeReceipt
```

The review probe runs a noninteractive read through the provider and service
identity, then signs a new public receipt. W08 stays `waiting-external` until the
immutable handle, provider hash, scope, expiry, reduced revocation state, and
review-probe receipt pass. W12 builds a fresh `ProgramSnapshotV1` and execution
context that bind both receipt digests. Publication copies that exact review
receipt into the bundle, creates another immutable probe immediately before
pre-push fetch, and creates a third immediately before signing. None of the
probes changes the snapshot or handle.

- [ ] **Step 4: Harden integration and implement recorded publication**

Extend the W05 core using argument arrays for every Git call. Resolve and verify
every clone and scratch path before cleanup. Resolve the authoritative remote
SHA only through a supervised probe inside the leased execution context. Do not
use force push, hard reset, or checkout-based reversion. A concurrent remote
advance emits cancellation and reconciliation events. Require a live
`GitCredentialHandleV1` and a new purpose-bound probe receipt before the first
remote command and again before signing. A push whose response is lost enters
`unknown-submission`; only a
recorded read-only fetch may classify it. The recovery cases and single
policy-authorized retry are exactly those in Step 1. Publish and verify
`RemoteConfirmationBundleV1` only after the post-push fetch succeeds. Build it
in a same-volume temporary directory, publish it with one non-replacing durable
rename, verify the final directory, and append the event last.

- [ ] **Step 5: Run repository and recovery suites**

```powershell
pwsh -NoProfile -File scripts/tests/repository-lease.contract.ps1
pwsh -NoProfile -File scripts/tests/git-credential-boundary.contract.ps1
pwsh -NoProfile -File scripts/tests/remote-confirmation-publication.contract.ps1
pwsh -NoProfile -File scripts/tests/program-attempt-recovery.contract.ps1
```

Expected: the normal local publish passes, every crash boundary recovers without a partial receipt or blind repush, and all concurrency, containment, credential, predecessor-set, and stale-state fixtures reject.

- [ ] **Step 6: Commit the transaction slice**

```powershell
git add -- scripts/program/RepositoryLease.psm1 scripts/publish-repository-transaction.ps1 scripts/verify-remote-confirmation.ps1 scripts/provision-git-credential.ps1 scripts/tests/repository-lease.contract.ps1 scripts/tests/git-credential-boundary.contract.ps1 scripts/tests/remote-confirmation-publication.contract.ps1 program/schemas/program-event-v1.schema.json openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W08
git diff --cached --check
git commit -m "Add leased repository transactions"
```

### Task 13: `PBT-S00-W09` Compile Bounded Grok Packets and Environment Receipts

**Files:**
- Modify: `docs/grok-4.5-handoff.xml`
- Create: `program/templates/grok-sprint-packet-v1.xml`
- Create: `program/schemas/grok-sprint-packet-v1.xsd`
- Create: `program/schemas/environment-receipt-v1.schema.json`
- Create: `scripts/program/SprintPacket.psm1`
- Create: `scripts/new-sprint-packet.ps1`
- Create: `scripts/get-program-environment.ps1`
- Create: `scripts/tests/sprint-packet.contract.ps1`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- `Get-ProgramEnvironment -RepositoryRoot -ControllerEndpoint -ScratchRoot` records public host and tool facts only: OS, shell, architecture, Git, GitHub CLI, Node, npm, OpenSpec, Python, Scrapling, Rust, Go, Grok, Codex, WSL, Docker, qualified chain tools, writable-root probes, network probe summaries, and executable hashes. It probes `TEMP`, `TMP`, `CODEX_HOME`, `HOME`, `USERPROFILE`, `APPDATA`, `LOCALAPPDATA`, `RUSTUP_HOME`, `CARGO_HOME`, `GOMODCACHE`, `GOCACHE`, `GOTMPDIR`, npm cache, XDG roots, WSL home/cache, and Docker storage without recording secret values or exposing the controller root.
- `New-SprintPacket -SprintId -Stage discovery|resolved -Plan -Snapshot -Environment -ResolvedInputReceipt <array> -OutputPath` emits XSD-valid XML containing only the packages allowed in that stage, allowed paths/endpoints, immutable input requirements, verified resolved bindings when the stage is `resolved`, required skills, command-supervisor entrypoint, stop rules, review contract, and final response schema. Discovery packets cannot claim resolved receipts; resolved packets cannot omit them.
- The packet fixes Grok model `grok-4.5`, reasoning effort `high`, and full permission mode only after the environment probe confirms the installed CLI syntax. Full permission applies inside the restricted worker boundary and does not grant access to controller or canonical Git storage. The packet contains the capability-bound command-shim path but not the administrative broker endpoint, capability value, or launcher invocation. It directs all commands through `invoke-recorded-command.ps1`.
- The packet gives Grok one communication path to Codex: the detached audit runner whose path is fixed here and whose behavior is validated in Task 14. It does not permit direct mutation by the auditor.

- [ ] **Step 1: Preserve and classify the current Grok XML**

Materialize the XML from its Task 1 content object and verify its baseline entry. Extract reusable host, runlog, review, and non-claim rules. Do not read later canonical-worktree bytes or carry Sprint 2 remediation packages into the new controller bootstrap.

- [ ] **Step 2: Write failing packet tests**

Reject an unknown sprint, unclosed predecessor, snapshot mismatch, extra package, missing allowed path, missing timeout, direct shell command bypass, any child command outside the capability-bound command shim, administrative endpoint or launcher disclosure, direct unrecorded Codex call, mutable review directory, mainnet text in an allowed network field, secret-bearing environment, unsupported CLI flag, absent writable-root probe, stale tool receipt, controller-root disclosure, or a package worker that can bypass the broker ACL.

- [ ] **Step 3: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/sprint-packet.contract.ps1
```

Expected: import failure because `SprintPacket.psm1` does not exist.

- [ ] **Step 4: Implement environment probing and packet compilation**

Probe tools with the recorded-command supervisor and finite timeouts. Record only version, resolved path, executable hash, status, and public capability result. Render XML with .NET XML APIs, validate it against the XSD, parse it back, and compare every package and digest to the plan and snapshot.

- [ ] **Step 5: Replace the monolithic handoff with the controller bootstrap**

`docs/grok-4.5-handoff.xml` becomes a checked bootstrap for `PBT-S00`; it points to the canonical plan, current snapshot, packet compiler, supervisor, runlog validator, and audit runner. It keeps the useful system-card citations and records that versions and CLI flags must be re-probed rather than trusted from the document.

- [ ] **Step 6: Run packet and secret tests**

```powershell
pwsh -NoProfile -File scripts/tests/sprint-packet.contract.ps1
pwsh -NoProfile -File scripts/scan-committable-artifacts.ps1 -Paths docs/grok-4.5-handoff.xml,program/templates/grok-sprint-packet-v1.xml -Ruleset runlogs/security/secret-patterns-v1.json -OutputPath "C:\Users\charl\.mcb-scratch\pbt-s00-packet-scan.json"
```

Expected: the canonical `PBT-S00` packet validates, all negative packets reject, and the scan reports zero matches.

- [ ] **Step 7: Commit the packet slice**

```powershell
git add -- docs/grok-4.5-handoff.xml program/templates/grok-sprint-packet-v1.xml program/schemas/grok-sprint-packet-v1.xsd program/schemas/environment-receipt-v1.schema.json scripts/program/SprintPacket.psm1 scripts/new-sprint-packet.ps1 scripts/get-program-environment.ps1 scripts/tests/sprint-packet.contract.ps1 openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W09
git diff --cached --check
git commit -m "Add snapshot-bound sprint packet generation"
```

### Task 14: `PBT-S00-W10` Run Isolated Codex Audits and Persona Councils

**Files:**
- Create: `program/schemas/review-request-v1.schema.json`
- Create: `program/schemas/review-result-v1.schema.json`
- Create: `program/schemas/closure-envelope-v1.schema.json`
- Create: `program/reviewers/proof-reader-v1.json`
- Create: `program/reviewers/consensus-reader-v1.json`
- Create: `program/reviewers/operator-reader-v1.json`
- Create: `program/reviewers/security-reader-v1.json`
- Create: `program/templates/reviews/proof-reader-v1.md`
- Create: `program/templates/reviews/consensus-reader-v1.md`
- Create: `program/templates/reviews/operator-reader-v1.md`
- Create: `program/templates/reviews/security-reader-v1.md`
- Create: `scripts/program/ProgramReview.psm1`
- Create: `scripts/invoke-codex-audit.ps1`
- Create: `scripts/invoke-program-council.ps1`
- Create: `scripts/validate-closure-envelope.ps1`
- Create: `scripts/tests/program-review.contract.ps1`
- Create: `scripts/tests/helpers/fake-codex.ps1`
- Create: `scripts/tests/helpers/fake-reader.ps1`
- Modify: `program/schemas/program-event-v1.schema.json`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- `Invoke-CodexAudit -Snapshot -Request -ScratchRoot -RunRoot -TimeoutSeconds` creates a full disposable clone from the snapshot bundle with independent Git metadata, redirects every writable root and language cache below its unique scratch directory, copies snapshot-declared dependencies into a disposable snapshot, and invokes Codex through `Invoke-RecordedCommand`.
- Codex arguments are `-a never exec --ephemeral -s workspace-write --add-dir <scratch> -m gpt-5.6-sol --json --color never -C <clone> -o <response> -`. The runner resolves current supported syntax during Task 9 and fails if it differs without an approved packet update.
- `Invoke-ProgramCouncil -Snapshot -Roles proof-reader,consensus-reader,operator-reader,security-reader` launches one separately supervised ephemeral reader process per snapshot-bound reviewer profile. Each process has its own full clone, independent Git metadata, scratch root, immutable request, command record, stdout, stderr, model/tool identity, session id, and response. Readers cannot read another reader's output or use the implementation actor id.
- Each Sprint 0 reviewer profile invokes the qualified Codex CLI with model `gpt-5.6-sol`, `exec --ephemeral`, JSON output, no approval prompts, a no-edit role prompt, and a unique session. The environment receipt binds the executable hash and supported arguments. An unavailable or changed reader executable blocks review until the profile is requalified in a new snapshot.
- Advisory review results require snapshot id, target commit, scope digest, immutable request and response hashes, exact Blocking/Major/Minor counts, verdict, and disposition link. Counts describe the report and cannot authorize closure.
- `ClosureEnvelopeV1` binds the reviewed snapshot to optional advisory review requests/results, dispositions, deterministic OpenSpec archive relocation and receipt, final event segment/state, a deterministic raw wiki closure receipt, its source node and graph materialization updates, wiki log events, inventories, redaction/seal receipts, and, only for `PBT-S13-W05`, the deterministic `live-pass` classifier receipt. Its typed delta manifest enumerates exact permitted paths and object digests, optional review round and role ids, finding dispositions, event types and ids, package state changes, raw wiki source digest, graph predicates and event ids, inventory additions, archive source and destination blob ids, and classifier fields. The manifest excludes the envelope's fixed path and blob. The validator checks that one file separately against the schema and semantic rules, then requires the complete tree delta to equal the typed manifest plus exactly `program/closures/<sprint-id>/closure-envelope-v1.json`. The envelope has no field for its own blob digest, final closure tree, or final closure commit. For Sprint 0, permitted state change is limited to closing W01-W18 and the sprint; public gates, deployment, activation, and classifier state cannot change. `Publish` creates the separately schema-checked and controller-signed `RemoteConfirmationBundleV1` through the broker after the push.

- [ ] **Step 1: Write failing audit-environment tests**

Preserve fixtures for the prior read-only TEMP denial, mixed stdout/stderr JSONL, absent `thread.started`, malformed JSONL, response file missing despite exit zero, dependency digest not matching the snapshot, dependency mutation, audited-clone mutation, shared Git metadata, stale snapshot, and process timeout with a surviving grandchild. Sentinel-test `TEMP`, `TMP`, `CODEX_HOME`, `HOME`, `USERPROFILE`, `APPDATA`, `LOCALAPPDATA`, `RUSTUP_HOME`, `CARGO_HOME`, `GOMODCACHE`, `GOCACHE`, `GOTMPDIR`, npm cache, and XDG roots for host writes.

- [ ] **Step 2: Write failing review-round tests**

Reject an overwritten round, duplicate role, mismatched snapshot, mismatched target commit, altered request, synthesized output without a command record, shared reader scratch, reader access to a peer report, cross-reader clone mutation, disposition that changes counts, a report whose verdict/count relationship violates its own schema, report written by the implementation actor or reused session, and remediation that reuses the same round. Closure-envelope fixtures add code, stable-spec, design, registry, artifact, or deployment changes after review and must reject; the exact attestation-only diff must pass. They also reject an envelope that inventories its own blob, an envelope outside the fixed path, a second unlisted file, a missing envelope, or an envelope with a closure-tree or closure-commit field. Hostile within-path fixtures also reject an extra gate-closing event, a later package transition, a deployment or activation field change in derived state, an unlisted wiki assertion, a changed archive blob, an extra inventory object, a classifier receipt before S13, or a classifier field not derived from its declared inputs.

- [ ] **Step 3: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/program-review.contract.ps1
```

Expected: import failure because `ProgramReview.psm1` does not exist.

- [ ] **Step 4: Implement the detached audit runner**

Use a full disposable clone with an independent object database and a unique external scratch root. Redirect every root named in Step 1, including a copied minimal `CODEX_HOME` with external secret handles and no logged secret bytes. Copy dependencies rather than linking canonical trees. Require their initial digest to equal the snapshot-declared digest, then verify the same digest after the audit. Capture Codex JSONL and stderr separately and extract the real thread id. Always verify and remove the clone and scratch children after process termination.

- [ ] **Step 5: Implement immutable persona review rounds**

Each supervised reader receives the same snapshot and a role-specific scope. Store reader-authored reports verbatim with executable, model, CLI, session, prompt, environment-receipt, and command hashes. A remediation creates a new implementation snapshot and new round. Technical dispositions append beside reports and never edit them. Build the closure delta from schema-enumerated semantic operations rather than path prefixes, and re-reduce its event and wiki subsets against the reviewed state. Agent-reader independence is an audit control only; it never counts as human MPC independence.

- [ ] **Step 6: Run fake audit, timeout, mutation, and council tests**

```powershell
pwsh -NoProfile -File scripts/tests/program-review.contract.ps1
pwsh -NoProfile -File scripts/tests/recorded-command.contract.ps1
pwsh -NoProfile -File scripts/tests/repository-lease.contract.ps1
```

Expected: the valid fake audit returns a real fixture thread id and clean clone; every sandbox, stream, mutation, timeout, target, role, and count negative rejects.

- [ ] **Step 7: Commit the review slice**

```powershell
git add -- program/schemas/review-request-v1.schema.json program/schemas/review-result-v1.schema.json program/schemas/closure-envelope-v1.schema.json program/reviewers program/templates/reviews scripts/program/ProgramReview.psm1 scripts/invoke-codex-audit.ps1 scripts/invoke-program-council.ps1 scripts/validate-closure-envelope.ps1 scripts/tests/program-review.contract.ps1 scripts/tests/helpers/fake-codex.ps1 scripts/tests/helpers/fake-reader.ps1 program/schemas/program-event-v1.schema.json openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W10
git diff --cached --check
git commit -m "Add snapshot-bound audit and council runners"
```

### Task 15: `PBT-S00-W11` Materialize and Lint the Program Wiki

**Files:**
- Create: `scripts/program/ProgramWiki.psm1`
- Create: `scripts/materialize-program-wiki.ps1`
- Create: `scripts/validate-program-wiki.ps1`
- Create: `scripts/tests/program-wiki.contract.ps1`
- Create: `knowledge_base/program-wiki/reports/pbt-s00-lint.json`
- Modify: `knowledge_base/program-wiki/README.md`
- Modify: `knowledge_base/program-wiki/AGENTS.md`
- Modify: `knowledge_base/program-wiki/graph/schema.json`
- Update: `knowledge_base/program-wiki/graph/events.jsonl`
- Update: `knowledge_base/program-wiki/graph/nodes.json`
- Update: `knowledge_base/program-wiki/graph/edges.json`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- `Read-WikiGraphEvents -RepositoryRoot -WikiRoot -Snapshot INDEX|<commit>` validates schema, contiguous sequence, event id, operation semantics, source path, source id, and SHA-256 from the staged index or committed Git blob selected by the explicit snapshot. It requires V1 events 1-29 to equal committed blob `c79bae81f4bdb87c5c7eef1baeeef190f8be5f65` byte-for-byte with prefix SHA-256 `401d2fc42de6d52fc0b52633364c9a428ec364a2fa8daf8d3c4b6226b1e51e50`. V1 resolves sources against the explicit validator snapshot. V2 begins at event 30 and requires `source_snapshot=self`; `self` resolves to that explicit snapshot and must contain both event and source.
- `Build-WikiGraph` deterministically emits sorted `nodes.json` and `edges.json` from `events.jsonl`.
- `Test-ProgramWiki` checks frontmatter, stable unique page ids, valid types/status, existing sources, Markdown links, index membership, orphan pages, duplicate concepts, contradictions, required supersession, chronological log, graph materialization, source hashes, 14 canonical sprint nodes, 106 canonical package nodes, package-to-sprint edges, full package dependencies, and exact agreement with `ProgramPlanV1` and the master register.

- [ ] **Step 1: Write failing wiki fixtures**

Copy the wiki to scratch and inject, one at a time: changed V1 byte, V1 after sequence 29, V2 at or before sequence 29, missing or non-`self` V2 source snapshot, missing metadata, duplicate id, missing source identity, wrong blob hash, index bytes checked as HEAD, committed bytes checked as INDEX, mismatched explicit snapshot, event gap, duplicate event, invalid operation, missing canonical sprint, missing package, wrong package-to-sprint edge, dependency disagreement, orphan page, broken link, unindexed page, unresolved contradiction, superseded assertion without link, stale materialized node, and Windows working-tree hash used instead of the selected Git blob hash. There is no validator mode that rewrites or upgrades the V1 prefix.

- [ ] **Step 2: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/program-wiki.contract.ps1
```

Expected: import failure because `ProgramWiki.psm1` does not exist.

- [ ] **Step 3: Implement graph materialization and lint**

Use the append-only event stream as the sole graph history. Resolve repository sources through `git show <snapshot>:<path>` or `git cat-file blob`, never through converted worktree text. Emit stable, ordinally sorted materialized arrays. Report all findings in one structured result and return nonzero for Blocking or Major findings.

- [ ] **Step 4: Update maintenance rules and create the lint report**

Document exact commands, explicit `INDEX` versus commit hashing, materialized ordering, canonical `PBT-*` graph ids, and the rule that raw files and event objects are immutable after first commit. Run the validator on the real committed wiki and write `pbt-s00-lint.json` with source snapshot, graph head, 14 sprint nodes, 106 package nodes, page count, node count, edge count, and zero unresolved Blocking/Major lint findings.

- [ ] **Step 5: Run wiki, snapshot, and OpenSpec tests**

```powershell
pwsh -NoProfile -File scripts/tests/program-wiki.contract.ps1
pwsh -NoProfile -File scripts/validate-program-wiki.ps1 -RepositoryRoot . -WikiRoot knowledge_base/program-wiki -Snapshot INDEX -Report knowledge_base/program-wiki/reports/pbt-s00-lint.json
npm --offline run openspec:validate
```

Expected: the real wiki and materialized graph pass; every injected defect fails for its specific reason.

- [ ] **Step 6: Commit the wiki automation slice**

```powershell
git add -- scripts/program/ProgramWiki.psm1 scripts/materialize-program-wiki.ps1 scripts/validate-program-wiki.ps1 scripts/tests/program-wiki.contract.ps1 knowledge_base/program-wiki/README.md knowledge_base/program-wiki/AGENTS.md knowledge_base/program-wiki/graph/schema.json knowledge_base/program-wiki/graph/events.jsonl knowledge_base/program-wiki/graph/nodes.json knowledge_base/program-wiki/graph/edges.json knowledge_base/program-wiki/reports/pbt-s00-lint.json openspec/changes/pbt-s00-program-control-plane/tasks.md
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W11
git diff --cached --check
git commit -m "Add deterministic program wiki validation"
```

### Task 16: `PBT-S00-W12` Publish and Reproduce the Base GateRosterV2

**Files:**
- Create: `protocol/gate-roster-v2.schema.json`
- Create: `protocol/gate-evaluation-v1.schema.json`
- Create: `program/schemas/classifier-readiness-v1.schema.json`
- Create: `protocol/gate-roster-v2-base.json`
- Create: `protocol/gate-roster-v2-base.cbor.hex`
- Modify: `protocol/README.md`
- Modify: `reference/rust/src/model.rs`
- Modify: `reference/rust/src/harness.rs`
- Modify: `reference/rust/tests/structural.rs`
- Modify: `reference/go/internal/harness/model.go`
- Modify: `reference/go/internal/harness/harness.go`
- Modify: `reference/go/internal/harness/harness_test.go`
- Create: `scripts/tests/gate-roster-v2.contract.ps1`
- Create: `scripts/tests/gate-evaluation.contract.ps1`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`

**Interfaces:**
- The base `GateRosterV2` records stable legacy and meta-gate ids, class, direction when known, source root, destination surface, evidence producer package, consumer packages, `initial_state=unresolved`, accepted evidence schema, invalidation scope, `activation_required`, earliest activation stage, and `roster_stage=base`. It contains no proof-template family id and is permanently ineligible for public execution, activation, or classification by itself. `PBT-S04-W06` later publishes a separate `roster_stage=family-complete` roster under the same V2 schema. That roster preserves `base_roster_sha256` and `base_entry_count`, contains the ordered base entries as a byte-identical canonical prefix, binds `admitted_matrix_root`, and appends only admitted family entries with `initial_state=unresolved`; neither file is mutated. A canonical activation-subset digest covers exactly the entries with `activation_required=true` whose stage is no later than predeployment. Deployment, execution, public-receipt, classifier-readiness, and terminal classifier evidence are never prerequisites for the deployment that produces them.
- `GateEvaluationV1` binds one entry-origin roster digest, canonical entry digest, and entry id to a program snapshot, producer package and attempt, accepted evidence-schema id, evidence and command-record digests, evaluation `passed|failed|unresolved`, issue and optional expiry times, and invalidation scope. Base-prefix entries always use `base_roster_sha256` as their origin, including when read from the family-complete artifact. Only appended family entries use the family-complete roster digest. New evidence appends a superseding evaluation event; expiry or scoped input drift appends invalidation and makes the current view unresolved. The reducer rejects two effective evaluations for one logical entry. After verifying the byte-identical prefix, the classifier constructs one logical set from all base entries plus only the appended family entries, requires exactly one nonexpired evaluation for each, and never treats `initial_state` as current proof.
- Gate classes include activation blocker, consensus root, destination execution, predicate corpus, direction-family execution, setup, readiness, public receipt, and classifier readiness. `ActivationDecisionV1` consumes only the roster-defined predeployment activation subset and binds its subset digest and ordered current evaluations. Advisory reader artifacts never enter a roster, activation decision, classifier-readiness receipt, or classifier input. The classifier-readiness gate names `PBT-S12-W07` as its producer and `program/schemas/classifier-readiness-v1.schema.json` as its accepted evidence schema. `ClassifierReadinessV1` proves that the frozen classifier candidate and every other current roster evaluation are complete. PBT-S12-W07 then appends the readiness gate's own `GateEvaluationV1` using that receipt. PBT-S13 independently verifies the resulting complete set. The terminal classifier receipt is an output and never a roster input.

- [ ] **Step 1: Write failing roster tests**

Require the existing six `S01-BLOCK-*` and eight `CONS-*` facts to map into V2 with `initial_state=unresolved`. Add gates for official source roots, both destination surfaces, exact 42/52 admission, direction-family matrix admission, circuit freeze, human setup, readiness, public receipts, and classifier readiness. Sprint 0 must not invent family ids. `PBT-S04-W06` expands the roster with exact family rows after catalog admission. Reject duplicate ids, missing producer, unknown package, a family gate without an admitted catalog receipt and direction, evidence schema mismatch, impossible dependency order, an activation-required entry whose producer or evidence cannot exist before deployment, a late gate included in the activation-subset digest, an activation decision that uses the complete classifier set, any reader or council artifact represented as a roster entry, a classifier-readiness producer other than `PBT-S12-W07`, a classifier-readiness evidence schema other than `ClassifierReadinessV1`, any non-unresolved initial state, any closed public gate without a current roster-bound evaluation and receipt, a base roster used alone in S12 run intent or S13 classification, and a family-complete roster that does not preserve the exact base digest, entry count, ordered byte-identical prefix, or admitted matrix root. Evaluation fixtures reject unknown entries, wrong origin roster, wrong entry digest or snapshot, a base-prefix evaluation keyed to the family digest, wrong evidence schema, duplicate current records, stale or expired evidence, invalid supersession, and missed invalidation. Classifier fixtures reject an omitted, altered, reordered, expired, or unevaluated base or family gate even when the stored roster digests are correct. They also reject any classifier input that attempts to use advisory reader counts or artifacts.

- [ ] **Step 2: Run and observe RED**

```powershell
pwsh -NoProfile -File scripts/tests/gate-roster-v2.contract.ps1
pwsh -NoProfile -File scripts/tests/gate-evaluation.contract.ps1
```

Expected: nonzero because `gate-roster-v2-base.json` and independent reproduction do not exist.

- [ ] **Step 3: Publish V2 and extend independent reproduction**

Use one deterministic CBOR profile. Extend Rust and Go independently to parse, validate, encode, and hash the same base roster. Do not call one implementation from the other. Tests reject any family id in a base roster, require `activation_eligible=false` and `classification_eligible=false`, and require the unresolved matrix-admission gate owned by `PBT-S04-W06`. Preserve V1 as historical structural-harness input until `PBT-S01` migrates it.

### Task 17: `PBT-S00-W17` Integrate CI and Run the Control-Plane Smoke Test

**Files:**
- Create: `scripts/tests/pbt-s00-smoke.integration.ps1`
- Create: `scripts/verify-program-control.ps1`
- Create: `.github/workflows/program-control.yml`
- Modify: `README.md`
- Modify: `openspec/specs/operations-governance/spec.md`
- Modify: `openspec/specs/conformance-testnet/spec.md`
- Modify: `openspec/changes/pbt-s00-program-control-plane/tasks.md`
- Modify: `openspec/changes/pbt-s00-program-control-plane/review.md`

`verify-program-control.ps1` runs every Sprint 0 contract through the W05
supervisor, strict OpenSpec, plan validation, event reduction, runlog and wiki
lint, independent Rust/Go roster reproduction, secret scan, clean detached
checkout, and `git diff --check`.

Reader outputs are advisory quality evidence and never a closure input. Closure depends on deterministic suites, signed
operator records, and externally reproducible receipts.

- [ ] **Step 1: Write the smoke integration test before the verifier**

The first run must fail at `program verifier missing`. Then implement `verify-program-control.ps1` as an ordered fail-fast orchestrator whose commands are themselves recorded. The smoke test must inject a torn event, timeout, lease-renewal loss, stale fence, host/WSL/container leak, secret, snapshot drift, two parallel clone results, shared Git metadata, concurrent remote advance, synthesized reader result, a reader count presented as closure authority, non-attestation closure diff, and cleanup failure, proving each invalid closure input blocks without emitting success.

- [ ] **Step 2: Add CI and reconcile the main README**

The workflow runs portable tests on GitHub-hosted Windows and Ubuntu. A required self-hosted job labeled `mcb-wsl-docker` runs the real WSL-native-checkout, controller-service ACL, restricted-token, Windows Job Object, dedicated WSL-distro escape and double-fork, and Docker cleanup tests. Pin third-party actions to reviewed commit SHAs and use lockfiles or offline modes after dependency installation. The README links the approved design, master plan, Sprint 0 plan, OpenSpec change, program wiki, controller commands, and current blocked deployment state. Materialize the W01-inventoried README content object, verify it, and merge its intent; do not read a later canonical-worktree value or overwrite it wholesale.

- [ ] **Step 3: Run the complete local verification set**

```powershell
pwsh -NoProfile -File scripts/tests/gate-roster-v2.contract.ps1
pwsh -NoProfile -File scripts/tests/pbt-s00-smoke.integration.ps1
pwsh -NoProfile -File scripts/tests/openspec-archive.contract.ps1
pwsh -NoProfile -File scripts/verify-program-control.ps1
pwsh -NoProfile -File scripts/verify-reference-harness.ps1
npm --offline run openspec:validate
git diff --check
```

Expected: every control and current harness check exits zero. The result reports `sprints=14 packages=106`, all Sprint 0 negative suites exercised, current public gates unresolved, `deployment_outcome=blocked`, and `activation_eligible=false`.

- [ ] **Step 4: Sync stable OpenSpec, commit, and validate the exact candidate**

Mark implementation tasks complete only where their command receipts exist. Sync accepted PBT-S00 delta requirements into stable `operations-governance` and `conformance-testnet`, and update current-state wiki synthesis. Leave reader results, archive relocation, final event/state, wiki log, seal, and closure envelope absent. These are the only permitted post-review additions. Stage and commit the review candidate first. The W17 manifest maps `openspec-reviewed-candidate` to the qualified OpenSpec executable with exact argv `validate --all --strict --no-interactive`, `OPENSPEC_TELEMETRY=0`, a finite timeout, and a required complete-pass summary. The executable and its complete dependency bundle live outside the clone, are read-only, and have a manifest digest bound by the environment receipt and `ProgramSnapshotV1`; the command does not install dependencies or create `node_modules`. The broker runs it in a fresh full clone at the committed candidate, binds the candidate commit and full tree digest in `CommandRecordV2`, and proves that cwd, Git HEAD, clean status, and input tree are that candidate before launch and after exit. A checkout, index, environment, executable, dependency-bundle, or input-tree mismatch rejects the record.

```powershell
git add -- protocol/gate-roster-v2.schema.json protocol/gate-evaluation-v1.schema.json protocol/gate-roster-v2-base.json protocol/gate-roster-v2-base.cbor.hex protocol/README.md reference/rust/src/model.rs reference/rust/src/harness.rs reference/rust/tests/structural.rs reference/go/internal/harness/model.go reference/go/internal/harness/harness.go reference/go/internal/harness/harness_test.go program/schemas/openspec-archive-receipt-v1.schema.json scripts/validate-openspec-archive.ps1 scripts/tests/openspec-archive.contract.ps1 scripts/tests/gate-roster-v2.contract.ps1 scripts/tests/gate-evaluation.contract.ps1 scripts/tests/pbt-s00-smoke.integration.ps1 scripts/verify-program-control.ps1 scripts/invoke-program-package.ps1 .github/workflows/program-control.yml README.md openspec/specs/operations-governance/spec.md openspec/specs/conformance-testnet/spec.md openspec/changes/pbt-s00-program-control-plane/tasks.md openspec/changes/pbt-s00-program-control-plane/review.md knowledge_base/program-wiki/wiki
pwsh -NoProfile -File scripts/assert-cached-paths.ps1 -Plan program/plans/public-testnet-livepass-v2.json -PackageId PBT-S00-W17 -Phase implementation
git diff --cached --check
git commit -m "Integrate the bridge program control plane"
$reviewCandidate = (git rev-parse HEAD).Trim()
pwsh -NoProfile -File scripts/invoke-program-package.ps1 -Action Reconcile -ExecutionContext $executionContextPath -CommandId openspec-reviewed-candidate -TargetCommit $reviewCandidate
```

### Task 18: `PBT-S00-W18` Close Sprint 0 and Confirm Remote Publication

**Files:**
- Create: `program/schemas/openspec-archive-receipt-v1.schema.json`
- Create: `scripts/validate-openspec-archive.ps1`
- Create: `scripts/tests/openspec-archive.contract.ps1`
- Modify: `scripts/invoke-program-package.ps1`
- Create: `openspec/changes/archive/2026-07-10-pbt-s00-program-control-plane/`
- Create: `program/closures/pbt-s00/closure-envelope-v1.json`
- Create: `knowledge_base/program-wiki/raw/closures/pbt-s00/<closure-id>.json`
- Update: `knowledge_base/program-wiki/graph/events.jsonl`
- Update: `knowledge_base/program-wiki/graph/nodes.json`
- Update: `knowledge_base/program-wiki/graph/edges.json`
- Modify: `knowledge_base/program-wiki/wiki/log.md`
- Update: `program/events/public-testnet-livepass-v2/`
- Update: `program/state/public-testnet-livepass-v2.json`

The active change's `review.md` is frozen before the candidate commit. Advisory
reader records remain immutable and snapshot-bound, but their model-generated
counts cannot authorize closure. `FinalizeClosure` accepts only the reviewed
snapshot, deterministic validation records, signed operator receipts, declared
redaction receipts, and the typed attestation-only delta.

- [ ] **Step 1: Freeze one snapshot and run advisory independent reviews**

Use the W18 execution context to create `ProgramSnapshotV1` from the clean review-candidate commit. Run a fresh Codex audit plus proof, consensus, operator, and security readers through Task 14. Each reader inspects the full committed snapshot. Preserve every round. Convert any accepted technical issue into a failing deterministic contract before fixing it; reader counts themselves are neither pass criteria nor closure fields.

- [ ] **Step 2: Build and validate the attestation-only closure envelope**

After every required deterministic suite and external receipt passes, the controller creates an archive-candidate
worktree from the reviewed commit. That worktree performs exactly one semantic
operation: remove the active PBT-S00 change path and add the same file set and
bytes at
`openspec/changes/archive/2026-07-10-pbt-s00-program-control-plane/`. It commits
this relocation before generating an archive receipt. The controller runs the
byte-relocation validator and stable-only OpenSpec validation in a fresh clean
clone at that archive-candidate commit. Their command records bind the full
archive-candidate tree.

Only after both checks pass does the controller create the final closure
worktree from the archive candidate. It may add immutable reader artifacts,
technical dispositions, the non-self-referential archive receipt, final event
segment and derived state, wiki log and graph events, inventories, redaction
receipts, run seal, one deterministic raw wiki closure receipt and source node,
and `program/closures/pbt-s00/closure-envelope-v1.json`. The raw wiki receipt
binds the reviewed commit, archive-candidate commit, immutable review-result
digests, archive validation records, and final event inputs, but not the closure
envelope that later inventories it. Graph events use that raw receipt as their
content-addressed source. The envelope's typed delta manifest inventories every
new closure path and object digest except its own fixed path and blob. The
validator checks the envelope separately and requires the complete tree delta to
equal the inventory plus that one path. Neither the envelope nor another in-tree
record contains the final closure tree or commit. Run
`validate-closure-envelope.ps1` against the reviewed commit, archive-candidate
commit, and final closure tree. Any other path or semantic change returns to Step
7 and repeats affected readers.
OpenSpec itself does not validate archived changes. Archive assurance is the
composition of four records: strict stable-plus-active validation from a clean
clone at the reviewed candidate and exact tree, the reviewed active-change tree
manifest, byte-identical relocation verified by
`validate-openspec-archive.ps1`, and strict stable-only validation in a clean
clone at the relocation-only archive candidate. `OpenSpecArchiveReceiptV1` is
created afterward and binds every source and destination blob id, both tree
digests, required artifact, reviewed commit, archive-candidate commit, and both
validation command digests. It never binds a tree containing itself. It requires
the pre-archive command record's target commit and complete input-tree digest to
equal the reviewed candidate, and the post-archive record to equal the archive
candidate. The archive contract rejects a
missing or extra file, renamed requirement, changed byte, wrong date/name,
unreviewed source tree, command record from another tree, dirty validation clone,
or active copy left behind. The W18 manifest maps
`openspec-archive-byte-check` to the byte-relocation validator and
`openspec-post-archive-stable` to the same qualified OpenSpec executable with
exact argv `validate --specs --strict --no-interactive`. The latter binds the
archive-candidate commit and full tree plus the expected stable-spec count and
cannot include any active change.
Both commands use the snapshot-bound read-only dependency bundle. The active
change `review.md` must remain byte-identical; reader artifacts are not written
there. Run the complete verifier after both pass.

```powershell
$archiveCandidate = pwsh -NoProfile -File scripts/invoke-program-package.ps1 -Action Reconcile -ExecutionContext $executionContextPath -Phase archive-candidate | ConvertFrom-Json
pwsh -NoProfile -File scripts/invoke-program-package.ps1 -Action Reconcile -ExecutionContext $executionContextPath -CommandId openspec-archive-byte-check -TargetCommit $archiveCandidate.commit
pwsh -NoProfile -File scripts/invoke-program-package.ps1 -Action Reconcile -ExecutionContext $executionContextPath -CommandId openspec-post-archive-stable -TargetCommit $archiveCandidate.commit
$closureResult = pwsh -NoProfile -File scripts/invoke-program-package.ps1 `
  -Action FinalizeClosure `
  -ExecutionContext $executionContextPath `
  -ArchiveCandidateCommit $archiveCandidate.commit | ConvertFrom-Json
```

- [ ] **Step 3: Integrate and publish the verified closure context**

```powershell
$closureContextPath = $closureResult.execution_context
pwsh -NoProfile -File scripts/validate-closure-envelope.ps1 `
  -ExecutionContext $closureContextPath `
  -ExpectedSourceCommit $closureResult.closure_source_commit `
  -ExpectedIntegrationCommit $closureResult.closure_integration_commit `
  -ExpectedTree $closureResult.closure_tree `
  -ExpectedEnvelopeSha256 $closureResult.closure_envelope_sha256
$publishResult = pwsh -NoProfile -File scripts/invoke-program-package.ps1 `
  -Action Publish `
  -ExecutionContext $closureContextPath | ConvertFrom-Json
pwsh -NoProfile -File scripts/verify-remote-confirmation.ps1 `
  -Bundle $publishResult.remote_confirmation_bundle `
  -Envelope $closureResult.closure_envelope_path `
  -ExpectedCommit $closureResult.closure_integration_commit
```

Expected: `FinalizeClosure` materializes, commits, validates, and integrates the exact attestation-only closure tree and returns distinct source and canonical integration commits, their equal tree, external envelope digest, integration receipt, and closure execution context. Normal push succeeds, fetched remote SHA equals the returned canonical integration commit, and a signed external `RemoteConfirmationBundleV1` plus `remote-confirmed` event records the equality. The archive composition validates. `PBT-S01-W01` becomes externally ready only from the envelope plus verified bundle; before its lease, the controller imports the receipt, all three credential-probe receipts, every ordered command record and exact raw stream and manifest, controller identity, immutable public credential-handle receipt, and payload manifest byte-for-byte, then emits `remote-confirmation-imported`. No later package becomes ready early.

## Sprint 0 Closure Checklist

- [ ] All 18 package ids are closed by valid event histories and matching OpenSpec receipts.
- [ ] The canonical plan validates at 14 sprints, 106 packages, and zero cycles.
- [ ] Atomic event publication, crash, retry, renewal, release, resume, external wait, stale fence, timeout, host/WSL/container cleanup, and unknown-submission behavior pass.
- [ ] Command records are V2, come only from the execution wrapper, and bind the current fence plus exact executable, source, argv, cwd, environment, outputs, raw byte streams, execution boundary, and terminal state.
- [ ] Runlogs are path-contained, inventory-complete, hash-complete, stream-separated, review-complete, redaction-checked, and thought-stream-free.
- [ ] Detached Windows and WSL checkouts reproduce Git-blob identities and leave no undeclared residue.
- [ ] Restricted package workers cannot mutate the controller, canonical Git metadata, or sibling clones; controller integration is serialized; repository transactions reject stale fences, concurrent remote movement, out-of-scope changes, and prompted or revoked credentials; the signed `RemoteConfirmationBundleV1` later reproduces both fetches and the post-push remote SHA.
- [ ] Grok packets are sprint-bounded, snapshot-bound, XSD-valid, supervisor-routed, environment-qualified, and free of credentials.
- [ ] Codex audits use full disposable clones and writable external scratch; independent Git metadata, JSONL, stderr, response, dependencies, cleanup, and target identity validate.
- [ ] Council reports come from separately supervised reader sessions, are immutable and snapshot-equal, and remain advisory rather than authorization evidence.
- [ ] `ClosureEnvelopeV1` proves that the pushed tree differs from the reviewed snapshot only by allowed attestation and deterministic archive artifacts.
- [ ] The program wiki passes metadata, explicit-snapshot source hashes, links, contradictions, supersession, materialization, 14-sprint, 106-package, and ProgramPlan agreement checks.
- [ ] The base `GateRosterV2` has independent Rust and Go reproduction, contains no invented family id, and retains every unresolved chain gate honestly.
- [ ] The current reference harness passes; accepted deltas are synced; the PBT-S00 change is archived with a digest; strict OpenSpec passes; the canonical design still has exactly 25 numbered sections.
- [ ] Deployment remains `blocked` with `activation_eligible=false`; no Sprint 0 artifact claims public proof verification or destination execution.
