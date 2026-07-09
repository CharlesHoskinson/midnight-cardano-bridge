---
type: Concept
title: Midnight ZkStdLib — in-circuit gadgets (secp256k1, bls12_381, keccak, blake2b,
  sha2/3, jubjub, poseidon)
timestamp: '2026-07-09T15:41:06Z'
description: Midnight's ZkStdLib exposes configurable in-circuit chips (secp256k1,
  bls12_381, keccak_256, blake2b, sha2/3, jubjub, poseidon) that determine which foreign-chain
  signatures and hashes a Midnight circuit can verify natively.
resource: https://github.com/midnightntwrk/midnight-zk/blob/main/zk_stdlib/README.md
tags:
- midnight
- zk-stdlib
- gadgets
- secp256k1
- bls12-381
- keccak256
- blake2b
- sha512
- jubjub
- poseidon
- circuit
source: src-0029
status: researched
okf_version: '1.0'
---

# Midnight ZkStdLib — in-circuit gadgets (secp256k1, bls12_381, keccak, blake2b, sha2/3, jubjub, poseidon)

The *Midnight ZK Standard Library* (`midnight-zk-stdlib`, exposed as `ZkStdLib`) is the high-level, developer-facing layer for building Midnight's zero-knowledge circuits. It sits on top of the lower-level `midnight-circuits` and `midnight-proofs` crates and encapsulates the configuration and chip-creation boilerplate: a developer writes only an implementation of the `Relation` trait (instance, witness, circuit logic) instead of Halo2's raw `Circuit` trait. This page catalogs the in-circuit gadgets ("chips") it can enable, because that set is exactly what bounds which foreign-chain signatures and hashes a Midnight circuit can verify natively — the crux of the Cardano↔Midnight bridge design.

## The chip catalog: `ZkStdLibArch`

Circuit capability is declared through the `ZkStdLibArch` struct, whose boolean fields toggle individual chips. A `Relation`'s `used_chips` function returns the arch it needs. The available chips are:

| Chip | Field | Bridge relevance |
|---|---|---|
| JubJub | `jubjub` | Midnight-internal signature/commitment curve (default-on) |
| Poseidon | `poseidon` | ZK-native hash for Merkle/state commitments (default-on) |
| SHA-256 | `sha2_256` | General hashing; enabled in the default arch |
| SHA-512 | `sha2_512` | General hashing |
| SHA3-256 | `sha3_256` | SHA-3 family hashing |
| Keccak-256 | `keccak_256` | **Ethereum/EVM hash** — verify EVM-style commitments in-circuit |
| BLAKE2b | `blake2b` | **Cardano/IOG hash family** — verify Cardano-style hashes in-circuit |
| secp256k1 | `secp256k1` | **ECDSA curve** — zk-wrapper over ECDSA/secp256k1 signatures |
| BLS12-381 | `bls12_381` | **BLS path** — verify BLS12-381 signatures/aggregates in-circuit |
| base64 | `base64` | Encoding gadget |
| automaton | `automaton` | Regex/state-machine gadget |

Plus `nr_pow2range_cols` (columns for the `pow2range` range-check chip; max 4). By default the architecture activates **only** `JubJub`, `Poseidon` and `sha256` — every heavier chip (secp256k1, bls12_381, keccak_256, blake2b, the wider hash set) is opt-in per circuit via `used_chips`, so a circuit pays for a foreign-chain verifier only when it declares it.

Circuits are set up and proven against an SRS (Structured Reference String) loaded with `load_srs`, sized to the circuit's `k` (log2 rows); the SHA-256 preimage example in the README exercises the pipeline end-to-end, calling `std_lib.sha2_256(...)` as an in-circuit gadget.

## Bridge implication

For a Midnight↔Cardano recursive, trustless bridge the chip catalog gives two concrete verification paths **inside a Midnight circuit**:

- **BLS path** — with the `bls12_381` chip, a Midnight circuit can natively verify BLS12-381 group operations, i.e. BLS signatures and aggregate/committee-key checks. This lines up Midnight with Cardano's BLS12-381 substrate (see [Midnight proving system — curves & commitments](/midnight/proving-system-curves.md)) and with committee-key / APK-style aggregate verification (see [APK proofs & committee keys](/proof-systems/apk-proofs-committee-key.md)).
- **ECDSA / secp256k1 zk-wrapper** — with the `secp256k1` chip, a circuit can perform secp256k1 curve arithmetic in-circuit, enabling a zk-wrapper that verifies ECDSA/secp256k1 signatures (the Cardano→Midnight leg and general EVM/Bitcoin-style key material).

The `keccak_256` and `blake2b` hash chips complete the picture: Midnight can recompute and constrain Ethereum-style (Keccak) and Cardano/BLAKE2b-style hashes in-circuit, so header/state/transaction commitments from a foreign chain can be checked without a trusted relayer. These gadgets are the primitive building blocks the [Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md) composes into a trustless verification relation.

## See also

- [Knowledge base index](/index.md)
- [Sources index](/sources/index.md)
- [Midnight proving system — Plonk/Halo2 + KZG over BLS12-381](/midnight/proving-system-curves.md)
- [APK proofs & committee keys](/proof-systems/apk-proofs-committee-key.md)
- [Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md)
