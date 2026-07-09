---
type: Concept
title: BEEFY — Bridge Efficiency Enabling Finality Yielder (canonical protocol)
timestamp: '2026-07-09T15:04:51Z'
description: BEEFY is a Substrate/Polkadot companion protocol that lets a remote light
  client cheaply verify GRANDPA finality via signed commitments over an MMR root,
  making it the direct structural template for the Midnight->Cardano on-chain verifier.
resource: https://raw.githubusercontent.com/paritytech/grandpa-bridge-gadget/master/docs/beefy.md
tags:
- beefy
- polkadot
- grandpa
- finality
- bridge
- mmr
- signature
- ecdsa
- bls
- light-client
source: src-0019
status: researched
okf_version: '1.0'
---

# BEEFY — Bridge Efficiency Enabling Finality Yielder (canonical protocol)

**BEEFY** ("BEEFY is a consensus protocol designed with efficient trustless bridging in mind") is the Substrate/Polkadot companion protocol whose entire purpose is to let a **remote light client** cheaply verify [GRANDPA](/consensus/grandpa-finality.md) finality in restricted environments — "optimized for restricted environments like Ethereum Smart Contracts or On-Chain State Transition Function (e.g. Substrate Runtime)." That is exactly the job of the **Midnight→Cardano** on-chain verifier, so BEEFY is the most direct existing template for it. Because [Midnight uses Substrate AURA+GRANDPA](/consensus/midnight-consensus-aura-grandpa.md), the object a Cardano-side verifier must attest is GRANDPA finality, and BEEFY shows how to compress that attestation into a single small signed structure.

## BEEFY sits on top of GRANDPA

BEEFY is **not standalone**: "BEEFY is required to be running on top of GRANDPA." It is conceptually "an extra voting round done by GRANDPA validators for the current best finalized block," lagging behind the best GRANDPA-finalized block just as GRANDPA lags behind the best produced block. This piggy-backing buys three simplifications the bridge inherits for free:

- The **BEEFY validator set is the same** as GRANDPA's (same bonded actors, possibly different session keys), so no separate authority set has to be tracked.
- BEEFY runs **only on the finalized canonical chain** ("no forks"), so a commitment can reference a block by *number* with no ambiguity.
- A **session** is "a period of time (or rather number of blocks) where validator set (keys) do not change," and session boundaries are identical to GRANDPA's — the validator-set handoff a verifier must follow is exactly the GRANDPA authority-set rotation, with the first block of each session being a mandatory block that always carries a justification.

## The commitment and signed commitment (the structure to copy)

This is the core template for the verifier. A **commitment** is the pair `(block_to_vote_on, payload_to_vote_on)`, plus the BEEFY **validator set id** at that block. The **payload** is an opaque blob that is "some form of crypto accumulator (like Merkle Tree Hash or Merkle Mountain Range Root Hash)" — i.e. an **MMR root**. A validator's **vote** is simply its signature over this commitment.

A **Signed Commitment** is "a Commitment and a collection of signatures," and "a valid Signed Commitment is also called a **BEEFY Justification** (BEEFY Finality Proof)." A justification is worthwhile only when it carries at least `2/3rd + 1` valid signatures from the current validator set. So the entire object a remote verifier checks reduces to: **one small commitment (block number + MMR root + validator-set id) plus a supermajority of validator signatures over it** — no headers, no ancestry data. The MMR root is what makes ancestry/inclusion proofs cheap: the light client verifies one signed root and then checks Merkle Mountain Range proofs against it rather than importing block headers (MMR is explicitly cited as the mechanism "for Efficient Bridges").

## Signature scheme is the cost-decisive variable

BEEFY exists because GRANDPA's own proofs are expensive to verify remotely: "GRANDPA uses `ed25519` signatures and finality proof requires `2N/3 + 1` of valid signatures," bundled with ~100-byte headers. BEEFY's stated goals are to "minimize the size of the signed payload and the finality proof" and to "allow customisation of crypto to adapt for different targets [and] support thresholds signatures" eventually.

- **Now:** BEEFY's initial cryptography is **secp256k1** (ECDSA) with **keccak256** hashing, chosen so the light client can be an Ethereum Solidity contract.
- **Planned:** **threshold / BLS** signatures — the future direction that lets the whole validator set collapse to one aggregate signature (APK-style).

For the **Midnight→Cardano** direction this is the pivotal design choice. Verifying a set of ECDSA/secp256k1 signatures in a Groth16 circuit (or in Plutus) is costly per-signature; the BLS12-381 path is far cheaper to verify and, critically, **Cardano has native BLS12-381 builtins** ([CIP-0381](/standards/cip-0381.md)), so aligning the Midnight-side BEEFY-style signature scheme with BLS+APK maps directly onto primitives the Cardano verifier already has. The [recursive bridge design](/bridges/midnight-cardano-recursive-bridge.md) should treat the BEEFY signed-commitment (MMR root + aggregate signature over a bounded validator set) as the canonical shape of the finality object to verify on-chain.

## See also

- [Knowledge base index](/index.md)
- [Sources index](/sources/index.md)
- [GRANDPA — the finality gadget BEEFY attests](/consensus/grandpa-finality.md)
- [Polkadot hybrid consensus (BABE + GRANDPA)](/consensus/polkadot-hybrid-consensus.md)
- [CIP-0381 — native BLS12-381 on Cardano](/standards/cip-0381.md)
- [Midnight↔Cardano recursive trustless bridge](/bridges/midnight-cardano-recursive-bridge.md)
