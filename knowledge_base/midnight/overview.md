---
type: Concept
title: Midnight — overview and dual-state (public/private) ledger model
timestamp: '2026-07-09T14:17:04Z'
description: How Midnight's dual public/private state ledger, client-side computation,
  and on-chain zk-SNARK verification shape what a Midnight<->Cardano bridge must attest.
resource: https://docs.midnight.network/what-is-midnight
tags:
- midnight
- zero-knowledge
- privacy
- dual-state
- compact
- architecture
source: src-0006
status: researched
okf_version: '1.0'
---

# Midnight — overview and dual-state (public/private) ledger model

Midnight is a data protection blockchain that pairs a public, on-chain ledger with private, client-side state, using zero-knowledge proofs to move trust between the two. This page synthesizes its architecture and draws out the implications for a recursive, trustless Midnight <-> Cardano bridge. See also the [knowledge base index](/index.md) and [sources index](/sources/index.md).

## Dual-state ledger: what is on-chain vs client-side

Midnight maintains two parallel states. The **public state** is traditional blockchain data stored on-chain and visible to all participants — it "includes transaction proofs, contract code, and any intentionally public information." The **private state** is encrypted data stored locally by users and never exposed to the network. Data minimization keeps only essential data on-chain while sensitive information stays in local storage.

For a bridge, this is the central fact: the only Midnight state a Cardano-side verifier can observe or attest to is the public on-chain state — proofs, public outputs, contract code, and shielded/standard transaction records. Private state is off-chain and out of reach; any cross-chain claim must be expressed as a fact provable from public state.

## Zero-knowledge proofs bridge public and private

Zero-knowledge cryptography is the bridge between the two states. Using zk-SNARKs, Midnight generates compact proofs of 128 bytes regardless of computation complexity and validates them in milliseconds on-chain. Selective disclosure lets a party prove facts about data without revealing the data itself.

Transaction flow: users compute on their private data locally, the runtime generates a zk-SNARK proof of that computation, and validators verify it with the zk-SNARK verification algorithm. Once verified, public state updates on-chain and private state updates in local storage. Midnight processes both standard public transactions and shielded transactions that use zero-knowledge proofs.

## Implications for the bridge

- The bridge must attest to Midnight *public* state only; the constant-size (128-byte), milliseconds-to-verify zk-SNARK proofs are attractive artifacts for a Groth16-style Midnight -> Cardano proof to reference or wrap.
- Midnight already "maintains a native bridge to Cardano for asset transfers" — a recursive trustless bridge should be contrasted against this existing native bridge's trust model.
- Because verification is fast and proofs are succinct, on-chain proof checking (and recursion over it) is feasible; the design question is finality and settlement, which ties into Cardano's [Ouroboros Peras finality](/cardano/ouroboros-peras-finality.md) and asset/standards handling under [CIP-0381](/standards/cip-0381.md).

<!-- okf:begin sources -->
## Sources

- [Midnight — What is Midnight?](https://docs.midnight.network/what-is-midnight) (`src-0006`)
<!-- okf:end sources -->
