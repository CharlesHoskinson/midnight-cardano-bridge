---
type: Concept
title: Mithril — Cardano stake-based threshold BLS multi-signature certificates
timestamp: '2026-07-09T15:18:20Z'
description: Mithril produces stake-threshold multi-signature certificates over Cardano
  state (BLS/STM), a Cardano-side finality/state certificate a Midnight verifier could
  check via a pairing check in the Cardano->Midnight direction.
resource: https://raw.githubusercontent.com/input-output-hk/mithril/main/README.md
tags:
- cardano
- mithril
- bls12-381
- stm
- threshold-multisignature
- stake
- certificate
- finality
source: src-0024
status: researched
okf_version: '1.0'
---

# Mithril — Cardano stake-based threshold BLS multi-signature certificates

Mithril is an Input Output research project that provides **stake-based threshold multi-signatures (STM)** on top of the Cardano network. It is the natural Cardano-side analogue of Midnight's BLS-BEEFY: a compact, stake-weighted certificate over Cardano state that a foreign verifier — in this study, a Midnight-side verifier — could check with a single aggregate-signature (pairing) check, giving the **Cardano→Midnight (Direction B)** bridge leg a concrete finality/state witness. It complements, and is an alternative to, the Peras vote certificate as the object a light client attests to (see [Ouroboros Peras finality](/cardano/ouroboros-peras-finality.md)).

## The stake-threshold multi-signature (STM) structure

- **Individual → aggregate.** Stakeholders in the proof-of-stake network **individually sign messages, which are then aggregated into a single multi-signature**. Each Mithril **signer** produces individual signatures; the Mithril **aggregator** collects them from the signers and aggregates them into the multi-signature.
- **Stake threshold, not signer count.** The aggregated multi-signature **guarantees that its signers represent a minimum share of the total stake** — the *k-of-N* threshold is expressed in stake, not head-count. This is the security core: **an adversarial participant holding less than the required share of total stake cannot produce a valid multi-signature.** The exact threshold is set by the Mithril **protocol parameters** (the `k`, `m`, and `phi_f` of the STM scheme).
- **BLS / pairing basis.** STM is realized as a BLS-style aggregate signature over the BLS12-381 pairing-friendly curve (per the underlying *Mithril: Stake-based Threshold Multisignatures* paper and the `mithril-stm` crate); the aggregate is verified with a constant-size pairing check independent of the number of signers. Note: this README characterizes the scheme as "stake-based threshold multi-signatures (STM)" but does **not** itself name the curve or the pairing primitive — the BLS12-381 detail comes from the STM paper / `mithril-stm`, not from this source. See [CIP-0381 (BLS12-381 on Cardano)](/standards/cip-0381.md) for the on-chain pairing primitives available Plutus-side.

## What Mithril certifies (the "state certificate")

- The aggregator uses its aggregation ability to produce **certified snapshots of the Cardano blockchain**. These Cardano-chain certified snapshots are used to **securely restore a Cardano node**, letting a fully operating node bootstrap in **under two hours** instead of days.
- Beyond snapshots, Mithril implements a **framework that certifies any data type that can be computed deterministically** — so the same STM certificate machinery can attest to arbitrary deterministic functions of Cardano state (Cardano transaction sets, stake distribution, etc.), which is exactly what a bridge needs.
- Certificates are linked into a **certificate chain** exposed by each aggregator (surfaced by the Mithril explorer). The chain roots trust in the on-chain stake distribution, so a verifier that knows the epoch's stake distribution can validate a certificate independently.
- The cryptographic engine is isolated in the **`mithril-stm`** core library, and Mithril is already **deployed in SPO production infrastructure on Cardano mainnet** (beta).

## Bridge relevance (Direction B: Cardano → Midnight)

For a Midnight verifier to accept Cardano state trustlessly, it needs a succinct, stake-weighted certificate it can check without following the whole chain. Mithril supplies exactly that shape of object:

1. **Single aggregate check.** A Mithril certificate reduces "≥k-of-N stake signed message M" to one aggregate BLS signature plus the signed message — a natural fit for in-circuit or pairing-precompile verification on the Midnight side. This is directly comparable to how BLS-BEEFY certificates are verified in the [Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md).
2. **Stake-bound security.** Because validity requires an honest stake majority (threshold share of total stake), the certificate inherits Ouroboros/PoS security rather than a separate committee's honesty assumption.
3. **Mithril vs. Peras as the finality witness.** Peras gives an *in-protocol* vote/quorum certificate tied to consensus finality; Mithril gives an *out-of-protocol* (application-layer) certificate over arbitrary deterministic state, produced by SPOs today on mainnet. A bridge can treat Mithril as an already-shipping, stake-threshold BLS certificate of Cardano state, while Peras (once live) provides the tighter consensus-finality guarantee. The two are complementary options for the Cardano→Midnight leg.

**Caveat / open question:** this README does not describe any **Plutus / on-chain verification** of Mithril certificates — Mithril today is an off-chain network of signers/aggregators/clients. Whether (and how cheaply) a Mithril STM aggregate can be verified inside a Plutus script or a Midnight verifier circuit depends on the BLS12-381 pairing operations, i.e. the primitives tracked in [CIP-0381](/standards/cip-0381.md); that verifier-cost question is not answered by this source.

## See also

- [Knowledge base index](/index.md)
- [Sources index](/sources/index.md)
- [CIP-0381 — BLS12-381 primitives on Cardano](/standards/cip-0381.md)
- [Ouroboros Peras finality](/cardano/ouroboros-peras-finality.md)
- [Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md)
