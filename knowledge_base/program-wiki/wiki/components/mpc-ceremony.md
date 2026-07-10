---
id: component.mpc-ceremony
type: component
title: Groth16 MPC framework and ceremony
status: blocked
updated_at: 2026-07-10T15:02:07Z
sources:
  - source.design-session.2026-07-10-program-rebaseline
  - C:/proof-zk-recovery@6c5dc25:proto/ceremony
  - C:/proof-zk-recovery:audit/26-mpc-ceremony-assurance-review.md
---

# Groth16 MPC framework and ceremony

Sprint 7 imports a reviewed subset of the `proof-zk-recovery` ceremony branch.
Useful inputs include the BLS12-381 BGM17 wrappers, commitment-aware Phase 2,
hash-linked transcripts, contribution verification, golden VK vectors, and the
pinned gnark memory patch.

The source branch is not accepted as a bridge ceremony implementation. It uses a
caller-supplied beacon known before contributions, couples the coordinator to a
mini circuit, caps payloads below real transcript size, reuses the same verifier
stack, and documents a single-operator Preview setup. The bridge excludes those
artifacts and fixes the framework under adversarial tests.

Agents simulate contributor behavior to test the code. Actual ceremony trust
comes later, after the exact circuits and toolchains freeze. Sprint 8 waits for
independently controlled human entropy, verifies the full transcript, derives
the keys, and checks that every deployed VK copy matches the transcript output.

Any change to a frozen circuit or setup input invalidates the affected ceremony.
