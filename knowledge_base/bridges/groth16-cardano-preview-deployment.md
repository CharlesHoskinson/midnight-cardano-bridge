---
type: Concept
title: Working Groth16 verifier live on Cardano Preview (real deployment)
timestamp: '2026-07-09T14:23:37Z'
description: A hardened Groth16 redemption validator deployed to live Cardano Preview
  released real tADA against a client ZK proof and rejected a double-claim on-chain
  via a nullifier-backed spent-state gate.
resource: https://github.com/CharlesHoskinson/proof-zk-recovery/blob/proto/preprod-experiments/proto/onchain/redemption/SP2-PREVIEW.md
tags:
- cardano
- groth16
- preview
- deployment
- plutus-v3
- nullifier
- replay-protection
- zk
source: src-0012
status: researched
okf_version: '1.0'
---

# Working Groth16 verifier live on Cardano Preview (real deployment)

This is a **real deployment record**, not a simulation. On 2026-06-29 the hardened, ticket-aware
`RedemptionValidator` was deployed to the live [Cardano](/cardano/groth16-onchain-cost.md) **Preview**
network (testnet-magic 2) and exercised end-to-end. It is the strongest available feasibility proof
for the Midnight->Cardano [Groth16](/cardano/groth16-verifier-plutus.md) leg of a recursive trustless
bridge: a genuine client ZK proof was verified on-chain and moved real value.

## What happened on-chain

- **A real Groth16 proof verified and paid out.** A custody balance plus a per-credential claim
  ticket were locked, and a real client ZK proof drove *Claim A*, which spent and burned the ticket
  and released **5 tADA** to a bound destination `D`. `D` received exactly **5,000,000 lovelace**;
  the confirmed transaction (validator ACCEPT) is
  `d9f4bd9ea7efbb4f1fd72df70fb43fb5da08cbd6f6130261e113e413823a147c`. The node ran the full
  validator on both script inputs, with the **Custody** branch executing the real
  `groth16VerifyCommitted` builtin. The deployed validator is pinned by cborHex sha256
  `860134f9…0c3a4584`.

- **A double-claim was rejected on-chain.** A second claim for the same credential `C` — identical
  proof, payout, and entitlement, differing only in that no ticket was available (the one ticket was
  already burned by Claim A) — was rejected in phase-2 with **no budget overspend**: a pure
  spent-state-logic rejection. The custody UTxO for the already-claimed credential could not be
  redeemed, and `D` received no second payment.

## The nullifier replay-protection pattern

Replay / double-claim protection is enforced by a **one-ticket-per-credential** invariant rather
than by any global set membership. Each claimable credential `C` gets exactly one
[nullifier](/cardano/groth16-onchain-cost.md)-keyed claim ticket, where the **version-stable
nullifier** is

```
n = Blake2b(domainSep ‖ scriptHash ‖ C)
```

(concrete value in this run: `719bf915…4a2a51b6`). A claim must spend **two** script inputs in one
transaction — the custody UTxO and the matching ticket — and the ticket is **burned** (no ticket
output). Because the ticket is consumed on first claim, any later claim for the same `C` fails the
validator's spent-state gate on-chain. This is a clean, UTxO-native replay-protection primitive that
the Midnight->Cardano bridge can adopt directly: a per-message/per-credential nullifier ticket
whose burn is the on-chain record of "already redeemed."

## Per-input ex-unit budgeting

The claim spans two separate Plutus executions, one per script input, so ex-units must be budgeted
**per input**, not just per transaction. Measured (CEK) costs, declared on-chain with margin:

| Branch | CEK ExCPU / ExMem | Declared on-chain |
|--------|-------------------|-------------------|
| custody (proof + `ticketBurnedFor`) | 5,504,101,369 / 9,206,533 | 6,500,000,000 / 11,000,000 |
| ticket (`custodyClaimPresent`) | 435,282,352 / 1,738,236 | 600,000,000 / 2,600,000 |

Both sit well within the per-tx ceiling (10e9 steps / 16.5e6 mem). A practical lesson: the synthetic
CEK context slightly under-measures the real node's memory (real inputs/collateral/redeemers), so a
first live attempt overspent its declared budget; the figures above carry deliberate margin over the
raw CEK cost. See [on-chain Groth16 verification cost](/cardano/groth16-onchain-cost.md) for the
underlying verifier budget and [CIP-0381](/standards/cip-0381.md) for the BLS12-381 builtins it
relies on.

## Lessons for the bridge

- **Feasibility is proven, on real chain.** The Midnight->Cardano Groth16 verification leg works on a
  live Cardano network today, not only in a local evaluator.
- **Nullifier tickets are the replay-protection pattern.** A burn-on-claim, one-ticket-per-credential
  design closes double-claim structurally, verified on-chain here.
- **Budget per input, with margin.** Multi-input claims need per-input ex-unit declarations, and
  synthetic-context measurements should be padded against the real node context.
- The live run also caught a real integration bug the off-chain harness had masked (a ticket-datum
  emitter that emitted the flat `Constr 1 [B n]` instead of the nested `Constr 1 [Constr 0 [B n]]`),
  underscoring the value of an actual on-chain exercise over evaluator-only testing.

Bridge finality considerations for such redemptions are discussed in
[Ouroboros Peras finality](/cardano/ouroboros-peras-finality.md).

## Provenance

Source: [SP2-PREVIEW.md](https://github.com/CharlesHoskinson/proof-zk-recovery/blob/proto/preprod-experiments/proto/onchain/redemption/SP2-PREVIEW.md)
(`src-0012`). See also the [knowledge base index](/index.md) and the
[sources index](/sources/index.md).
