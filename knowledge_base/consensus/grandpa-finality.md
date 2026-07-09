---
type: Concept
title: GRANDPA — Polkadot/Substrate finality gadget (Midnight's finality; bridge attestation
  target)
timestamp: '2026-07-09T14:40:21Z'
description: GRANDPA is Polkadot/Substrate's BFT finality gadget that finalizes entire
  chains via >2/3 prevote/precommit rounds; it is the finality object a Midnight->Cardano
  Groth16 bridge must attest.
resource: https://medium.com/polkadot-network/polkadot-consensus-part-2-grandpa-fb1963ef6c70
tags:
- grandpa
- polkadot
- substrate
- finality
- bft
- prevote
- precommit
- justification
- midnight
- bridge
source: src-0017
status: researched
okf_version: '1.0'
---

# GRANDPA — Polkadot/Substrate finality gadget (Midnight's finality; bridge attestation target)

**GRANDPA** (GHOST-based Recursive ANcestor Deriving Prefix Agreement) is Polkadot's and Substrate's Byzantine-fault-tolerant **finality gadget**: its purpose is to *deterministically select the canonical chain* — i.e. decide which set of changes is final. Because **Midnight** is a Substrate/Polkadot-SDK chain, GRANDPA is exactly the finality mechanism a **Midnight→Cardano** bridge must attest, and a GRANDPA finality proof is the precise object the **Groth16** circuit will verify. This makes GRANDPA structurally symmetric to Cardano's [Ouroboros Peras vote certificate](/cardano/ouroboros-peras-finality.md) on the other bridge leg.

## GRANDPA finalizes chains, not blocks

GRANDPA stands apart from other BFT blockchain algorithms in that **validators vote on *chains*, not individual blocks**. Votes are applied transitively; the algorithm finds the highest block number with a sufficient number of votes to be considered final, so **several blocks can be finalized in a single round** (observed on Kusama: one round finalized three blocks, 664,254–664,256). This "prefix agreement" is what lets a light client treat *one* finality proof as settling an entire span of blocks at once, rather than proving block-by-block.

GRANDPA is deliberately **separated from block production**: it does not produce blocks itself but imports them from a separate block-production module (**BABE**, the sibling gadget). GRANDPA imposes few constraints on those blocks — it only needs eventual safety, its own fork-choice rule, and that each block header carry a **pointer to its parent block** (the property that lets light clients follow the chain).

## A GRANDPA round: prevote → precommit → commit

Each round proceeds in two voting phases plus a commit:

1. **Primary** broadcasts the highest block it believes could be final from the previous round.
2. **Pre-vote:** after a network delay, each validator broadcasts a *pre-vote* for the highest block it thinks should be finalized.
3. **Pre-commit:** each validator computes the highest finalizable block from the set of pre-votes; if that set extends the last finalized chain, the validator casts a *pre-commit* to that chain.
4. **Commit:** each validator waits to receive **enough pre-commits to form a commit message** on the newly finalized chain.

**Threshold (the number that matters for a bridge):** a protocol step is completable only when it has **more than two-thirds of the pre-votes or pre-commits** from validators — a >2/3 supermajority in each of the prevote and precommit phases. GRANDPA supports weighted voting, but in Polkadot every validator has a single, equally weighted vote. To obtain *deterministic* finality (as opposed to probabilistic), the validator set must be **bounded/limited** in size — a light client can therefore enumerate the exact voter set and its signatures.

## BFT threshold and accountable safety

GRANDPA's safety rests on the standard BFT bound: the **maximum fraction of faulty validators is one-third** of the total (equivalently, honest validators must exceed 2/3). Concretely, with 10 validators the system withstands at most 3 faulty ones (`f = (10−1) / 3`). A **safety violation** — two blocks in *different* chains both finalized — can only happen if that bound is broken, i.e. **at least one-third of validators voted on two conflicting chains** (called *equivocating*).

GRANDPA adds **accountable safety**: if two conflicting chains finalize, honest validators reveal, for each finalized block, a set of pre-votes or pre-commits carrying a **supermajority** for that block; the intersection of the two vote sets exposes the equivocators, who can then be slashed and ejected. For a bridge this matters because equivocation is *cryptographically attributable* — the finality proof is non-repudiable signed evidence.

## What a Midnight→Cardano bridge must attest

The **finality justification** is the concrete, verifiable object. A GRANDPA justification for a finalized block is the **commit message**: the set of validator **pre-commit signatures** on that block (and, transitively, its chain), constituting **more than a 2/3 supermajority** of the bounded validator set. This is precisely the quorum-of-signatures shape as Cardano's Peras certificate — a quorum of committee votes on a block — so the two bridge legs are structurally symmetric.

For the **Midnight→Cardano** direction, the on-Cardano **Groth16 verifier** (settled in Plutus) must, given a Midnight block as public input, verify in-circuit roughly:

1. **Validator-set commitment.** The identity/public keys and weights of the current GRANDPA authority set (deterministic and bounded), plus any authority-set change proofs linking back to a trusted checkpoint — because finality is only meaningful relative to *which* validators were entitled to vote.
2. **A >2/3 pre-commit quorum.** More than two-thirds of that authority set produced valid pre-commit signatures on the target block (the commit message / justification). This signature-set verification is the core of the circuit and the direct analogue of checking a Peras quorum certificate.
3. **Block inclusion / header chain.** The target block's header chains back (via parent-hash pointers) to the finalized block the quorum signed, so inclusion is provable to a light client without the full chain.

Because GRANDPA finality is **deterministic and provable** (a bounded signed quorum), not probabilistic, the Groth16 circuit attests a *single* justification rather than a rollback-probability argument — an advantage over having to reason about depth-based settlement. The dominant in-circuit cost is verifying the validator **signature set** (and any BLS-style aggregation over it), exactly as KES/VRF signature checks dominate the Peras-certificate circuit on the other leg. See the [recursive bridge design](/bridges/midnight-cardano-recursive-bridge.md) for how this justification-verification circuit composes with the Cardano→Midnight direction.

## See also

- [Knowledge base index](/index.md)
- [Sources index](/sources/index.md)
- [Ouroboros Peras — Cardano finality (symmetric bridge leg)](/cardano/ouroboros-peras-finality.md)
- [Midnight↔Cardano recursive trustless bridge](/bridges/midnight-cardano-recursive-bridge.md)
