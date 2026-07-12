---
id: program.open-questions
type: question
title: Open questions
status: blocked
updated_at: 2026-07-12T02:20:00Z
sources:
  - source.design-session.2026-07-10-program-rebaseline
  - knowledge_base/proof-claims/predicate-catalog-status.md
  - docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md
  - knowledge_base/bridges/midnight-cardano-recursive-bridge.md
---

# Open questions

1. Can an official public Mithril signer population certify the exact SCLS
   descriptor and message required by the Cardano anchor?
2. Can public Midnight data reproduce the chain identity, initial BEEFY state,
   every mandatory transition, and the complete event-to-MMR relation?
3. Can the unmodified Midnight testnet operation verify the selected external
   Halo2 relation and change all destination-local state owners atomically?
4. Does the complete commitment-Groth16 BSB22 Plutus boundary fit the selected
   Cardano testnet limits with the final KZG decider enforced?
5. Where are the three source files that identify the 42 and 52 predicate rows,
   or what primary evidence can reconstruct each missing row?
6. Which KZG setup material is format- and degree-compatible with the frozen
   circuits, and which setup phases require a new human ceremony?
7. Which organizations or individuals will provide independently controlled
   ceremony contributions after circuit freeze?
8. Can Compact, cardano-node, and cardano-cli be installed and qualified under
   the frozen host and toolchain policy?
9. Can official endpoints reproducibly supply the Midnight genesis and BEEFY data
   needed to authenticate the complete public source relation?

Each question has an owning `PBT-S02`, `PBT-S03`, or `PBT-S08` package or gate.
None can be answered through an agent assertion alone.
