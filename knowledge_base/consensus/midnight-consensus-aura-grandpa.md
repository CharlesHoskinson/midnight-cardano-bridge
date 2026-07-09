---
type: Concept
title: Midnight consensus — AURA (block production) + GRANDPA (finality), Cardano-SPO
  validators
timestamp: '2026-07-09T15:40:28Z'
description: 'Authoritative Midnight docs page: Midnight runs a modified Substrate
  consensus using AURA (not BABE) for block production and GRANDPA for finality, with
  a custom validator set drawn from Cardano SPO stake delegation.'
resource: https://github.com/midnightntwrk/midnight-docs/blob/main/docs/concepts/network-architecture/consensus.mdx
tags:
- midnight
- consensus
- aura
- grandpa
- finality
- substrate
- partner-chain
- spo
- validator
source: src-0027
status: researched
okf_version: '1.0'
---

# Midnight consensus — AURA (block production) + GRANDPA (finality), Cardano-SPO validators

This is the authoritative [Midnight docs page on consensus](https://github.com/midnightntwrk/midnight-docs/blob/main/docs/concepts/network-architecture/consensus.mdx). It **corrects an earlier assumption**: Midnight's block production is **AURA — not BABE**. Midnight runs a *modified* consensus model built on standard **Substrate primitives**, pairing **AURA for block production** with **GRANDPA for finality**. Both gadgets are extended to support Midnight's role as a **Cardano Partnerchain**.

## AURA, not BABE, for block production

**AURA (Authority Round)** is a **proof-of-authority (PoA)** algorithm that decides which validator produces each block. Validators take turns in a **round-robin** fashion using predefined slots and session keys — simple, fast, and deterministic, suited to high-throughput chains with a known validator set. This differs from many Polkadot-SDK chains that use **BABE** (slot-lottery, VRF-based) for block production; the [BABE block-production page](/consensus/babe-block-production.md) describes that alternative model. AURA is not specific to Midnight and was originally implemented in OpenEthereum. Any component reasoning about Midnight's block-authoring rule (e.g. a light client) must model AURA's round-robin authority schedule, **not** a BABE VRF lottery.

## GRANDPA for finality — the bridge attestation target

**GRANDPA** (GHOST-based Recursive ANcestor Deriving Prefix Agreement) is a **finality gadget** that provides **asynchronous, provable finality**. Crucially, it **operates independently of block production**: validators vote on chains and finalize blocks once they have sufficient support, so finality is decoupled from whoever authored the block. GRANDPA is a general-purpose Polkadot component and is not specific to Midnight; see [GRANDPA finality](/consensus/grandpa-finality.md) for its round structure and justifications.

Because GRANDPA finality is **asynchronous and provable** and independent of the (AURA) block-production layer, it — not the AURA authoring step — is the object a **Midnight→Cardano recursive trustless bridge must attest**. A GRANDPA finality proof (justification) is what the bridge's succinct proof verifies on the Cardano side. See [Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md).

## Validator set: Cardano SPO stake delegation

Unlike standard Substrate chains, Midnight uses a **custom validator set selection function**. It **accounts for stake delegation from Cardano Stake Pool Operators (SPOs)**, letting existing Cardano validators participate directly in Midnight consensus — the mechanism that makes Midnight a Cardano partner chain at the consensus layer. The model also **optionally admits permissioned validators**, supporting hybrid public/private deployments.

For a bridge, this means the GRANDPA authority set being attested is derived from Cardano SPO stake delegation (plus any permissioned validators) — the validator set and its rotation are part of what a trustless light client must track alongside GRANDPA justifications.

## Takeaways

- **Block production is AURA (PoA round-robin), not BABE.** Correct any earlier BABE-based assumption about Midnight.
- **GRANDPA provides asynchronous, provable finality independent of block production** — it is the bridge attestation target, not AURA.
- **The validator set is custom**, derived from **Cardano SPO stake delegation** with optional permissioned validators.
- Both AURA and GRANDPA are stock Substrate/Polkadot gadgets; Midnight's novelty is the Cardano-Partnerchain **validator-selection** extension, not the consensus gadgets themselves.

## Related

- [Knowledge base index](/index.md)
- [Sources index](/sources/index.md)
- [GRANDPA finality](/consensus/grandpa-finality.md)
- [BABE block production](/consensus/babe-block-production.md)
- [Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md)
