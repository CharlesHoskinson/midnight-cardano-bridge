---
type: Concept
title: Commitment Groth16 (gnark) — Pedersen commitment + proof-of-knowledge variant
timestamp: '2026-07-09T14:24:09Z'
description: How gnark's BSB22 commitment-Groth16 variant adds a Pedersen commitment
  D plus a knowledge-of-opening proof to move committed wires out of the public inputs,
  keeping the on-chain public-input MSM small for the Midnight to Cardano Groth16
  verifier.
resource: https://github.com/CharlesHoskinson/proof-zk-recovery/blob/proto/preprod-experiments/docs/commitment-groth16-protocol.md
tags:
- groth16
- commitment
- gnark
- pedersen
- proof-of-knowledge
- bls12-381
- verification
source: src-0013
status: researched
okf_version: '1.0'
---

# Commitment Groth16 (gnark) — Pedersen commitment + proof-of-knowledge variant

*Commitment-Groth16* (gnark's **BSB22** construction) extends vanilla Groth16
with two extra proof elements: a single **Pedersen commitment point** `D ∈ G1`
and its **knowledge-of-opening proof** (PoK, also in `G1`). It is the exact
proof shape the Midnight → Cardano recovery circuit uses, and understanding it
matters for the bridge because it is *the* mechanism that keeps the on-chain
public input — and therefore the verifier's multi-scalar multiplication (MSM) —
small. See the [knowledge base index](/index.md), the
[sources index](/sources/index.md), and the broader
[proof-systems fundamentals](/proof-systems/proof-systems-fundamentals.md).

## What the commitment variant adds over vanilla (A, B, C)

The committed proof is **exactly 336 bytes**, five elements in fixed order:
the Groth16 triple `A` (G1), `B` (G2), `C` (G1), then the Pedersen commitment
`D` (G1, carried **uncompressed** as `X‖Y`) and the PoK (G1, compressed).
Correspondingly the verifying key carries one extra IC point `K2` and two
Pedersen commitment-key points (`CK.G = G` and `CK.GSigmaNeg = G^{−σ}`).

gnark aggregates **all** committed wires across the whole circuit into
**exactly one** Pedersen commitment. In the recovery circuit the heavy
range-check / lookup wires (Blake2b, SHA-512, Ed25519 gadgets, `logderivlookup`)
are routed through `api.Commit`, so they collapse into the single point `D`
rather than being carried as individual public inputs. The committed values are
the circuit's **private committed wires**, so `D` is deterministic given
(setup, witness) with **no blinding randomness** — `Commit` is a plain MSM,
`D = Σ_j values_j · [Basis_j]`.

## Why it is used: keeping the public input / MSM small

A Groth16 verifier folds every public input into a single accumulator point
`vk_x` via one scalar-mul per input (`vk_x = K0 + Σ pub_i · [K_i] + Σ commitments`).
The size and cost of that MSM grows with the number of public inputs. The
commitment variant moves the bulk of what would otherwise be public data into
the commitment `D`, leaving the recovery circuit with **exactly one** public
scalar `pub`. The verifying key therefore holds only **three** IC points
(`IC0`, `IC1` for `pub`, and `K2` for the commitment hash), and the fold is:

```
vk_x = K0 + pub·[K1] + e_cmt·[K2] + D
```

This is directly relevant to the bridge's on-chain economics: Cardano's Plutus
Groth16 verifier pays per G1 scalar-mul in the public-input MSM (see
[CIP-0133](/standards/cip-0133.md) and the
[on-chain Groth16 cost analysis](/cardano/groth16-onchain-cost.md)). By keeping
the public input to a single scalar, the commitment variant holds the on-chain
MSM to the minimum while still binding arbitrarily many committed wires.

## The commitment hash `e_cmt` and how `D` re-enters the fold

`e_cmt` is the **BSB22 commitment challenge**, derived by the verifier from `D`
**alone** (the prover contributes nothing but `D`). It is a RFC 9380
hash-to-field of the 96-byte uncompressed commitment:

```
e_cmt = OS2IP_BE( expand_message_xmd(SHA-256, m, "bsb22-commitment", 48) ) mod r
```

`D` enters `vk_x` **twice-linked** — once as the scalar `e_cmt` on basis `K2`,
and once as the raw point `D` added directly. Both terms are mandatory;
omitting either admits adaptive-commitment forgeries. Critically the verifier
**must recompute `e_cmt` from `D`** and must not accept a prover-supplied
`e_cmt` or committed-wire value. `D` is emitted uncompressed precisely so the
verifier hashes the *identical* 96 bytes gnark hashed when it derived `e_cmt`.

## Verification: PoK check + Groth16 pairing check

Acceptance requires **both** pairing checks to pass on well-formed inputs:

1. **Proof-of-knowledge check** — binds the PoK to `D`:

   ```
   e(D, GSigmaNeg) · e(π, G) == 1_GT
   ```

   The PoK is `π = σ · D` (the same MSM over the σ-shifted basis). The setup
   secret `σ` binds `π` to `D` through the pairing, so a prover who does not
   know an opening of `D` cannot forge `π`. (`σ` is discarded after setup.)

2. **Groth16 pairing check** — the standard equation with the folded `vk_x`:

   ```
   e(A,B) ≠ e(alpha,beta) · e(vk_x, gamma) · e(C, delta)   ⇒ reject
   ```

Acceptance is `iff` both hold; a verifier must otherwise fail closed (wrong
length, non-canonical / off-curve / non-subgroup points, identity points,
compressed `D`, or a prover-supplied challenge all cause rejection). The curve
throughout is **BLS12-381** with scalar field `Fr` and base field `Fp`.

## Relevance to the Midnight → Cardano bridge

For the Groth16 (Midnight → Cardano) direction of the recursive trustless
bridge, this variant is what makes an on-chain verifier affordable: the
public-input surface is a single scalar regardless of how much the circuit
proves, so the Plutus verifier's dominant per-public-input MSM cost stays
constant. The extra cost is one additional pairing (the PoK check) plus one
G1 scalar-mul and one hash-to-field for `e_cmt` — a fixed overhead, not one
that scales with witness size. See the
[on-chain Groth16 cost analysis](/cardano/groth16-onchain-cost.md) for how these
map to Plutus execution units.
