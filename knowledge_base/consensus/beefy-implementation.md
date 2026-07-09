---
type: Concept
title: BEEFY implementation notes (polkadot-sdk) — rounds, mandatory blocks, signatures
timestamp: '2026-07-09T15:04:04Z'
description: How the polkadot-sdk BEEFY client works — rounds, session mandatory blocks
  for validator-set handoff, signed-commitment contents, and the ECDSA signature scheme
  — read as the template for a Cardano-side Midnight finality verifier.
resource: https://raw.githubusercontent.com/paritytech/polkadot-sdk/master/substrate/client/consensus/beefy/README.md
tags:
- beefy
- polkadot-sdk
- implementation
- rounds
- mandatory-block
- signature
- validator-set
- mmr
source: src-0021
status: researched
okf_version: '1.0'
---

# BEEFY implementation notes (polkadot-sdk) — rounds, mandatory blocks, signatures

**BEEFY** (Bridge Efficiency Enabling Finality Yielder) is a *secondary* protocol that runs alongside [GRANDPA finality](/consensus/grandpa-finality.md) to make trustless bridging to non-Substrate chains cheap. It is exactly the piece a **Cardano-side verifier** for a [Midnight→Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md) should imitate: BEEFY re-packages GRANDPA finality into an object a restricted light client (originally an Ethereum smart contract; for us, a Cardano/Plutus verifier) can check with one small proof instead of re-verifying GRANDPA's variable-size, ed25519-signed justifications. This page distils the official polkadot-sdk BEEFY client README (source `src-0021`) into the details that drive a verifier design.

## Why not verify GRANDPA directly

GRANDPA finality proofs are awkward for a light client on two axes. First, GRANDPA voters vote for *different* blocks (each votes for the latest block it sees, and the protocol settles on the common ancestor with >2/3 support), so a proof must carry per-validator vote data plus extra headers to check vote ancestries — the size is variable. Second, GRANDPA signs with **ed25519**, which "we can't efficiently verify in the EVM." BEEFY exists to fix both: it fixes what is signed (a single commitment) and lets the signature scheme be chosen for the target chain.

## Mental model: BEEFY is an extra voting round on finalized blocks

BEEFY should be considered as **an extra voting round done by GRANDPA validators for the current best finalized block**. It lags behind best-GRANDPA the same way GRANDPA lags behind best-produced. Two shortcuts follow from piggy-backing on GRANDPA and matter for the verifier:

- **Same validator set.** The BEEFY validator set *is the same* as GRANDPA's (same bonded actors, possibly different session keys). A verifier that tracks the BEEFY authority set is implicitly tracking the GRANDPA/Midnight authority set.
- **Finalized, fork-free.** BEEFY only votes on GRANDPA-finalized blocks, so there is no ambiguity — a commitment can identify its block by **block number** rather than hash.

## What gets signed: the Commitment and the Signed Commitment

This is the object the Cardano verifier ultimately checks.

- A **Commitment** consists of a **payload** plus the **block number** the payload originates from.
- The **payload** is an opaque blob expected to be a crypto accumulator — in practice a **Merkle Mountain Range (MMR) root hash**. This single 32-byte-ish root is what commits to chain history; the verifier checks a signature over it and then does cheap MMR inclusion proofs against it.
- The Commitment *also* carries the **BEEFY validator set id** at that block — the anchor that lets a light client detect a validator-set handoff.
- A Commitment together with a **collection of signatures** is a **Signed Commitment**, also called a **BEEFY Justification** / **BEEFY Finality Proof**. A valid one carries at least `2/3 + 1` signatures from the current validator set. This is the whole proof object: one commitment, one accumulator root, a bag of signatures.

## Rounds

A **round** is an attempt to produce a BEEFY Justification; the **round number** is simply the block number being voted on. A round ends when the next one starts — either the node collects `2/3 + 1` valid votes, or it receives a Justification for a block beyond its best-BEEFY block. Round selection is driven by a formula over `best_grandpa`, `best_beefy`, and `session_start` that (a) first finalizes the session's mandatory block, then (b) picks the highest GRANDPA-finalized block whose distance from `best_beefy` is a power of two — so BEEFY changes rounds less often when it is lagging, raising the chance a round concludes.

## Mandatory blocks — the validator-set-handoff guarantee

This is the mechanism that lets a light client *never miss a validator-set change*, and it is the single most important property to replicate on Cardano.

- A **session** is a span of blocks over which the validator set (keys) does not change. Because BEEFY piggy-backs on GRANDPA, **BEEFY session boundaries are exactly the same as GRANDPA's**.
- Every **first block in each session is a mandatory block**. Mandatory blocks **MUST** have a BEEFY justification, and validators **always start and conclude a round at mandatory blocks** (non-mandatory blocks may be skipped).
- Consequence: there is **guaranteed to be at least one BEEFY-finalized block per session**, and it is the session's first block — precisely the block whose commitment carries the *new* validator set id.

So a verifier can follow authority-set handoffs by walking mandatory-block Justifications one session at a time: each mandatory-block Signed Commitment is signed by the *outgoing* set and announces the *incoming* set id, giving an unbroken, gap-free chain of custody of the validator set. Critically, **older sessions must be finalized by the validator set in force at that time, not the current one** ("catch up"): even if block production and GRANDPA have raced ahead into a new session, BEEFY still concludes the older session's mandatory round under the old keys — a verifier must therefore accept a mandatory-block proof against the historical set it is currently tracking, never jump sets.

## Signature scheme — the cost-decisive choice

BEEFY makes the crypto pluggable "to adapt for different targets," and this is where a Cardano verifier's cost is decided:

- GRANDPA uses **ed25519** (efficient to verify natively, but not in constrained bridge environments).
- BEEFY's **current scheme is ECDSA** (secp256k1 with keccak256), chosen so an Ethereum/EVM light client could verify it. The README flags that multiple signature schemes are intended in future, with multiple kinds of `SignedCommitment` that together form one Justification — the hook through which **BLS (BLS12-381)** aggregation is planned.
- For the Midnight→Cardano leg this matters directly: Cardano has native **BLS12-381** operations (CIP-0381), so a BEEFY-style verifier that can consume BLS-aggregated signed commitments would verify one aggregate signature over the MMR-root commitment rather than `2/3+1` individual ECDSA checks. The verifier template is BEEFY-over-GRANDPA; the signature scheme is the free variable to optimize.

## Bridge-design takeaways

1. **Verify one accumulator root, not a chain of headers.** The proof object is a Signed Commitment: (MMR root ‖ block number ‖ validator-set id) + signatures. Everything else is an MMR inclusion proof against that root.
2. **Track the authority set via mandatory blocks.** One guaranteed BEEFY-finalized block per session, at the session's first block, carrying the new set id — the gap-free handoff feed a Cardano verifier must consume in order.
3. **Handoffs are proven under the old keys.** Catch-up means a session transition is attested by the outgoing validator set; the verifier advances its tracked set only on a valid mandatory-block proof.
4. **Signature scheme is the cost lever.** ECDSA today; BLS12-381 aggregation is the planned path and aligns with Cardano's native CIP-0381 support.

## Sources

- Source register: [/sources/index.md](/sources/index.md) — `src-0021` (polkadot-sdk BEEFY client README).
- Related: [GRANDPA finality](/consensus/grandpa-finality.md), [Midnight→Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md), [knowledge base index](/index.md).
