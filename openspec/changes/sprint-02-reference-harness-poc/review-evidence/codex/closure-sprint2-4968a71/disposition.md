# Disposition for closure-sprint2-4968a71

| Id | Severity | Disposition | Evidence |
|----|----------|-------------|----------|
| C1 | Major | **Fixed** | `OPENSPEC_TELEMETRY=0` and `DO_NOT_TRACK=1` assigned before `Get-ToolVersions`. Telemetry contract asserts call order. |
| C2 | Major | **Fixed** | Rust `build_gate_records_cbor`, Go classifier, and independent cbor2 path encode `evidence_digest` as bytes. Fixture/evidence regenerated (`gate_record_set_digest=6e75f4a9…`). |
| c1 | Minor | **Deferred / environment** | Codex sandbox TEMP denial; local full verifier green outside sandbox. |

Post-disposition verification: `pwsh -NoProfile -File scripts/verify-reference-harness.ps1` exit 0 with `structural-pass`, `deployment_outcome=blocked`, `activation_eligible=false`.

Final B/M/m for resolved audit state: **0/0/0** (C1/C2 fixed; c1 not a product defect).
