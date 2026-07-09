---
type: Concept
title: Bridge claim requirements — finality, message identity, replay, asset semantics,
  authorization
timestamp: '2026-07-09T16:33:36Z'
description: 'The application-layer claim contract that rides on top of the recursive
  bridge''s finality proof: the five things a cross-chain bridge claim must bind (finality
  anchor, deterministic message identity, replay nullifier/consumed-message records,
  canonical asset semantics, and action-bound authorization) plus expiry, lanes, and
  idempotent execution.'
resource: C:/proofcategories/reports/cardano-midnight-proof-claim-report.md#31-bridges-rollups-and-cross-chain-systems
tags:
- bridge
- cross-chain
- claim
- finality
- message-identity
- replay
- nullifier
- asset-identity
- authorization
source: src-0035
status: researched
okf_version: '1.0'
---

> **Application layer, not substrate.** This page specifies what a *bridge claim* must
> bind. It rides **on top of** the finality proof that the recursive bridge design
> provides: our substrate emits a verifiable `anchor` (settled prefix / certified root)
> and a named `finality_rule`; these requirements are exactly the fields a claim must
> bind to that anchor so a destination contract can act safely. See
> [the recursive bridge design](../bridges/midnight-cardano-recursive-bridge.md) for the
> proof substrate and [Cardano system transactions](../bridges/cardano-system-transactions.md)
> for the settlement surface.

Bridges are **claim problems before they are bridge problems**: consuming a fact from
one domain inside another is a statement that must be categorized precisely. A secure
bridge composes distinct statements — inclusion, finality, authorization, asset
identity, balance conservation, nullifier freshness, governance approval, execution
validity — and never lets a short proof stand in for the others.

## The five requirements a bridge claim must bind

1. **Finality.** Transaction *inclusion* is not finality. A Cardano claim binds to a
   settled prefix or certified checkpoint; a Midnight claim binds to a block/state root
   under a declared finality rule. The proof only proves inclusion *under an anchor* —
   the **destination must not infer finality from proof validity**. The envelope carries
   the finality rule name + parameters, and a destination rejects a rule it does not
   accept. *This is precisely the `anchor` + `finality_rule` our substrate supplies.*

2. **Message identity.** A source event becomes a destination message via a
   **deterministic hash** over source (network, block/slot/height, txid, output/action
   index, event discriminator, contract/script, payload hash) **and** destination
   (network, contract, asset handler, recipient, amount/rights, nonce, lane, replay
   scope). Omit any field and the message can be replayed or redirected. Multi-destination
   events need per-destination or **fan-out commitments** whose leaves bind each domain,
   handler, recipient, and payload.

3. **Replay control.** Two *distinct* records: a **ZK nullifier** proves a hidden source
   note/credential was spent once in a privacy scope; a **consumed-message record** proves
   a destination already processed a specific cross-domain message (keyed by destination
   domain, bridge contract, source domain, lane, message ID). Both may co-exist in one
   flow; the proof exposes a message ID/nullifier the destination marks consumed.

4. **Asset semantics.** Bind the asset identity **precisely** using canonical identifiers
   only — a display name is not an identity. Cardano assets are the tuple
   `(source_system=cardano, network_id, policy_id, raw asset_name)` with ADA as an explicit
   tag. **DUST is a local fee capability, not a normal bridgeable asset.** Amount and action
   must be bound together so one source event cannot mean lock/burn/mint/release/
   shield/unshield interchangeably.

5. **Authorization.** Bound to the *specific* transaction or message being authorized.
   Historical ownership does not authorize a present transfer; a private-role proof does
   not prove consent for this action.

## Cross-cutting discipline

- **Two-part expiry:** source acceptance age (how old the finalized event may be) and
  destination submission window (how long a relayer has to submit) — never compared by raw
  epoch-to-height.
- **Ordering / lanes:** a lane declares nonce ordering (per account, UTxO, contract, asset,
  or lane) *or* explicitly states no ordering is guaranteed; hidden assumptions cause stuck
  messages and replay gaps.
- **Idempotent destination execution:** the payload defines whether retry is allowed and
  what state proves completion, so a failed execution has a retry/refund/stuck-message path
  without duplicate execution.

## Relation to the KB

- Extraction run and verbatim-gated claims live under this source in
  [the sources index](../sources/index.md); browse the KB from the
  [index](../index.md).
- This concept is the **claim contract** that any bridge built on the
  [recursive trustless design](../bridges/midnight-cardano-recursive-bridge.md) must
  satisfy at its application layer.