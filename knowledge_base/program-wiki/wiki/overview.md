---
id: program.overview
type: overview
title: Public-testnet proof bridge program
status: blocked
updated_at: 2026-07-10T15:02:07Z
sources:
  - source.design-session.2026-07-10-program-rebaseline
  - docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md
---

# Public-testnet proof bridge program

The program builds two proof paths between unmodified Cardano and Midnight
public testnets. Cardano facts use a Halo2/Plonkish proof accepted by a Midnight
operation. Midnight facts use a complete Halo2/KZG decision relation wrapped in
commitment-Groth16 BSB22 for a Plutus validator.

The program is blocked at its public feasibility and source-catalog gates. The
current repository has a structural harness, protocol drafts, source research,
and gate definitions. It does not have the public source roots, complete proof
relations, deployed destination verifiers, or transactions needed for
`live-pass`.

Execution uses 14 sprints and 100 work packages. [[sprints/overview]] records the
boundaries. [[risks/public-chain-gates]] records the public capabilities that can
stop the program before expensive circuit and deployment work.
