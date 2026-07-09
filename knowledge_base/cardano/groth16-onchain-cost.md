---
type: Concept
title: On-chain Groth16 verification cost (Plutus V3 + CIP-381, measured)
timestamp: '2026-07-09T14:23:26Z'
description: Measured Plutus V3 CEK ex-units for on-chain Groth16 and commitment-Groth16
  verification, showing a single claim costs about 25% of the per-tx CPU budget.
resource: https://github.com/CharlesHoskinson/proof-zk-recovery/blob/proto/preprod-experiments/proto/onchain/COMMITMENT-VERIFIER-COST.md
tags:
- cardano
- plutus-v3
- groth16
- bls12-381
- cip-381
- cost
- ex-units
- verifier
source: src-0011
status: researched
okf_version: '1.0'
---

# On-chain Groth16 verification cost (Plutus V3 + CIP-381, measured)

This page records **measured** on-chain execution cost for Groth16 verification on
Cardano using the [Plutus V3](/cardano/groth16-verifier-plutus.md) BLS12-381 builtins
introduced by [CIP-0381](/standards/cip-0381.md). Figures come from a Plinth / Plutus V3
prototype run in CEK ex-units counting mode against the pinned plutus-core 1.38 default
cost model, and are validated against the SPEC cost model ("cost model E") to under 0.2%.
It matters to the **Midnight→Cardano (Groth16)** bridge direction because it turns the
verifier's affordability from an estimate into a measurement.

## Primitive costs (BLS12-381 builtins, measured)

Isolated by single-occurrence differencing, the per-builtin CPU costs are:

| primitive | measured CPU |
|---|---:|
| G1 uncompress | 52,980,122 |
| G2 uncompress | 74,730,472 |
| G1 scalarMul | 76,505,874 |
| [millerLoop](/proof-systems/commitment-groth16.md) | 254,118,273 |
| [finalVerify](/proof-systems/commitment-groth16.md) | 334,213,863 |

A vanilla single-proof Groth16 verify sits at **1.36–1.61×10⁹ CPU** (3 vs 4 miller
loops). Against the per-tx ceiling of **10¹⁰ CPU**, that is comfortably affordable —
about 14–16% of the budget.

## The commitment-Groth16 delta

The [commitment-Groth16](/proof-systems/commitment-groth16.md) proof adds one Pedersen
commitment `D∈G1` and a knowledge-of-opening PoK `π∈G1` on top of `(A,B,C)`. The measured
per-claim delta is **1,033,457,922 CPU (≈1.03×10⁹)**, dominated (~82%) by the opening PoK
pairing (measured 844,624,447 CPU); the nonlinear hash-to-field is negligible (~0.4%).
The full single-claim commitment total (vanilla + delta + one-time vk-point uncompress) is
**≈2.4–2.8×10⁹ CPU**, centrally **≈25–26% of the 10¹⁰ per-tx budget**. The on-chain
serialised validator for the full delta path is just **303 bytes**.

## Batching and the per-tx ceiling

Under a Tier-1 RLC batch the opening pairing is shared, so the commitment batch cost is
approximately **3.35×10⁹ + 0.748×10⁹·N** (vs vanilla `1.66×10⁹ + 0.538×10⁹·N`). This puts
the CPU-bound ceiling at **≈8 claims/tx** (N=8 ≈93%, N=9 exceeds 100%) — a ~40–50%
throughput haircut versus vanilla, not a wall. Importantly, **memory (16.5M) and
`maxTxSize` (16,384 B) likely bind before CPU**, so the true ceiling must be re-measured on
preprod v11 with all soundness controls enabled.

## V3 vs V2: why this is the feasible path

The [pure-Plutus-V2 verifier](/cardano/groth16-verifier-plutus.md) hand-implemented all
BLS12-381 arithmetic and hit a hard cost wall — a single pairing alone cost ~363×10⁹ CPU
(~36× the budget) and a full verify ~1.33×10¹² CPU (~133× over), runnable only on Hydra.
The CIP-0381 builtins in Plutus V3 collapse that: the **same full verification now fits in
roughly a quarter of one transaction's CPU budget**, with room to batch several claims. For
a production Midnight→Cardano Groth16 bridge verifier, this measurement confirms the V3
builtin-backed path is not merely viable but has comfortable headroom for the
commitment-and-batching soundness machinery.

## References

- Source: [sources index](/sources/index.md) · [knowledge base index](/index.md)
- Related standards: [CIP-0381 — BLS12-381 builtins](/standards/cip-0381.md) · [CIP-0133](/standards/cip-0133.md)
- Related: [pure-Plutus V2 verifier (cost baseline)](/cardano/groth16-verifier-plutus.md) · [commitment-Groth16](/proof-systems/commitment-groth16.md) · [preview deployment](/bridges/groth16-cardano-preview-deployment.md)
