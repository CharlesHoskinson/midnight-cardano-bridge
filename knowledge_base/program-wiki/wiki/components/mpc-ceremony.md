---
id: component.mpc-ceremony
type: component
title: Groth16 MPC framework and ceremony
status: blocked
updated_at: 2026-07-11T05:16:21Z
sources:
  - source.design-session.2026-07-10-program-rebaseline
  - source.external.proof-zk-recovery-mpc.2026-07-10
  - source.external.gnark-bsb22-mpc.2026-07-10
  - source.external.proof-zk-recovery-mpc.2026-07-12
  - source.external.gnark-bsb22-mpc.2026-07-12
  - docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md
  - docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md
---

# Groth16 MPC framework and ceremony

Sprint 7 may import a provenance-pinned candidate subset of the local
`proof-zk-recovery` ceremony branch after `PBT-S07-W01` confirms its upstream
identity and license.
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

Before enrollment, `PBT-S08-W01` must publish
`ContributorIndependencePolicyV1`. It freezes numeric human and organization
thresholds, accepted public identity anchors, separate recovery and
administration domains, environment-diversity evidence, two adjudicators from
different control domains, and an appeal path. Its failure conditions include a
duplicate identity anchor, shared credential or recovery control, a shared
entropy seed, an agent or coordinator key in the counted set, missing or
contradictory environment evidence, insufficient organization diversity, and
any unresolved Sybil indicator. A failure records `waiting-external`; the
coordinator cannot waive it or lower the frozen count. Agent simulations can
exercise this policy but never satisfy it.

The pinned commitment-aware gnark suite contributes `tau`, `alpha`, and `beta`
in Phase 1. Every circuit-specific Phase 2 contributes `delta` plus one `sigma`
per commitment group. Replay verifies each update and PoK, derives each
`GSigmaNeg`, and checks that key sealing uses the standard BLS12-381 G2 generator
for `gamma`; gamma is not a Phase 2 contribution.

KZG acceptance also requires independent algebraic replay. Two implementations
verify every selected ceremony contribution proof, the update relation across
all declared G1 and G2 powers, cross-group consistency, degree and prefix
preservation, and final SRS byte equality with the sealed head. Altered,
omitted, duplicated, reordered, inconsistent, or cross-transcript powers reject;
a catalog hash and beacon record alone are insufficient.

New or update KZG transcripts, Groth16 Phase 1, and per-circuit Phase 2 each have
their own precommitted future beacon, domain, close point, counted contributor
set, sealed head, acknowledgements, and public anchor. The schedule key is the
complete tuple of setup kind, stable transcript id, SRS-profile id, phase, and
circuit id or no-circuit sentinel. A sealed historical KZG SRS instead requires
`HistoricalCeremonyQualificationV1`, which verifies its original precommitment,
chronology, beacon, contributor policy, transcript algebra, public anchors, and exact final bytes.
The bridge cannot add a new beacon to old bytes. Missing historical evidence
blocks or forces a rebaseline when the destination requires those constant
bytes. Each counted human contribution needs
a signed receipt, independent publication, and an acknowledgement that it
remains in every final head the person joined. A valid tail that omits a counted
contribution, or a head sealed with another transcript's beacon, does not satisfy
the human-participation gate.

The frozen circuit manifest includes a KZG binding profile. That profile states
whether verifier material is constant or authenticated input and fixes its
degree, encoding, transcript identity, input slots, and equality constraints.
If the public destination cannot support that exact profile, the program stops
before circuit or ceremony work continues.

A circuit, setup-interface, KZG binding-profile, or constant-bound SRS change
returns to circuit freeze. For `new-or-update`, participant-policy,
contribution, beacon, sealed-head, or authenticated-input ceremony-output drift
repeats the affected human ceremony under the unchanged frozen interface. For
`historical-qualified`, the same drift reruns historical qualification; failed
original evidence blocks or forces a rebaseline rather than changing the sealed
bytes.
