---
type: Concept
title: APK proofs / committee key scheme — accountable BLS light client for PoS bridges
timestamp: '2026-07-09T15:16:55Z'
description: The w3f apk-proofs committee-key SNARK proves an aggregate BLS public
  key is formed from a threshold subset of a committed validator set, serving as the
  accountable-light-client core for both directions of a Midnight-Cardano recursive
  bridge.
resource: https://raw.githubusercontent.com/w3f/apk-proofs/master/README.md
tags:
- apk-proofs
- bls
- aggregation
- committee-key
- light-client
- bridge
- snark
- accountable
- bls12-381
source: src-0025
status: researched
okf_version: '1.0'
---

# APK proofs / committee key scheme — accountable BLS light client for PoS bridges

## What the scheme proves

The Web3 Foundation **apk-proofs** work (a.k.a. the *committee key scheme*) is a family of custom, non-interactive succinct arguments of knowledge (SNARKs) that compute and prove the correctness of an **apk** — the *aggregate public key* of the actual signers of a message. BLS signatures on a common message aggregate into a single signature verifiable in constant time, but only if the verifier already holds the aggregate public key of the signer set. Deriving that apk naively is *linear* in the number of signers and forces the verifier to know every individual public key.

apk-proofs removes exactly that cost. The prover supplies a SNARK; the verifier is given only:

1. a **commitment to the list of public keys** of all eligible signers (the committed validator/committee set), and
2. a **bitmask** identifying which of those eligible signers actually signed.

From these, the proof convinces the verifier that the claimed apk is the correct aggregate of the subset selected by the bitmask — without the verifier ever touching the individual keys. Because the bitmask names exactly who signed, the scheme is **accountable**: it is not merely "some aggregate signature verified," but "*these specific* committee members signed," and (via the *Counting* variant) that at least a threshold *t* of them did. This is the primitive that turns a raw BLS aggregate into a "≥ 2/3 of the committed validator set signed" statement.

## Why it is the accountable-light-client core for the bridge

The scheme was designed specifically as the cryptographic core for **accountable light clients bridging PoS blockchains** — a light client that can be run cheaply by a verifier that is constrained resource-wise and computation-wise, explicitly including **smart contracts on blockchains** (and mobile phones). The repository ships a sketch of such a blockchain light-client design that exploits these proofs, and the formal write-up develops the security model and the application to accountable light clients for PoS chains.

For the Midnight ⇄ Cardano recursive trustless bridge (see [/bridges/midnight-cardano-recursive-bridge.md](/bridges/midnight-cardano-recursive-bridge.md)) this matters because *both* directions reduce to the same question: **did a supermajority (≥ 2/3) of a known validator/stake set attest to a state?**

- On the **Midnight side**, finality is carried by BLS-signed [BEEFY](/consensus/beefy.md) commitments over a validator set whose handoffs are anchored by [GRANDPA finality](/consensus/grandpa-finality.md); apk-proofs lets a Cardano-side verifier confirm the ≥ 2/3 BLS threshold succinctly instead of checking every validator signature.
- On the **Cardano side**, the analogous stake-threshold attestation can be expressed against a committed key/stake set with the same commitment-plus-bitmask verifier interface.

Because a smart-contract verifier only needs the succinct apk proof plus the committed key set and bitmask, the *same* committee-key mechanism serves as the shared accountable-signing core for both bridge directions, keeping on-chain verification cheap enough for recursive composition.

## Schemes and benchmarks

The repository provides three custom constructions of increasing capability:

- **Basic Accountable Scheme** — proves the apk for the bitmask-selected signers.
- **Packed Accountable Scheme** — a more efficient packed variant.
- **Counting Scheme** — additionally proves how many committee members signed, i.e. the ≥ *t* threshold.

Benchmarks in the README (basic scheme, committee size N = 2^10) report a prover time of roughly 520.741 ms against a verifier time of roughly 25.871 ms — the asymmetry (fast verifier, heavier prover) is precisely what a light client / on-chain verifier needs. The formal description, security model, and PoC live in the w3f/apk-proofs repository and the associated IACR eprint 2022/1205.

## Provenance

Source: [w3f/apk-proofs README](https://raw.githubusercontent.com/w3f/apk-proofs/master/README.md) (`src-0025`). See the [knowledge base index](/index.md) and the [sources index](/sources/index.md).
