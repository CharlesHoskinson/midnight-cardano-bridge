---
type: Concept
title: Claim interface schema — canonical predicate/verifier/registry record shapes
timestamp: '2026-07-09T16:34:45Z'
description: Canonical typed-claim envelope, predicate/verifier-registry record shapes,
  and validation order for a Midnight-Cardano recursive trustless bridge.
resource: C:/proofcategories/reports/claim-interface-schema.md
tags:
- claim
- schema
- predicate
- verifier-registry
- interface
- bridge
- conformance
source: src-0038
status: researched
okf_version: '1.0'
---

Companion to the proof-claim taxonomy. Where the taxonomy answers *what can be
proved*, this schema fixes *how a proved statement is presented to a verifier*:
the canonical typed-claim envelope, the predicate/verifier registry record, and
the validation order that binds them. It is the interface a recursive
[Midnight ↔ Cardano bridge](../bridges/midnight-cardano-recursive-bridge.md) needs
so an on-chain validator consumes a *typed claim* — not an untyped proof blob whose
meaning it must guess.

## Principle

A validator should receive four things: a typed public claim, a proof blob,
optional application callback/redeemer data, and a registry entry that pins the
accepted verifier/program/predicate. The proof only attests that the public claim
is true; the application consumes the claim output **only after** checking
`version`, context, `nullifier`, `expiry`, and the allowed predicate.

## Claim envelope

The reference shape (`HistoricalClaim`, expressed Solidity-like for clarity; on
Cardano encoded as Plutus data with canonical CBOR and fixed-size byte strings)
carries the fields that make a claim self-describing and non-malleable:

- **`predicateId`** — registry key for the statement being proved.
- **`verifierOrImageId`** — pins the accepted vk / zkVM image id / verifier program id.
- **`publicInputsHash` / `publicOutputsHash`** — hashes of the structured inputs and predicate outputs.
- **`contextHash`** — binds the claim to target script, caller, action, callback, and salt.
- **`expiry`** — latest slot/epoch at which the claim may be consumed.
- **`nullifier`** — replay prevention when the claim has side effects.
- Provenance context: `sourceChainId`, `ledgerEraOrForkId`, epoch/block range, `finalityRule`, `anchorType`, `anchorValue`.

Cardano-specific recommended public inputs include `network_magic`, `era_id`, slot/epoch
range, `mithril_certificate_hash` (Mithril), `protocol_parameters_hash`,
`cost_model_hash`, `governance_action_id` (CIP-1694), and Plutus/native-asset hashes.

## Verifier registry

`predicateId` resolves in a verifier registry to a `PredicateRegistryEntry`:
`verifier_or_image_id`, `proof_system`, `accepted_anchor_types`,
`accepted_ledger_eras`, `result_schema_hash`, `max_claim_age`, a lifecycle
`status` (active / frozen / deprecated), `upgrade_authority`, and `audit_hash`.
The lifecycle status lets operators **freeze or deprecate** a verifier entry when
an issue is discovered — the trustless analogue of revoking a compromised key.

## Validation order

Decode → check `version` → check `contextHash` binds the current tx → check
`expiry` → check `nullifier` unused (if the claim consumes rights) → look up
`predicateId` in the registry → confirm `verifierOrImageId` matches the entry →
verify the proof over the claim hash and outputs → decode outputs → apply policy →
mark `nullifier` consumed. Crucially, a caller must **not** be free to choose the
verifier key or image id; the registry, not the caller, is authoritative.

## Bridge relevance

For a recursive trustless bridge this schema is the contract at the verification
boundary. `bridge_message_finalized(message_hash, epoch, nullifier) -> bool` is a
first-class predicate; the envelope's separation of `anchorType` (mithril-cert,
scls-root, replay-root, hydra-snapshot) from `finalityRule`, and its insistence on
distinguishing *included* from *finalized* and *metadata bytes present* from
*real-world statement true*, are exactly the safety distinctions a bridge validator
must not collapse. Version every predicate and result schema so upgrades never
silently change claim meaning.

## Sources

- Source record: [sources index](../sources/index.md) (`src-0038`).
- Knowledge base [index](../index.md).