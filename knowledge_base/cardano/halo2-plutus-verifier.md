---
type: Concept
title: Halo2-Plutus verifier — verifying Halo2/KZG (BLS12-381) proofs on Cardano
timestamp: '2026-07-09T15:17:45Z'
description: An IOG open-source prototype that generates a Plutus/Plinth on-chain
  verifier for Halo2 proofs over BLS12-381, letting Cardano verify Midnight's native
  recursive proofs without a Groth16 wrapper.
resource: https://www.iog.io/news/unlocking-zero-knowledge-proofs-for-cardano-the-halo2-plutus-verifier
tags:
- cardano
- halo2
- plutus
- kzg
- bls12-381
- cip-381
- verifier
- zero-knowledge
source: src-0022
status: researched
okf_version: '1.0'
---

# Halo2-Plutus verifier — verifying Halo2/KZG (BLS12-381) proofs on Cardano

The **Halo2-Plutus verifier** ([plutus-halo2-verifier-gen](https://github.com/input-output-hk/plutus-halo2-verifier-gen))
is an IOG / Input | Output Research open-source prototype (published August 2025, under the
RSnarks workstream of the IOR 2025 proposal with Intersect and the Technical Steering Committee)
that generates and verifies zero-knowledge proofs using [Halo2](/proof-systems/halo2-plonkish.md)
and integrates them into Plutus/Plinth smart contracts on Cardano. Its stated primary goal is to
support the [Midnight-Cardano zk-bridge](/bridges/midnight-cardano-recursive-bridge.md), with
secondary uses in membership proofs, range proofs, and confidential transactions.

## Why this matters for the bridge

This is the strongest single-source evidence that **Cardano can verify Midnight's native Halo2/KZG
proofs directly, on-chain, without a Groth16 wrapper.** Midnight's proving stack is Halo2/Plonkish +
KZG over BLS12-381; Cardano exposes the [CIP-0381](/standards/cip-0381.md) BLS12-381 pairing
builtins. Halo2/KZG verification reduces to a pairing check, and the IOG team explicitly
**adapted the optimal pairing check algorithm — originally developed for BN256 — to the BLS12-381
elliptic curve**, which they call the key outcome enabling efficient recursive proof verification on
Cardano. That makes on-chain Halo2 verification a **Groth16-free option for Direction A** (Midnight →
Cardano): rather than re-proving Midnight state inside a Groth16 circuit and paying the
[on-chain Groth16 cost](/cardano/groth16-onchain-cost.md), Cardano verifies the recursive Halo2 proof
that attests Midnight's state natively.

A further advantage over Groth16 is trusted setup: Halo2 uses a **universal, updatable KZG setup**
(one ceremony reusable across all circuits), whereas Groth16 needs a fresh per-circuit setup — a
meaningful trust-model simplification for a bridge that must evolve its circuits over time.

## How the verifier works

- **Generation pipeline.** A Rust toolchain (built on the Halo2 library) takes a circuit description
  and emits a Plinth verifier. The generator uses Handlebars templates to populate Plinth Halo2
  templates with circuit-specific logic. Halo2 proofs are serialized to JSON; the corresponding
  verifier is output as Haskell files compatible with Plinth — i.e. **off-chain proving, on-chain
  verification**.
- **Circuit coverage.** Applied to several circuits including Ad-Hoc Threshold Multisignatures
  (ATMS); supports Halo2 **lookup tables and custom gates**.
- **Recursion / non-native arithmetic.** Recursive Halo2 verification requires foreign-field
  arithmetic (FFA) — operating on one curve's field inside another's SNARK circuit. The team used
  **EasyCrypt** to formally prove soundness and completeness of the FFA algorithm (and a novel MSM
  algorithm), per the paper *Efficient Foreign-Field Arithmetic in PLONK* (eprint 2025/695).

## On-chain cost and feasibility

- The article reports that **ATMS signatures can be efficiently verified on the Cardano mainnet, with
  the verifier fitting within the computational limits of a single Plutus script** — a concrete
  feasibility result (no exact ex-unit figures are given in this source; for measured Groth16 numbers
  see [on-chain Groth16 cost](/cardano/groth16-onchain-cost.md)).
- The conclusion still flags **"the high cost of verification"** as a challenge.
- To attack that cost, the team proposed **CIP-133 — Plutus support for Multi-Scalar Multiplication
  (MSM) over BLS12-381**, a built-in targeting the dominant bottleneck in SNARK proving/verification.
  Per this source, **CIP-133 has been accepted and is under implementation by the Plutus team**. MSM
  complements the existing CIP-0381 pairing/group builtins.

## Caveats

- It is a **prototype**, not production infrastructure.
- The source does not name "KZG" explicitly; the KZG linkage is inferred from Halo2's standard
  commitment scheme and the BLS12-381 pairing-check work described. Exact on-chain ex-units are not
  quantified here.

## Bridge implication (summary)

Direction A of the [Midnight ↔ Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md)
has a credible **Groth16-free path**: a generated Plinth verifier checks Midnight's recursive
Halo2/KZG proof directly using the BLS12-381 pairing builtins, backed by a universal KZG setup, with
CIP-133 MSM lined up to cut verification cost.

See also: [knowledge base index](/index.md) · [sources](/sources/index.md) ·
[CIP-0381](/standards/cip-0381.md) · [Halo2 / Plonkish](/proof-systems/halo2-plonkish.md) ·
[on-chain Groth16 cost](/cardano/groth16-onchain-cost.md).
