---
type: Concept
title: BABE — Polkadot/Substrate block production (ecosystem background)
timestamp: '2026-07-09T14:40:24Z'
description: How BABE assigns slot leaders via a VRF lottery to produce blocks that
  GRANDPA then finalizes — the block-production model Midnight adopts as a Cardano
  partner chain.
resource: https://medium.com/polkadot-network/polkadot-consensus-part-3-babe-dcc2e0dd8878
tags:
- babe
- polkadot
- substrate
- consensus
- block-production
- slot-leader
- vrf
- midnight
source: src-0016
status: researched
okf_version: '1.0'
---

# BABE — Polkadot/Substrate block production (ecosystem background)

> **Scope note (important).** This page is **Polkadot/Substrate ecosystem background**,
> *not* a claim about Midnight's block production. Per Midnight's authoritative docs,
> **Midnight uses [AURA](midnight-consensus-aura-grandpa.md) (not BABE)** for block
> production, with [**GRANDPA**](grandpa-finality.md) for finality. BABE is retained here
> because it is the Polkadot family's better-known block-production engine and clarifies
> the general "probabilistic production + provable GRANDPA finality" split that Midnight
> also follows. What matters for the [bridge](../bridges/midnight-cardano-recursive-bridge.md)
> is that the Midnight → Cardano proof targets the **GRANDPA-finalized prefix**,
> regardless of whether blocks were produced by AURA or BABE.

Source: Joe Petrowski, *Polkadot Consensus Part 3: BABE* ([src-0016](../sources/index.md)).

## 1. What BABE is

**BABE** (Blind Assignment for Blockchain Extension) is Polkadot's / Substrate's
**block-production engine**, inspired by the Ouroboros Praos proof-of-stake protocol.
It can run on its own — because it provides **probabilistic finality** — or be coupled
with a finality gadget like GRANDPA. Polkadot runs it in the coupled configuration:
**BABE builds, GRANDPA finalizes.** (Midnight follows the same *split* but with **AURA**
as the block producer instead of BABE — see [Midnight consensus](midnight-consensus-aura-grandpa.md).)

## 2. Slots and epochs

BABE is a **slot-based** algorithm. It breaks time into **epochs**, and each epoch into
**slots**. In Polkadot each slot is **six seconds** long — the target block time — and
BABE selects one (or several) authors to author a block in each slot.

## 3. Slot leaders: a VRF lottery with a round-robin fallback

Rather than a predictable round-robin (which would let adversaries know the next author
in advance and coordinate attacks), BABE assigns each slot a **primary** and a
**secondary** leader:

- **Primary slot leaders** are chosen by a private lottery: leadership is granted by
  evaluating a **VRF** (verifiable random function). The VRF takes an epoch random seed
  (agreed in advance by all nodes), a slot number, and the author's private key. For any
  slot whose VRF output falls **below an agreed-upon threshold**, that validator has the
  right to author the block. Because assignment is random, a slot may have **no primary**
  or **several primaries**.
- **Secondary slot leaders** fill the gaps via a **round-robin** fallback: if no primary
  claims the slot, the secondary authors, guaranteeing every slot has a block author and
  a consistent block time.

## 4. How BABE and GRANDPA combine

This is the load-bearing relationship for the bridge:

1. **BABE must build on a chain already finalized by [GRANDPA](grandpa-finality.md).**
   That is the first rule of BABE's chain selection and a requirement of using GRANDPA.
2. **Fork choice:** since a slot can have multiple primaries, BABE chains fork. BABE's
   best chain is simply the one with the **most blocks authored by primaries**. Having a
   well-defined best chain is what gives BABE its **probabilistic finality** (and is why
   it could be used standalone).
3. **Division of labour:** BABE produces blocks efficiently (block gossip is *O(n)* — an
   author just broadcasts) and **GRANDPA finalizes a set of them**. GRANDPA's finality is
   provable and irreversible; BABE's is only probabilistic.

## 5. Consequence for Midnight → Cardano

A trustless Midnight → Cardano attestation cannot safely commit to a
probabilistically-produced **chain tip**, which can still reorg (on Midnight that tip
is produced by [AURA](midnight-consensus-aura-grandpa.md), not BABE). The **finalized
prefix** is defined by GRANDPA, so the bridge's succinct finality proof (per the
[bridge design](../bridges/midnight-cardano-recursive-bridge.md)) should attest a
**GRANDPA-finalized** Midnight block. BABE (this page) is Polkadot background that
illustrates the same probabilistic-production / provable-GRANDPA-finality split. See
[GRANDPA finality](grandpa-finality.md) for the finality gadget itself.

---

*Part of the consensus study for the Midnight ↔ Cardano bridge.* Back to
[knowledge base index](../index.md) · [sources](../sources/index.md).
