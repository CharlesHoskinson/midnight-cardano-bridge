---
type: Concept
title: Shared claim envelope — typed fields a cross-chain claim/bridge message binds
timestamp: '2026-07-09T16:33:49Z'
description: The typed, canonically encoded envelope that a Cardano/Midnight cross-chain
  claim or bridge message binds, with its required fields, three field classes, and
  strict parser rules.
resource: C:/proofcategories/reports/cardano-midnight-proof-claim-report.md#8-shared-claim-envelope
tags:
- claim-envelope
- predicate
- verifier
- anchor
- context-hash
- replay-scope
- nullifier
- schema
- bridge
source: src-0036
status: researched
okf_version: '1.0'
---

Both the Cardano and Midnight proof catalogs share one common **claim envelope**: a typed message a validator receives alongside a proof, optional application callback data, and a [verifier registry](/bridges/midnight-cardano-recursive-bridge.md) entry that pins the accepted verifier or program. The validator should never receive raw proof bytes and guess their meaning. A good claim binds the source network, era, time range, finality rule, anchor type and value, predicate ID, verifier/image ID, public input and output hashes, target application context, expiry, and nullifier. Cardano and Midnight fill these same slots with chain-specific values (network magic / era / block hash / Mithril certificate on one side; network ID / Zswap and DUST roots / contract address / transcript hash on the other).

## Recommended envelope fields

The report specifies a typed field table. Required-and-proof-bound fields include `schema_version`, `network_id`, `source_system` (`cardano`, `midnight`, or an explicit private namespace), `predicate_id`/`predicate_version`, `anchor_type`/`anchor_digest`, `finality_rule`, `time_scope`, `verifier_id`, `public_input_hash`, and `public_output_hash`. Conditionally required fields: `context_hash` (for consumable claims — binds the proof to script, contract, entry point, transaction, campaign, or **bridge message**), `replay_scope` (reusable / one-time / campaign / transaction / bridge scope), `nullifier` (if replay is stateful), `expiry` (if freshness matters), `disclosure_set` (if private data exists), and `chain_specific` (era, protocol version, cost model / transcript / effects hashes, root index). The `advisory` field is a display-only typed map that MUST NOT affect acceptance.

## Three field classes

1. **Critical semantic** — bound into the proof and checked by the validator.
2. **Validator-only** — not hidden from the proof, but may be checked outside the circuit when the surrounding transaction already commits to them.
3. **Advisory** — wallet display and service routing only. If a field can change whether the application should accept the claim, it is *not* advisory.

## Strict parser and canonical encoding

A conforming envelope SHOULD use one canonical binary encoding: **canonical CBOR** for Cardano-adjacent uses, and deterministic binary records with fixed field order and explicit length bounds for Midnight and cross-chain requests. The hashable envelope MUST reject duplicate fields, unknown critical fields, non-canonical integers, ambiguous strings, and unordered maps. Parser rules are deliberately strict: unknown critical fields MUST be rejected, unknown advisory fields MAY be ignored, and byte strings MUST carry declared length bounds.

## Bridge relevance

This typed envelope is the **schema to reconcile with the BEEFY relay's Cardano PlutusData** representation used by the [Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md): the `anchor_digest`, `finality_rule`, `context_hash`, and `replay_scope`/`nullifier` fields must map cleanly onto the on-chain PlutusData a Cardano validator script inspects, and canonical CBOR encoding aligns the envelope with Cardano's native serialization.

See also the [knowledge base index](/index.md) and [sources index](/sources/index.md).