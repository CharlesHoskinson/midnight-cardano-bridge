---
type: Concept
title: Anchor & trust models — settled prefix, Mithril, ledger-state root, Zswap/DUST
  roots
timestamp: '2026-07-09T16:34:45Z'
description: Enumerates the approved proof-claim anchor types and finality terms from
  taxonomy report §9 and maps each onto the recursive Midnight-Cardano bridge's finality
  objects.
resource: C:/proofcategories/reports/cardano-midnight-proof-claim-report.md#9-anchor-and-trust-models
tags:
- anchor
- finality
- mithril
- ledger-state-root
- zswap-root
- dust-root
- indexer
- trust-model
- bridge
source: src-0037
status: researched
okf_version: '1.0'
---

> Synthesis of §9 "Anchor and trust models" from the proof-claim taxonomy report,
> mapped onto the finality objects of the [recursive Midnight ↔ Cardano bridge](/bridges/midnight-cardano-recursive-bridge.md).
> Every load-bearing statement is a verbatim-gated claim in the linked [source](/sources/index.md).

## The core rule: the anchor is part of the claim

In both systems, **the anchor must be part of the claim** — a proof against an
unqualified "some root" is not enough. A verifier (the DApp) must know *why* a
root is accepted, *which* trust model produced it, and *whether* the root is
fresh or old enough for the application. For the bridge this means every proof
carried across the boundary must name the finality object it binds to, not just
a bare Merkle root. See the [knowledge base index](/index.md) for related pages.

## Approved anchor types → bridge finality objects

The report enumerates eight explicit anchor types. Each maps to a concrete
finality object on one side of the bridge:

| Anchor type | Side | What it proves | Bridge finality object |
| --- | --- | --- | --- |
| `settled_chain_prefix` | Cardano | A block/tx is inside a prefix accepted by the consumer's finality rule | [Ouroboros Peras](/cardano/ouroboros-peras-finality.md) settlement / GRANDPA-style prefix on Midnight |
| `mithril_certificate` | Cardano | A signed message or artifact was certified by a Mithril signer set | [Mithril BLS certificate](/cardano/mithril-bls-certificates.md) |
| `ledger_state_commitment` | Cardano | A namespace root represents replayed or canonical ledger state | CIP-165-style canonical root (not yet historical for all epochs) |
| `block_or_transaction_root` | Either | Data is included in a particular block or transaction structure | block-inclusion proof on either chain |
| `contract_state_root` | Midnight | A contract state namespace is committed at a block/tx point | Midnight ledger contract-state root |
| `zswap_root` | Midnight | A shielded commitment/nullifier statement is tied to a Zswap root | Zswap commitment tree root |
| `dust_root` | Midnight | A DUST commitment/generation/nullifier statement is tied to a DUST root | DUST tree root |
| `indexer_commitment` | Either | An indexer committed to a derived view that still needs a trust statement | untrusted convenience view — must be backed by one of the above |

### Cardano side

The strongest anchor — a full recursive ledger proof — is also the hardest,
because it forces the proof system to encode a large, era-sensitive protocol. In
practice the bridge leans on two weaker-but-tractable anchors:

- A **Mithril certificate** is a *stake-threshold attestation over a root, not a
  full ledger replay proof*. It certifies that a signed message or artifact was
  signed under a stake-based signer set — practical for snapshots and immutable
  artifacts. This is the Cardano→Midnight finality object today. See
  [Mithril BLS certificates](/cardano/mithril-bls-certificates.md).
- A **CIP-165-style ledger-state commitment** would be a clean membership /
  nonmembership target, but it is *not yet a historical root available for all
  prior epochs*. When available it complements [Peras finality](/cardano/ouroboros-peras-finality.md),
  which supplies the `settled_chain_prefix` acceptance rule.

Hydra and partner-chain anchors only prove facts about their own state — a Hydra
Head cannot answer whether a mainnet reward account had a balance at epoch E — so
they are unsuitable as general L1-history anchors for the bridge.

### Midnight side

Native Compact, Zswap, DUST, and aggregation proofs are already verifier-key
based and prove statements directly under their circuits, so `zswap_root`,
`dust_root`, and `contract_state_root` map straight onto Midnight ledger roots.
Public *historical* Midnight facts still need block or state anchoring; the
indexer can tell a wallet what happened, but a verifier needs node verification,
authenticated roots, or replay — so `indexer_commitment` is never a standalone
anchor. On this side the settlement / prefix acceptance is supplied by Midnight's
GRANDPA-style finality (with BEEFY-style bridging for light-client consumption).

## Bounded finality terms

The report also bounds the vocabulary the bridge's acceptance predicate uses:

- **Prior epoch** — the claim source time is before the epoch currently used for
  acceptance, not simply "old."
- **Settled** — the consumer's finality rule has accepted the chain prefix.
- **Certified** — a named certification system signed or committed to a specific
  artifact (e.g. a Mithril certificate).
- **Historical** — the claim concerns a past source time; this does *not*
  automatically mean final.
- **Fresh** — the source age and destination submission window are within the
  predicate's acceptance policy.

These terms let the bridge's predicate distinguish "a root exists" from "a root
this consumer will accept, now, under a named trust model" — the distinction §9
insists every claim must carry.