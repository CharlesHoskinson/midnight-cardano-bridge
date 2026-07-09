---
type: Tool
title: ak-381 — Aiken Groth16 verifier using BLS12-381
timestamp: '2026-07-09T14:08:01Z'
description: An Aiken library that verifies Circom/SnarkJs Groth16 proofs on-chain
  via Cardano's BLS12-381 (PlutusV3) primitives.
resource: https://raw.githubusercontent.com/Modulo-P/ak-381/main/README.md
tags:
- cardano
- aiken
- groth16
- bls12-381
- zk-snark
- verifier
- circom
- snarkjs
source: src-0003
status: researched
okf_version: '1.0'
---

# ak-381 — Aiken Groth16 verifier using BLS12-381

`ak-381` (Modulo-P) is an [Aiken](/index.md) library that implements on-chain
zero-knowledge proof verification following the **Groth16** protocol, built on
Cardano's **BLS12-381** primitives exposed to the Plutus VM in the PlutusV3
hardfork. Its main feature is a zk-SNARK verification function plus helper
utilities to create proofs and marshal them into a form the Plutus VM accepts.
The toolchain is explicitly tailored to **Circom** circuits and the **SnarkJs**
prover.

## What it provides

- An Aiken-native Groth16 verifier callable from validators, so a proof can be
  checked inside a Cardano script rather than off-chain.
- A guided setup/prove/verify workflow (a `groth16` bash script) that runs the
  Groth16 trusted setup — which requires a multi-party computation to produce
  the prover-key and verification-key — and then proving/verification via
  SnarkJs (`snarkjs g16p` to prove, `snarkjs g16v` to verify off-chain).
- A JavaScript `conversion` module (`convert.sh`) that serializes the Circom/
  SnarkJs `proof.json` and `verification_key.json` into the byte layout the
  Plutus VM expects.

## Proof / verification-key format (relevant to the Midnight -> Cardano leg)

For the Groth16 direction of the bridge, a Midnight-side prover would need to
emit proofs a Cardano validator can consume. `ak-381` fixes the concrete
interop contract:

- Proofs and verification keys originate as standard Circom/SnarkJs Groth16
  artifacts (`proof.json`, `verification_key.json`, public signals array).
- `convert.sh` serializes these into **uncompressed** BLS12-381 point form. The
  Plutus VM can *operate on* uncompressed values, but will **not** let you store
  them as `PlutusData`.
- To persist proof/vkey as `PlutusData` (e.g. in a datum/redeemer) they must be
  in **compressed** form; the Aiken compiler can perform the uncompressed ->
  compressed transformation under the hood. (At the time of writing, direct
  compressed-form conversion in the tooling was still a future item.)

This matters for the bridge because any Midnight->Cardano Groth16 prover must
either match SnarkJs's serialization exactly or reproduce the same BLS12-381
G1/G2 encoding (compressed for storage, uncompressed for pairing checks) that
`ak-381` and the underlying curve builtins expect. The relevant curve/encoding
standard is tracked under [CIP-0381](/standards/cip-0381.md).

## Relevance to the bridge

`ak-381` is a concrete, working reference for the Groth16-on-Cardano half of a
recursive Midnight<->Cardano bridge: it demonstrates end-to-end verification of
a Circom-generated proof on-chain and pins down the exact proof/vkey
serialization a prover must target. See the [sources index](/sources/index.md)
for related material.
