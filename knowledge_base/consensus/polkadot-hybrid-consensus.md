---
type: Concept
title: Polkadot hybrid consensus (BABE + GRANDPA) — authoritative overview
timestamp: '2026-07-09T14:43:18Z'
description: 'Authoritative overview of Polkadot''s hybrid consensus: BABE block production
  and GRANDPA provable finality run as independent services, and why that finality
  separation is the clean attestation target for a Midnight to Cardano bridge.'
resource: https://wiki.polkadot.com/learn/learn-consensus/
tags:
- polkadot
- substrate
- consensus
- babe
- grandpa
- finality
- hybrid
- prevote
- precommit
- midnight
source: src-0018
status: researched
okf_version: '1.0'
---

# Polkadot hybrid consensus (BABE + GRANDPA)

> **Why this page matters for the bridge.** Midnight is a Substrate chain and inherits
> Polkadot's *hybrid consensus*. The load-bearing property for a Midnight → Cardano
> bridge is that **finality is a separate, provable service (GRANDPA)** decoupled from
> block production (BABE). That separation gives the bridge a clean, self-contained
> object to attest to — a GRANDPA-finalized, irreversible chain — rather than a
> probabilistically-final block that could still be reorged. See
> [the recursive bridge design](../bridges/midnight-cardano-recursive-bridge.md).

## 1. Hybrid consensus: two services, two guarantees

Polkadot (and therefore Substrate-based Midnight) runs a **hybrid consensus** that
pairs two independent mechanisms:

- **BABE** — *Blind Assignment for Blockchain Extension* — the **block production**
  mechanism. It runs a per-slot VRF lottery among validators and rapidly extends the
  chain. Slots are ~6 seconds; a slot may have several candidate producers or none,
  so block timing is probabilistic. BABE alone gives only **probabilistic finality**.
- **GRANDPA** — *GHOST-based Recursive ANcestor Deriving Prefix Agreement* — the
  **finality gadget**. It runs *in parallel to block production as an independent
  service*, voting in consecutive rounds to mark blocks **provably final**.

The point of combining them is to keep the benefits of each and drop the drawbacks:
probabilistic finality never stalls block production, while provable finality removes
the "which fork is canonical?" ambiguity. Blocks are produced fast; the slower
finality process runs separately, so it never throttles transaction throughput.

See the companion pages [BABE block production](babe-block-production.md) and
[GRANDPA finality](grandpa-finality.md) for the mechanism details.

## 2. GRANDPA finality — the attestation target

GRANDPA is what a trustless bridge actually cares about:

- **Agreement on chains, not blocks.** When more than **⅔ of validators** attest to a
  chain containing a particular block, *all* blocks up to that one are finalized at
  once. This batch finalization is fast and survives long network partitions.
- **Provable (irreversible) finality.** A finalized block can *never be reverted*
  after the Byzantine-agreement process completes. This is the "provable finality"
  guarantee, distinct from Nakamoto/PoW probabilistic finality where deep blocks are
  only *statistically* safe.
- **BFT thresholds.** GRANDPA is safe in a partially synchronous model as long as ⅔
  of nodes are honest, and tolerates up to ⅕ Byzantine nodes in the asynchronous
  setting.

## 3. Fork choice: BABE builds on GRANDPA-finalized head

The two services are tied together by one rule: **BABE must always build on the chain
that GRANDPA has finalized.** Above the finalized head, where forks may still exist,
BABE picks the branch with the most *primary* (VRF-selected) blocks. The finalized
prefix is immutable; only the unfinalized tip is subject to fork choice.

This is precisely the property that makes finality a clean object to prove about: the
finalized prefix is a monotone, append-only, irreversible chain.

## 4. Relevance to a Midnight → Cardano recursive bridge

For a trustless bridge, security reduces to (a) each source chain's own finality and
(b) the soundness of the proof systems used. On the Midnight side:

- The bridge should attest to **GRANDPA-finalized state**, not merely block-produced
  (BABE) state — the former is irreversible, the latter is not. Attesting to a
  finalized prefix means the destination chain never has to reason about reorgs.
- Because GRANDPA reaches agreement on **chains** and its justification is a set of
  validator signatures over a finalized block, it is a compact, self-contained object
  — the natural input to a succinct proof that Cardano can verify.
- Polkadot already recognizes this pattern for external chains via **BEEFY** (*Bridge
  Efficiency Enabling Finality Yielder*), a secondary protocol to GRANDPA that lets a
  remote network efficiently verify finality proofs produced by relay-chain
  validators. BEEFY is the Polkadot-native analogue of what the Midnight → Cardano
  Groth16 path must accomplish with an on-Cardano verifier.

See the [recursive trustless bridge design](../bridges/midnight-cardano-recursive-bridge.md)
for how the Groth16 (Midnight → Cardano) verification path consumes such a finality
attestation.

## 5. Sources

- Primary: [Polkadot Wiki — Consensus](https://wiki.polkadot.com/learn/learn-consensus/)
  (src-0018), catalogued in the [sources index](../sources/index.md).
- Related knowledge base entries: [BABE block production](babe-block-production.md),
  [GRANDPA finality](grandpa-finality.md),
  [Midnight ↔ Cardano recursive bridge](../bridges/midnight-cardano-recursive-bridge.md),
  and the [knowledge base index](../index.md).
