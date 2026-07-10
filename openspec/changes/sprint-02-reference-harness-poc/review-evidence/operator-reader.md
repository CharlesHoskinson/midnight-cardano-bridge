# Sprint 2 Independent Operator / Reproducibility Review

## Snapshot SHA

`4d985a702fd48a1e7d82ceb9d5304f758544af99`

The worktree was clean at the start of this review. The review used the current
snapshot only and did not read prior council reports or conversation history.

## Scope

Reviewed:

- `scripts/setup-reference-harness.ps1`
- `scripts/verify-reference-harness.ps1`
- `scripts/compare-reference-harness.ps1`
- all three files under `scripts/tests/`
- `package-lock.json`, `reference/rust/Cargo.lock`,
  `reference/observers/requirements.txt`, and
  `reference/observers/requirements.lock.txt`
- committed structural, conformance, and unsigned-observation evidence
- `reference/README.md`, root `README.md`, and `EXAMINATION-CHECKLIST.md`
- the Sprint 2 proposal, design, tasks, and delta specs for reference harness,
  conformance/testnet, operations/governance, and Groth16

The review focused on clean-checkout bootstrap, exact tool selection, lock
integrity, offline/public-data separation, temporary output isolation,
read-only behavior, evidence publication and rollback, late-failure output,
stale-evidence detection, command/input/version binding, cleanup, Windows path
behavior, and documented reproduction. No live Midnight, Mithril, or Cardano
endpoint command was invoked. No implementation, documentation, task, or
committed evidence file was changed.

## Commands And Results

1. `git rev-parse HEAD` returned the full snapshot SHA above. Initial
   `git status --short --untracked-files=all` was empty.
2. `pwsh -NoProfile -File scripts/setup-reference-harness.ps1 -WhatIf` exited
   0. It validated the exact prepared-host versions and lock syntax and planned
   `npm ci`, venv recreation, locked pip installation, and
   `cargo fetch --locked` without executing them.
3. The same setup dry run was executed from a disposable `git archive HEAD`
   extraction that had no `node_modules`, `.venv-scrapling`, or Rust target.
   It exited 0 and planned all operations. The registry-backed, mutating setup
   was not run, so clean-checkout installation coverage remains dry-run only.
4. `pwsh -NoProfile -File scripts/tests/setup-reference-harness.contract.ps1`
   exited 0 with `test=setup-dry-run-contract state=PASS`.
5. `scripts/tests/compare-reference-harness.Tests.ps1` was run with temporary
   `CARGO_TARGET_DIR` and `GOCACHE`; it exited 0 and emitted
   `cross_language_structural=PASS`. Its candidate was under `%TEMP%`.
6. `pwsh -NoProfile -File scripts/tests/verify-reference-harness.integration.ps1`
   exited 0 with `test=late-failure-preserves-committed-evidence state=PASS`.
7. `pwsh -NoProfile -File scripts/verify-reference-harness.ps1` exited 0 in
   29.8 seconds. Rust (8 structural tests), Go tests/vet, 17 Python tests,
   cross-language comparison, roster validation, independent cbor2 checks,
   unsigned-observation validation, strict OpenSpec validation (13/13),
   `git diff --check`, input stability, and byte-identical evidence comparison
   all passed. The final result was `structural-pass`, deployment `blocked`, and
   `activation_eligible=false`.
8. An isolated `-UpdateEvidence` run in a disposable initialized snapshot held
   the conformance destination open so the second replace failed after all
   checks. It exited 1 at `evidence-publication`, emitted no final result JSON,
   restored both evidence hashes, and left zero verifier temp directories.
9. Post-run cleanup checks found no `mcb-reference-verify-*`,
   `mcb-verifier-integration-*`, or operator probe directories. The reviewed
   checkout remained unchanged by these commands.

## Blocking

### B-01: The default verifier does not enforce its no-network/read-only contract for OpenSpec

- **File:line:** `scripts/verify-reference-harness.ps1:658`,
  `scripts/verify-reference-harness.ps1:676`,
  `scripts/verify-reference-harness.ps1:767`, `package-lock.json:12`, and
  `package-lock.json:27`.
- **Failure mode:** A default verification can attempt OpenSpec telemetry and,
  on a first run, can create or update OpenSpec user configuration outside the
  run directory. This violates the normative requirement that the default
  command perform no network request and the documented read-only/offline
  behavior. `npm --offline` controls npm package access; it does not disable
  telemetry inside the child OpenSpec CLI. The loopback proxy settings are not
  an affirmative no-network control for Node's built-in `fetch`, and even a
  proxy connection attempt is a network request.
- **Evidence:** The lock pins OpenSpec 1.5.0 and its `posthog-node` dependency.
  Inspection of that exact installed package showed a CLI pre-action that calls
  `trackCommand`, with opt-out only through `OPENSPEC_TELEMETRY=0`,
  `DO_NOT_TRACK=1`, or `CI=true`. None of those variables is set, saved, or
  restored by `Set-RunEnvironment`; repository search found no telemetry
  opt-out. The normative no-network requirement is at
  `openspec/changes/sprint-02-reference-harness-poc/specs/reference-harness/spec.md:34`.
- **Required disposition:** Disable OpenSpec telemetry before every OpenSpec
  invocation, including version discovery, save and restore the relevant
  variables, and add an isolated test with an empty OpenSpec user config that
  fails on any socket attempt or user-config write. Regenerate both evidence
  reports after the verifier changes.

## Major

### M-01: The structural report does not carry the bindings required of each committed report

- **File:line:** `scripts/compare-reference-harness.ps1:105`,
  `scripts/compare-reference-harness.ps1:109`,
  `reference/evidence/structural-report-v1.json:1`, and
  `openspec/changes/sprint-02-reference-harness-poc/specs/reference-harness/spec.md:37`.
- **Failure mode:** `structural-report-v1.json` cannot independently distinguish
  a current result from a stale result because it contains only the fixture
  name, implementation names, and structural fields. It has no input manifest,
  verifier revision, commands, tool versions, or exit/result binding. The
  conformance report indirectly binds the structural file by hash, but the
  requirement says each committed report shall carry the bindings, and the
  README describes all files under `reference/evidence/` as input-bound.
- **Evidence:** The evidence constructor at lines 105-110 adds two labels and
  copies Rust report properties; the committed structural report's complete
  field set contains none of the required execution-binding fields. Only
  `conformance-report-v1.json` contains them.
- **Required disposition:** Add a deterministic execution-binding object to the
  structural candidate containing the complete input manifest, verifier
  revision, actual command records, tool versions, and final semantics. Keep the
  conformance report's structural hash cross-link, validate both directions,
  and add a negative stale-structural-report test.

### M-02: The conformance command binding is descriptive, not exact or directly reproducible

- **File:line:** `scripts/verify-reference-harness.ps1:747`,
  `scripts/verify-reference-harness.ps1:774`,
  `scripts/verify-reference-harness.ps1:779`,
  `scripts/verify-reference-harness.ps1:780`, and
  `reference/evidence/conformance-report-v1.json:50`.
- **Failure mode:** An operator cannot reconstruct the exact execution from the
  evidence. The verifier executes the comparison script in-process with
  `& $tools.compare`, but records a fresh `pwsh -NoProfile -File` process. The
  independent CBOR command is recorded with the non-executable placeholder
  `<independent-cbor-check>`. Resolved executables, cwd, argv, and the offline
  environment are not represented as structured command inputs. This conflicts
  with the README's `exact commands` claim and weakens independent reproduction.
- **Evidence:** The committed commands array reproduces the handwritten strings
  at lines 774-783, including the placeholder, rather than records emitted by
  the invocation wrapper. The actual comparison call at line 747 is different
  from the recorded command at line 779.
- **Required disposition:** Generate structured command records from the same
  wrapper that executes each check. Bind logical tool identity and resolved
  version, cwd, argv, relevant offline/isolation environment, and the SHA-256 of
  inline check source. Either execute the recorded comparison command exactly
  or record the actual in-process invocation. Add a test that replays every
  recorded command record in an isolated snapshot.

### M-03: The Python dependency lock pins versions but not artifact integrity

- **File:line:** `reference/observers/requirements.lock.txt:1`,
  `scripts/setup-reference-harness.ps1:91`, and
  `scripts/setup-reference-harness.ps1:223`.
- **Failure mode:** A clean checkout can install different or replaced wheel or
  sdist bytes under the same 28 name/version pairs. Platform-specific artifact
  choice and registry compromise are not constrained, so the setup cannot
  support the documentation's claim of an exact dependency installation at the
  artifact level. The installed-distribution equality check runs only after
  code has been downloaded and installed.
- **Evidence:** Every Python lock entry is only `name==version`. The lock parser
  accepts only that single-line form, and pip is invoked without
  `--require-hashes`; in contrast, `package-lock.json` and `Cargo.lock` carry
  registry artifact integrity/checksum fields.
- **Required disposition:** Generate and commit a Windows/Python 3.14 lock with
  hashes for every accepted artifact, install it with `--require-hashes`, and
  constrain source builds or explicitly bind their build inputs. Validate the
  lock's target platform and hash completeness in setup and verifier tests.

### M-04: Evidence publication is not a portable or crash-atomic pair update

- **File:line:** `scripts/verify-reference-harness.ps1:625`,
  `scripts/verify-reference-harness.ps1:627`,
  `scripts/verify-reference-harness.ps1:636`,
  `scripts/verify-reference-harness.ps1:638`, and
  `reference/README.md:87`.
- **Failure mode:** On Windows, a checkout on a different volume from `%TEMP%`
  cannot use the documented `-UpdateEvidence` command at all. On the same
  volume, the two destinations are replaced sequentially; process termination
  or host loss between the two moves leaves a mixed generation because the
  catch/rollback block cannot run. That is not the atomic pair publication
  claimed by the design and README.
- **Evidence:** Lines 625-629 explicitly reject different roots. Lines 636 and
  638 are separate moves with only in-process exception rollback. The isolated
  locked-second-file probe confirmed that ordinary caught failure rolls bytes
  back correctly, but it cannot cover termination between moves.
- **Required disposition:** After all checks pass, stage publication files on
  the destination volume automatically. Publish a generation identifier or
  commit manifest last, make readers reject incomplete/mixed generations, and
  implement startup recovery for an interrupted update. Add tests for a
  different `%TEMP%` volume, second-move failure, and interruption between
  replacements; document the actual transaction semantics.

### M-05: Canonical evidence does not exercise the harness control tests or an actual clean bootstrap

- **File:line:** `scripts/verify-reference-harness.ps1:729`,
  `scripts/verify-reference-harness.ps1:767`,
  `scripts/tests/setup-reference-harness.contract.ps1:35`, and
  `scripts/tests/verify-reference-harness.integration.ps1:171`.
- **Failure mode:** The canonical verifier and committed command list can pass
  while setup planning, comparison output isolation, late-failure label
  suppression, evidence preservation, or cleanup regress. None of the three
  PowerShell tests under `scripts/tests/` is run by the verifier. Moreover, the
  setup contract invokes only `-WhatIf`, so it never proves that a dependency-
  empty checkout can execute `npm ci`, create the venv, install the Python lock,
  fetch Cargo dependencies, and then verify successfully.
- **Evidence:** The canonical check sequence runs Rust, Go, Python observation,
  comparison, OpenSpec, and Git checks only. The late-failure assertions at
  integration-test lines 171-177 and the setup dry-run assertions are outside
  committed conformance evidence. Manual review runs passed those tests, but
  that result is not bound into either report.
- **Required disposition:** Add a non-recursive orchestration test phase to the
  release/conformance entry point and bind its commands/results. Add an isolated
  clean-snapshot bootstrap integration test using controlled local registries or
  caches, then run the verifier from the newly created environment and assert
  that no chain/public-data endpoint is reachable.

## Minor

### m-01: Setup reports READY during `-WhatIf` even when nothing is installed

- **File:line:** `scripts/setup-reference-harness.ps1:232`,
  `scripts/setup-reference-harness.ps1:245`, and
  `scripts/tests/setup-reference-harness.contract.ps1:47`.
- **Failure mode:** Automation or an operator parsing the final state can treat a
  dry-run-only checkout as ready, then immediately fail because `node_modules`
  and `.venv-scrapling` do not exist.
- **Evidence:** A clean `git archive` extraction confirmed all three dependency
  directories were absent, yet `-WhatIf` emitted
  `setup=reference-harness state=READY`. The contract test requires that output,
  while installed-version and lock-match checks are skipped under `-WhatIf`.
- **Required disposition:** Emit `state=PLANNED` or `ready=false` in WhatIf mode,
  and reserve `READY` for runs that completed the installed-version and exact
  distribution-set checks. Update the contract test accordingly.

### m-02: The documented standalone comparison accepts unsupported tool versions

- **File:line:** `scripts/compare-reference-harness.ps1:24`,
  `scripts/compare-reference-harness.ps1:38`,
  `scripts/compare-reference-harness.ps1:115`, and
  `reference/README.md:28`.
- **Failure mode:** The component command can emit
  `cross_language_structural=PASS` with arbitrary Cargo or Go versions selected
  from `PATH` or overrides. Only the combined verifier performs the exact
  version gate, so the documented standalone reproducer does not enforce the
  toolchain table that governs it.
- **Evidence:** The comparison script checks only that the resolved paths exist;
  it never invokes or validates `cargo --version`, `rustc --version`, or
  `go version` before producing a PASS candidate.
- **Required disposition:** Reuse one shared exact tool resolver/version checker
  in setup, verifier, and comparison, or require the comparison to receive a
  validated tool manifest from the verifier. Add wrong-version override tests.

Blocking=1 Major=5 Minor=2
