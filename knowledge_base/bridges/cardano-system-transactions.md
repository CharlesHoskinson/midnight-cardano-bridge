---
type: Concept
title: Cardano→Midnight system transactions (CMST) — the current trusted observation
  interface
timestamp: '2026-07-09T16:05:55Z'
description: How Midnight observes Cardano events via block-producer-constructed system
  transactions, relying on Cardano as a trusted layer at launch.
resource: https://github.com/midnightntwrk/midnight-ledger/blob/ledger-8/spec/cardano-system-transactions.md
tags:
- midnight
- cardano
- cmst
- system-transaction
- partner-chain
- trusted-layer
- bridge
- observation
source: src-0030
status: researched
okf_version: '1.0'
---

# Cardano→Midnight system transactions (CMST) — the current trusted observation interface

This page summarizes the authoritative Midnight ledger spec for the **Cardano→Midnight
interface**: how Midnight observes events that occur on Cardano and persists them in the
Midnight ledger. It is the *current* mechanism that a [recursive trustless
bridge](midnight-cardano-recursive-bridge.md) is designed to replace on this
direction. See also the [knowledge base index](/index.md) and the
[sources index](/sources/index.md).

## Trusted-at-launch model

> "At launch, Midnight will rely on Cardano as a trusted layer."

This is the load-bearing premise. Certain information relevant to Midnight is recorded
on Cardano; it must then be **observed** on Cardano and **persisted** in the Midnight
ledger in the form of system transactions. At launch, Midnight does *not* verify that
these observations are faithful with a cryptographic proof — it **trusts** them. The
spec is explicit that verification "assumes that the verifier fully trusts the block
producer to correctly determine the block range," and that a Midnight validator "fully
trusts the range of blocks specified in the header, or blindly accepted the fact that
Midnight block does not contain a CMST." This trust is exactly what a *trustless* bridge
removes: it replaces trusted observation with proof-based verification of the same
Cardano events.

## CMST structure: Header + Body

A **Cardano-based Midnight System Transaction (CMST)** consists of two components:

- **Header** — information needed by Midnight validators to verify correctness of the
  transaction body against the Cardano network. Concretely it records the **hash of the
  last processed Cardano block** and the **zero-based index of the next transaction to
  process** in that block (`struct CMSTHeader { block, tx }`). If the index equals the
  block size, the block was processed in full; otherwise it was processed partially.
  Inspecting the previous transaction's header lets producers and verifiers determine
  the exact range of Cardano transactions that should have been included.
- **Body** — information that originates from Cardano and needs to be persisted in the
  Midnight ledger. The body is **divided into multiple payloads**, each recording a
  different *type* of Cardano event (e.g. the "cNIGHT generates DUST" / NgD payload).
  Each payload is tagged with its type when serialized so the format can be extended
  with new payload types. A CMST may contain an **empty body**.

Storage split: the **header must be stored in the block history** to enable block
verification against Cardano, but the **ledger itself only needs to store the body**.

## Construction and verification

- **Block producers construct** CMSTs. A producer inspects the previous header and the
  most recent *finalized* Cardano block to determine the transaction range to attempt,
  then processes those transactions, records events into their respective payloads, and
  writes the actually-processed range back into the new header. Blocks may be processed
  partially only when including all transactions would exceed the CMST size allowance.
- **Validators verify** CMSTs by reconstruction: given the header's block range, the
  validator builds *its own* body and checks it is identical (modulo payload ordering)
  to the producer's. Rebuilding — rather than merely spot-checking the submitted body —
  is what enforces **completeness**: it guarantees the block producer did not *omit* any
  events, not just that the events it did include really happened.
- **No-CMST blocks are allowed.** A Midnight block need not contain a CMST at all, so
  Midnight can run even if Cardano has not produced a new block since the last Midnight
  block — expected to be common, since Midnight's throughput exceeds Cardano's.

## Where this meets the trustless bridge

The CMST spec defines precisely *what a trustless Cardano→Midnight proof would need to
attest instead of trusting observation*: that the payloads in a body are the **complete
and correct** set of Midnight-relevant events for the Cardano block range named in the
header. The current design achieves this by having validators re-observe Cardano and by
trusting the producer's chosen range. A [recursive trustless
bridge](midnight-cardano-recursive-bridge.md) instead verifies Cardano's own BFT
finality over that block range with a succinct proof, so the Midnight ledger accepts the
observed events because it has *checked Cardano's consensus*, not because it trusts the
observer. The Midnight side of that verification runs on its
[AURA/GRANDPA Substrate consensus](/consensus/midnight-consensus-aura-grandpa.md).
