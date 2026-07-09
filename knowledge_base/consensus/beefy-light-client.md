---
type: Concept
title: BEEFY light client — remote verification (MMR proofs, ECDSA/BLS, verification
  steps)
timestamp: '2026-07-09T15:04:02Z'
description: How a BEEFY light client remotely verifies Polkadot finality via MMR
  proofs and validator signatures, and why the signature scheme (ECDSA/secp256k1 vs
  planned BLS) is cost-decisive for an on-chain verifier.
resource: https://docs.hyperbridge.network/protocol/consensus/beefy
tags:
- beefy
- light-client
- mmr
- ecdsa
- bls
- secp256k1
- bls12-381
- bridge
- verification
source: src-0020
status: researched
okf_version: '1.0'
---

# BEEFY light client — remote verification (MMR proofs, ECDSA/BLS, verification steps)

**BEEFY** (Bridge Efficiency Enabling Finality Yielder) is a *secondary* finality protocol for the Polkadot relay chain, layered on top of [GRANDPA](/consensus/grandpa-finality.md). Its whole purpose is to produce consensus proofs **cheap enough to be verified on any chain** — which makes it the exact template for the Midnight→Cardano verifier: a remote chain that must efficiently confirm Polkadot/GRANDPA finality. This page captures the concrete steps a BEEFY light client performs, why the signature scheme is cost-decisive, and what that implies for a Cardano-side verifier.

## Why GRANDPA is expensive to verify remotely

GRANDPA is an asynchronous, GHOST-based gadget: it votes on the *best chain seen so far* rather than immediately on blocks, so a naive consensus proof is "entire chains of headers from each validator" — massive data cost for a light client. Worse for a remote verifier, GRANDPA signs with **Ed25519**, which is *neither amenable to aggregation nor efficient to verify on EVM chains due to the lack of necessary precompiles*. BEEFY re-packages the same underlying finality into a form a foreign chain can check cheaply.

## The MMR accumulator: verify any header from one root

BEEFY introduces a **Merkle Mountain Range (MMR)** accumulator (`pallet-beefy-mmr`) that inserts a leaf at every block into a block-ancestry tree. This eliminates the need to reveal all headers: **with only the MMR root, the ancestry of any header in the chain can be cheaply verified**. The signed object BEEFY produces is essentially a commitment to this MMR root.

Each `MmrLeaf` carries:

- `parent_number_and_hash` — the leaf is inserted during block execution and cannot know its own block hash, so it points at the parent.
- `beefy_next_authority_set` — a `BeefyNextAuthoritySet { id, len, keyset_commitment }` holding the merkle root (`keyset_commitment`) of the **next** validator set's public keys. Light clients watch this to follow authority-set rotations and are bootstrapped with the *initial* authority-set commitment.
- `leaf_extra` — the **merkle root of all parachain headers finalized at the current relay chain block**. This is what lets a client prove an individual parachain header against the same signed root.

## What a light client actually verifies

Validators sign the latest MMR root; the signatures live in the block's finality justifications. Given signatures over that root, a consensus client:

1. **Verifies the signatures are from a known authority set** (current or next) using the authority-set commitment (`keyset_commitment`).
2. **Verifies the latest MMR leaf**, learning the latest finalized block number and hash.
3. *(Optional)* **Verifies merkle proofs of any parachain headers** it cares about, against `leaf_extra`.
4. *(Optional)* **Rotates** its authority-set commitment to the next set if the set changed.

Steps 1 (signature-set check) and 3 (MMR/merkle proofs) are the two workloads any on-chain verifier must absorb. Step 3 is cheap hashing; **step 1 — the signature set — is where the cost lives.**

## The signature scheme is the cost driver

BEEFY defines **two** signature schemes and the choice is decisive for on-chain cost:

- **ECDSA / secp256k1 (current).** Chosen as a *temporary* solution for bridging to EVM chains, which only expose the ECDSA precompile. But ECDSA does not aggregate, so **verification cost grows linearly with the validator-set size** — this both inflates cost and prevents frequently posting proofs for faster finality.
- **BLS (planned).** Once EVM chains ship a BLS precompile (EIP-2537), BLS will be used for its **aggregation** properties, combined with the **APK proofs scheme** for *accountable aggregation* of BLS public keys — collapsing N signatures to one aggregate check.

### zkBEEFY: wrapping ECDSA in a SNARK

Where BLS is not yet available, Hyperbridge instead absorbs the ECDSA cost inside a **SNARK circuit** that verifies the signatures *and* their `keyset_commitment` membership proofs. This **amortizes verification to a constant** regardless of validator-set size. Their implementation uses Aztec's **barretenberg**, which proves secp256k1 signature verification in **under 2s**. The finality object becomes a single succinct proof rather than N on-chain signature checks.

## Implication for a Cardano-side (Midnight→Cardano) verifier

The same cost structure decides the Cardano bridge leg — and here Cardano's primitives point to a specific design:

- **If Midnight/BEEFY finality is BLS12-381-based**, Cardano can verify it *near-natively*: [CIP-0381](/standards/cip-0381.md) exposes BLS12-381 G1/G2 add, scalar-mul, pairing and hash-to-curve builtins in Plutus, so an aggregated BLS signature (APK-style) over the finality commitment is a handful of builtin ops — no SNARK required for the signature check itself.
- **If finality is Ed25519 (GRANDPA) or secp256k1/ECDSA (current BEEFY)**, Plutus has no matching cheap primitive, so the signature-set verification must be pushed *inside* a proof — exactly the zkBEEFY pattern, but targeting Cardano's on-chain verifier. In this project that is a **Groth16 wrapper**: a circuit that absorbs the N validator-signature checks + authority-set membership and emits one constant-size proof that Plutus verifies. This is the direct analogue of the [Midnight→Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md) Groth16 leg.

The strategic takeaway: **BEEFY's planned BLS+APK direction is the cheapest possible target for a Cardano verifier** (aligns with CIP-0381), whereas any Ed25519/ECDSA finality forces a SNARK/Groth16 layer to make on-chain verification constant-cost. BEEFY's MMR design is independently reusable: it lets the Cardano side confirm *any* Midnight header from a single signed root.

## Sources

Fetched from [Hyperbridge BEEFY docs](https://docs.hyperbridge.network/protocol/consensus/beefy) (src-0020). See the [sources index](/sources/index.md) and [knowledge base index](/index.md).
