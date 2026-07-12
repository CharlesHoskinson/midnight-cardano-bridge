---
type: Concept
title: Midnight zero-knowledge proof model (Halo2/Plonkish)
timestamp: '2026-07-11T04:03:12Z'
description: How Midnight's zk-SNARK proving model works and what it implies for a
  recursive Midnight<->Cardano bridge.
resource: https://docs.midnight.network/concepts/zero-knowledge-proofs
tags:
- midnight
- zero-knowledge
- halo2
- plonk
- proving
- recursion
source: src-0007
status: researched
okf_version: '1.0'
---

# Midnight zero-knowledge proof model (Halo2/Plonkish)

This page summarizes Midnight's official concept documentation on zero-knowledge
proofs and draws out the implications for a recursive Midnight<->Cardano bridge.
Here, `trustless` applies only to a profile whose proof, setup, official-root,
governance, and destination-verifier assumptions are explicit and satisfied. See the [sources index](/sources/index.md) (`src-0007`)
and the [knowledge base index](/index.md) for related material.

> Scope note: the cited source is a high-level concept page. It establishes that
> Midnight uses **zk-SNARKs** and describes their generic setup/prove/verify
> lifecycle, but it does **not** on this page name the concrete scheme (Halo2 /
> Plonkish), the curve, the trusted-setup ceremony, recursion, or the proof
> server. Claims below are limited to what the page actually asserts; the
> bridge analysis flags where a claim is a design implication rather than a
> documented fact. More specific Midnight implementation sources resolve the
> selected backend as Plonk/Halo2 with KZG over BLS12-381 and an updatable
> universal trusted SRS.

## What the source establishes

- **Midnight uses zk-SNARKs**, or "zero-knowledge succinct non-interactive
  arguments of knowledge," a class of ZKPs chosen for compact proofs and
  efficient verification.
- **Succinctness**: proof size stays small relative to the size of the
  statement, giving efficient verification and reduced data transfer.
- **Non-interactivity**: a prover produces a proof with no back-and-forth with
  the verifier (no multi-round interaction).
- **Setup phase**: the scheme establishes **public parameters** used by both the
  proving and verification algorithms, and those parameters are "critical to
  scheme security and correctness."
- **Circuit model**: a statement is encoded as an **arithmetic circuit** of
  operations and constraints.
- **Prove**: the prover combines the **private witness**, the circuit, and the
  public parameters to produce a proof of validity without revealing the
  witness.
- **Verify**: the verifier checks validity from the proof, public parameters,
  and the statement.
- **Cryptographic basis**: proof generation and verification use advanced
  constructions "including elliptic-curve-based techniques" plus hashing
  primitives.

## Bridge implications

The bridge is asymmetric by design: **Groth16 for the Midnight -> Cardano leg**
and **Plonk/Halo2 for the Cardano -> Midnight leg**. This source informs both
directions.

### Cardano -> Midnight (a Midnight-side verifier)

The relevant fact the source pins down is the **setup phase producing public
parameters shared by prover and verifier**. Any statement verified on the
Midnight side is expressed as an **arithmetic circuit** with a **private
witness / public input** split and checked succinctly and non-interactively,
exactly the shape a Plonkish/Halo2 verifier consumes. Halo2 is an
arithmetization framework and can be paired with IPA or KZG; it does not imply a
transparent setup. The selected Midnight implementation uses KZG over BLS12-381
with an updatable universal trusted SRS, as documented in
[proving system and curves](proving-system-curves.md) and
[proof recursion](midnight-proofs-recursion.md).

### Midnight -> Cardano (a Groth16 prover feeding a Plutus verifier)

For this leg, a Midnight-side proof must be reducible to a **Groth16** proof that
a Cardano validator can check on-chain. The source's generic
witness/circuit/public-parameter framing is compatible with that, but Groth16 on
Cardano imposes concrete constraints documented elsewhere in this KB:

- the on-chain verifier and BLS12-381 point/serialization contract in
  [ak-381: Aiken Groth16 verifier](/cardano/ak-381-aiken-groth16.md);
- the Plutus-side verification mechanics in
  [Groth16 verifier on Plutus](/cardano/groth16-verifier-plutus.md).

The commitment-Groth16 BSB22 wrapper uses reusable Groth16 Phase 1 (Powers of Tau)
material followed by a circuit-specific commitment-aware Phase 2 that yields proving and verification keys. Both
directions inherit the KZG SRS trust assumption. The Midnight -> Cardano path
adds the BSB22 Phase 2 assumption for each distinct wrapper circuit; the reverse
leg is not transparent.

## Resolved and open questions

- Resolved by the specific implementation sources: the selected Midnight stack
  is Plonk/Halo2 with KZG over BLS12-381 and a universal/updatable trusted SRS.
- Specific implementation sources also resolve recursion: the pinned Midnight
  proof-stack material documents the selected recursive composition path. The
  high-level concept source summarized here does not establish that fact alone.
- Where does proving run (client-side witness generation, proof server), and
  what are the resulting proof-size / verification-cost figures a Cardano
  on-chain Groth16 verifier and a Midnight verifier must budget for?
