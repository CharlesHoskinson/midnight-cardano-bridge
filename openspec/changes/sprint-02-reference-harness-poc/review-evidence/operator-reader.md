# Sprint 2 Operator / Reproducibility Review (Closure)

## Snapshot SHA

Closure review against the Sprint 2 remediation tip (post Codex C1/C2 fixes).
Re-verify with `git rev-parse HEAD` on the branch before archive.

Review used the current snapshot only.

## Scope

Reviewed setup, comparison, verifier, control tests, Python hash lock, evidence
publication, host capability receipt, and documentation for offline/read-only
contracts and non-claims.

## Commands And Results

1. `git rev-parse HEAD` -> `4968a71a8373c6a38a6b37af6ca89df30627ed32`
2. `pwsh -NoProfile -File scripts/setup-reference-harness.ps1 -WhatIf` -> PASS;
   emits `setup=reference-harness state=PLANNED` and `ready=false`
3. `pwsh -NoProfile -File scripts/tests/setup-reference-harness.contract.ps1` -> PASS
4. `pwsh -NoProfile -File scripts/tests/openspec-telemetry.contract.ps1` -> PASS
5. `pwsh -NoProfile -File scripts/tests/verify-reference-harness.integration.ps1` -> PASS
6. `pwsh -NoProfile -File scripts/verify-reference-harness.ps1` -> PASS;
   evidence-publication byte-identical; `structural-pass` / `blocked` /
   `activation_eligible=false`

## Prior Finding Dispositions

### B-01 OpenSpec telemetry — fixed

- **File:line:** `scripts/verify-reference-harness.ps1:756-757`,
  `scripts/verify-reference-harness.ps1:926-928`
- Sets and asserts `OPENSPEC_TELEMETRY=0` and `DO_NOT_TRACK=1`. Telemetry
  contract test isolates config/data homes.

### M-01 structural bindings — fixed by contract choice

- Structural report is payload-only. Conformance envelope binds
  `structural_report_sha256`, inputs, structured commands, tools, and result
  (`report_role=envelope`, `structural_payload_role=payload-bound-by-hash`).
- Spec: `openspec/changes/sprint-02-reference-harness-poc/specs/reference-harness/spec.md`

### M-02 command provenance — fixed

- Commands are recorded through `Invoke-Recorded` /
  `New-CommandRecord` with logical tool, executable identity, cwd, argv,
  offline environment, exit code, and optional inline-source SHA-256.
  Paths are normalized to `${REPO}` / `${RUN_TEMP}`.

### M-03 Python artifact lock — fixed

- `reference/observers/requirements.hashes.txt` pins Windows CPython 3.14
  artifacts. Setup installs with
  `pip --require-hashes --only-binary=:all:`.

### M-04 crash-safe publication — fixed

- **File:line:** `scripts/verify-reference-harness.ps1:657+`
- Stages immutable generation under `reference/evidence/generations/<id>/` on
  the repository volume, verifies the pair, mirrors convenience copies, then
  publishes `current-generation.json` last. Readers reject incomplete or
  hash-mismatched generations.

### M-05 control tests / bootstrap — fixed

- Verifier runs setup contract, compare tests, late-failure integration, and
  telemetry contract without recursive control orchestration
  (`MCB_SKIP_CONTROL_TESTS=1` in the isolated late-failure copy).
- Bootstrap qualification receipt:
  `reference/evidence/bootstrap/clean-checkout-qualification-v1.json`

### m-01 WhatIf READY — fixed

- WhatIf emits `PLANNED` / `ready=false`. READY reserved for completed install.

### m-02 standalone comparison tool versions — fixed

- Comparison validates exact Cargo/Rustc/Go versions or a prior tool manifest.

### Host capability reconciliation — fixed

- Canonical design dated probe updated for WSL2 + Docker-in-WSL availability
  and absence of Compact/cardano tools.
- Receipt: `reference/evidence/host-probes/host-capability-2026-07-10.json`
- Non-claim preserved: Docker/WSL are not deployment readiness.

## Blocking

None.

## Major

None.

## Minor

None.

Blocking=0 Major=0 Minor=0
