---
type: Concept
title: Midnight node cryptography — signature schemes (sr25519 / ECDSA / Ed25519)
  and Blake2
timestamp: '2026-07-09T15:39:03Z'
description: Authoritative Midnight docs reference on the node's signature schemes
  and hash functions, defining which scheme signs GRANDPA finality and its implications
  for a Midnight-Cardano recursive bridge.
resource: https://github.com/midnightntwrk/midnight-docs/blob/main/docs/concepts/network-architecture/cryptography.mdx
tags:
- midnight
- cryptography
- ed25519
- ecdsa
- sr25519
- grandpa
- blake2
- signature
- finality
source: src-0026
status: researched
okf_version: '1.0'
---

# Midnight node cryptography — signature schemes (sr25519 / ECDSA / Ed25519) and Blake2

This is the authoritative Midnight docs reference on the node's foundational cryptography — the algorithms outside the Midnight Ledger that secure consensus, state-transition integrity, and network communication. It is load-bearing for the Direction-A (Midnight → Cardano) finality-signature handling in the [Midnight ↔ Cardano recursive trustless bridge](../bridges/midnight-cardano-recursive-bridge.md).

## Signature schemes by role

The Midnight node uses three distinct signature schemes, selected by role:

| Scheme | Signs | Consensus role |
| --- | --- | --- |
| **sr25519** (Schnorrkel / Ristretto x25519) | Block-authorship messages in **AURA** | Block production; supports key derivation and signature aggregation |
| **ECDSA** | **Partnerchain**-related consensus messages | Interoperability with external systems where ECDSA is standard |
| **Ed25519** | **GRANDPA finality** messages, and libp2p messages (Polkadot SDK) | Finalization + peer-to-peer networking |

The single most important fact for the bridge: **GRANDPA finality messages are signed with Ed25519.** Finalization — the point at which a Midnight block is irreversible and therefore safe to relay to Cardano — is attested by Ed25519 validator signatures. See [GRANDPA finality](grandpa-finality.md).

## Hash functions

- **Blake2 256** is the primary hash function, used for general-purpose hashing including block hashes and within state-transition functions. This is the hash a bridge light client must recompute to verify Midnight block headers.
- **twoxhash** is a non-cryptographic hash used only for storage-key generation (fast, low-collision, not security-bearing).

## Bridge implication (Direction A: Midnight → Cardano)

Because Midnight finality rides on **Ed25519** GRANDPA signatures, the finality proof that Direction A must verify on Cardano is a set of Ed25519 signatures over GRANDPA vote messages. This has two hard consequences:

1. **Not natively Cardano-verifiable.** Cardano's Plutus does not offer a native Ed25519-over-arbitrary-message primitive suited to cheaply verifying a full GRANDPA validator set on-chain, and verifying many individual signatures does not scale.
2. **Not aggregatable.** Ed25519 signatures cannot be aggregated the way BLS can, so a GRANDPA finality proof is O(validators) in size and verification cost — there is no compact multi-signature.

Therefore Direction A needs one of two approaches:

- a **zk-wrapper over Ed25519** — a Groth16 (or similar) SNARK that proves "a supermajority of the Midnight validator set produced valid Ed25519 GRANDPA signatures finalizing block H," yielding a succinct proof Cardano can verify; or
- an added **BLS-based BEEFY layer** — running BEEFY alongside GRANDPA to produce aggregatable, light-client-friendly finality proofs. See [BEEFY](beefy.md).

By contrast, ECDSA (used for Partnerchain consensus) is closer to what external chains verify natively, but it attests Partnerchain consensus messages, not GRANDPA finality — so it does not substitute for the finality-signature verification Direction A requires.

## Sources

- Provenance: [`cryptography.mdx`](https://github.com/midnightntwrk/midnight-docs/blob/main/docs/concepts/network-architecture/cryptography.mdx) (`src-0026`). See the [sources index](../sources/index.md) and [knowledge base index](../index.md).
