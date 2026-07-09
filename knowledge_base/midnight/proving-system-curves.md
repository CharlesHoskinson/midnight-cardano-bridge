---
type: Concept
title: Midnight proving system — Plonk/Halo2 + KZG over BLS12-381 (curves & commitments)
timestamp: '2026-07-09T15:17:59Z'
description: Midnight's proof stack is a Plonk/Halo2 implementation using KZG commitments
  over BLS12-381 with JubJub, forked from PSE halo2 (Zcash Sapling lineage) — putting
  Midnight on the same BLS12-381 substrate as Cardano's CIP-0381.
resource: https://raw.githubusercontent.com/midnightntwrk/midnight-zk/main/README.md
tags:
- midnight
- halo2
- plonk
- kzg
- bls12-381
- jubjub
- aggregation
- proving-system
source: src-0023
status: researched
okf_version: '1.0'
---

# Midnight proving system — Plonk/Halo2 + KZG over BLS12-381 (curves & commitments)

This page resolves a question left open by Midnight's high-level concept docs
(see [Midnight — zero-knowledge proof model](/midnight/zero-knowledge-proofs.md)):
**which concrete proving system, polynomial-commitment scheme, and curve does
Midnight run?** The answer, taken from the `midnight-zk` repository README
(`src-0023`), is direct and load-bearing for the bridge study. See the
[sources index](/sources/index.md) and the [knowledge base index](/index.md).

## What the source establishes

The `midnight-zk` repository "implements the proof system used in **Midnight**",
and its component breakdown pins down the whole cryptographic substrate:

- **Proving system = Plonk, commitment = KZG.** The `proofs` component is a
  "Plonk proof system using KZG commitments." This is a Plonkish/Halo2-style
  arithmetization with a **KZG polynomial-commitment scheme** — not IPA, and not
  Groth16.
- **Curves = BLS12-381 and JubJub.** The `curves` component is an
  "Implementation of elliptic curves used in Midnight, concretely BLS12-381 and
  JubJub." KZG requires a pairing-friendly curve; Midnight's is **BLS12-381**,
  with **JubJub** as the embedded (in-circuit) curve for efficient EC operations
  inside BLS12-381 circuits.
- **Lineage = PSE halo2 → Zcash Sapling.** The `proofs` crate "began as a fork
  of `halo2` v0.3.0" — the halo2 by the Privacy Scaling Explorations (PSE) team,
  "itself originally derived from the Zcash Sapling proving system." The
  `bls12_381`/`jubjub` code originated as forks of Filecoin's `blstrs` and
  Zcash's `jubjub`.
- **Divergence.** These components "are no longer maintained as forks and have
  evolved into standalone implementations tailored to Midnight's needs" — so
  Midnight is API-compatible in spirit with the PSE/Zcash Halo2 lineage but is
  now its own codebase.
- **Aggregation.** An `aggregator` component provides "proof aggregation of
  midnight-proofs," the repository's mechanism for composing/batching proofs.

## Curve and commitment findings

| Property | Midnight (`midnight-zk`) |
| --- | --- |
| Proving system | Plonk (Plonkish / Halo2 lineage) |
| Polynomial commitment | **KZG** (universal/updatable SRS) |
| Pairing curve | **BLS12-381** |
| Embedded curve | JubJub |
| Upstream | PSE `halo2` v0.3.0 ← Zcash Sapling |

Two points matter for the bridge. First, **KZG over BLS12-381** means Midnight
uses a *universal, updatable* structured reference string (one setup reused
across circuits), in contrast to **Groth16's per-circuit trusted setup**.
Second, the aggregation story: the README documents an `aggregator` component
for proof aggregation of midnight-proofs, but does **not** detail the recursion/
aggregation construction — that remains an open item to confirm from a more
detailed Midnight source. What is firmly established here is that the base layer
is **KZG over BLS12-381** (a single universal SRS).

## Bridge implications (Midnight ↔ Cardano)

The decisive result is that **Midnight and Cardano sit on the same BLS12-381
substrate.** Cardano's [CIP-0381](/standards/cip-0381.md) adds BLS12-381
built-ins (pairing, hashing-to-curve, and field/group operations) to Plutus, and
Midnight's proving stack is natively BLS12-381 (KZG). A recursive, trustless
bridge therefore does **not** need to bridge across incompatible curve families;
both legs can express and check proofs whose security rests on the same
BLS12-381 pairing.

Implications for each leg:

- **Cardano → Midnight.** A Midnight-side verifier is a Plonk/KZG verifier over
  BLS12-381 (the [Halo2/Plonkish](/proof-systems/halo2-plonkish.md) family).
  Because KZG uses a **universal** SRS, the trust assumption is a single
  updatable ceremony shared across circuits rather than a fresh per-circuit
  ceremony.
- **Midnight → Cardano.** Cardano can verify BLS12-381 proofs on-chain via the
  CIP-0381 built-ins. Whether the on-chain verifier checks a KZG/Plonk proof
  directly or a Groth16 wrapper, the underlying pairing arithmetic is the same
  curve Midnight already proves over — removing the cross-curve barrier that
  would otherwise force expensive non-native emulation.

This confirms the study's working hypothesis: **Midnight is a BLS12-381 + KZG
Plonk/Halo2 system**, aligning it with Cardano's CIP-0381 curve choice and
making a recursive Midnight↔Cardano bridge a shared-substrate problem. See the
[Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md)
page for how this feeds the end-to-end design.

## Open items to confirm

- The concrete **recursion / proof-aggregation** construction behind the
  `aggregator` component — not detailed in this README.
- The exact **KZG SRS / ceremony** Midnight uses and its updatability guarantees.
- Proof-size and verifier-cost figures a Cardano on-chain verifier must budget.
