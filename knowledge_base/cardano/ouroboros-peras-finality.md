---
type: Concept
title: Ouroboros Peras (CIP-0140) — faster settlement/finality
timestamp: '2026-07-09T14:08:52Z'
description: How Ouroboros Peras adds a voting/certificate layer to Praos for fast
  ex-post-facto settlement, and what a bridge light client must verify about Cardano
  finality.
resource: https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0140/README.md
tags:
- cardano
- ouroboros
- peras
- finality
- settlement
- consensus
- voting
source: src-0005
status: researched
okf_version: '1.0'
---

# Ouroboros Peras (CIP-0140) — faster settlement/finality

Ouroboros Peras is a proposed enhancement to Ouroboros Praos that adds a stake-weighted **voting layer** on top of Praos to deliver fast *ex post facto* settlement. It is directly relevant to a Midnight↔Cardano bridge, because in the **Cardano→Midnight** direction the Midnight-side light client must reason about the finality of the Cardano *source* chain, and Peras gives that finality a concrete, verifiable object: the **vote certificate**.

## How Peras achieves faster finality

- **Rounds and committees.** Slots are partitioned into voting rounds of `U` consecutive slots. In each round a committee of voters is selected by a Praos-style **sortition** algorithm driven by each SPO's **VRF**, so the probability of being on the committee is proportional to stake.
- **Votes → quorum → certificate.** Committee members vote for a block on their preferred chain. A **quorum** of votes for the same block in the same round is aggregated into a **certificate**. By construction there is at most one certificate per round, and every certificate must represent a quorum of recorded votes.
- **Weight boost.** A certificate adds a boost `B` to chain weight: `Wt_P(C) = len(C) + B · certCount_P(C)`. Chain selection prefers the heaviest chain, so a boosted block (and all its ancestors) becomes extremely hard to roll back.
- **Adversarial window.** A transaction is at risk only for at most `U + L` slots (`L` = block-selection offset, the minimum age before a block can be voted on). Once its block or a descendant is boosted, prior transactions are effectively final.
- **Recommended parameters** (pre-alpha): `U = 90` slots, `L > 30` slots, `B = 15` blocks, committee `n = 900`, quorum `τ = ⌈3n/4⌉ = 675`. These give **certainty within `U + L = 120` slots (~2 minutes)**: after two minutes a surviving block has less than a one-in-a-trillion rollback probability even at 45% adversarial stake.

## Security envelope and Praos fallback

Peras keeps fast settlement against adversaries holding **up to ~25%** of stake. A ≥25% adversary can withhold votes to prevent a quorum, forcing a **cool-down period** in which Peras behaves like plain Praos; the cool-down is exited only after the chain has *healed*, achieved *chain quality*, and reached a *common prefix* (governed by parameters `A`, `R`, `K`). Crucially, **Peras never weakens Praos/Genesis guarantees** — under strong attack it reverts to Praos-like probabilistic settlement for a period somewhat longer than the Praos security parameter `k`. So a Peras-based finality proof is an *optimistic fast path*; the *worst-case* guarantee remains Praos's exponential-rollback bound.

## What a bridge light client must prove about Cardano finality

For the **Cardano→Midnight** direction, a light client that wants to accept a Cardano transaction as final (without downloading the full chain) would have to verify, in-circuit or on-chain, roughly the following:

1. **The block is on the honest/preferred chain** — a valid header chain up to the block, with each header's slot-leadership (VRF) and signature valid, as in Praos.
2. **A vote certificate boosts the block or a descendant.** The certificate is the finality object. Each vote is a fixed **710-byte** structure (`voter_id`, `voting_round`, `block_hash`, VRF membership proof, voting weight, and **KES** signature) that reuses the block-header's VRF/KES key structure. A light client verifying finality must check that a quorum (`τ`) of committee members — validated via `IsCommitteeMember` (VRF membership proof + weight) and vote signatures — voted for the target block in one round, i.e. that the aggregated certificate is well-formed and points into the block on the chain.
3. **The certificate is bound to the current stake distribution**, since committee membership and quorum size are stake-weighted; the light client needs the epoch's stake distribution to check sortition weights.
4. **Fallback awareness:** if no certificate exists (a cool-down period), the client must fall back to Praos-style depth/confirmation reasoning rather than assume fast finality.

This makes the certificate/quorum the natural "finality witness" a **Groth16/Plonk** bridge circuit would attest to. Practical caveats for a circuit implementation: KES/VRF signature verification and BLS-style certificate aggregation are the expensive primitives; the on-ledger `peras_cert` field is only present at cool-down boundaries, so most certificates live off-chain (diffused as votes) and must be supplied to the client as witness data. The precise vote/certificate aggregation scheme is deferred by CIP-0140 to a companion CIP (*Votes & Certificates on Cardano*).

## See also

- [Knowledge base index](/index.md)
- [Sources index](/sources/index.md)
