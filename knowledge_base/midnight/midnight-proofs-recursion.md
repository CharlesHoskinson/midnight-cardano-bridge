---
type: Concept
title: midnight-proofs — Plonk/KZG internals, recursion (truncated challenges, aPLONK
  committed instances)
timestamp: '2026-07-09T15:40:38Z'
description: How Midnight's midnight-proofs crate achieves recursion via in-circuit
  KZG proof verification with 128-bit truncated challenges plus aPLONK committed instances
  — not a curve cycle.
resource: https://github.com/midnightntwrk/midnight-zk/blob/main/proofs/README.md
tags:
- midnight
- midnight-proofs
- plonk
- kzg
- recursion
- aplonk
- committed-instances
- polynomial-commitment
- halo2
source: src-0028
status: researched
okf_version: '1.0'
---

# midnight-proofs — Plonk/KZG internals, recursion (truncated challenges, aPLONK committed instances)

This page is the authoritative correction, taken from the `midnight-proofs`
crate README (`src-0028`), to how recursion works in Midnight's proving stack.
It refines the curves-and-commitments picture in
[Midnight proving system — Plonk/Halo2 + KZG over BLS12-381](/midnight/proving-system-curves.md)
and the PLONKish background in
[halo2 / PLONKish arithmetization](/proof-systems/halo2-plonkish.md), and it feeds
directly into the [Midnight ↔ Cardano recursive trustless bridge](/bridges/midnight-cardano-recursive-bridge.md)
study. See also the [sources index](/sources/index.md) and the
[knowledge base index](/index.md).

## What the crate is

`midnight-proofs` is an **implementation of the Plonk proof system with KZG
commitments**. It began as a fork of the Privacy Scaling Explorations (PSE)
`halo2` codebase at **v0.3.0**, which is itself originally derived from the
**Zcash Sapling** proving system. So the lineage is
Zcash Sapling → PSE halo2 v0.3.0 → `midnight-proofs`, and the polynomial
commitment scheme is KZG (a universal/updatable trusted setup), not inner-product
argument (IPA) style Halo2.

The proof system is built on a generic `PolynomialCommitmentScheme` trait with a
simpler, more generic interface. The one concrete instantiation shipped today is
**KZG with the original Halo2 multi-open (multipoint opening) argument**. The
`Transcript` API was reworked so the same Fiat–Shamir transcript logic can run
both natively (off-circuit) and inside a circuit (in-circuit) — a prerequisite for
verifying proofs inside proofs.

## The real recursion mechanism (no curve cycle)

There is **no Pluto–Eris (or any) half-pairing curve cycle** in this stack.
Recursion is achieved by **verifying a proof inside a circuit** — in-circuit KZG
proof verification — and making that verifier circuit cheap. Two features do the
heavy lifting:

- **Truncated challenges (`truncate-challenges` feature).** To enable efficient
  recursion, Fiat–Shamir challenges can be truncated to **128 bits**. Because the
  dominant in-circuit cost of a KZG/Plonk verifier is the variable-base scalar
  multiplications gated on those challenges, halving the effective scalar width
  **halves the size of the in-circuit scalar multiplications**, yielding
  considerable circuit-size gains for in-circuit proof verification. Soundness is
  retained because a 128-bit challenge space is still cryptographically large.

- **Committed instances (`committed-instances` feature).** Following **Section 4.2
  of the aPLONK paper (eprint 2022/1352)**, public inputs (the "instance") can be
  supplied as a *commitment* rather than as a long vector of field elements. This
  shrinks the public-input surface a verifier circuit must absorb, which is exactly
  what a recursive/aggregating verifier needs when it folds many inner statements.

Together these turn "one proof verifies another proof" into a tractable circuit,
and Midnight ships an `aggregator` toolkit (IVC / proof aggregation for
`midnight-proofs`) built on top of these primitives.

## Why it matters for the Midnight ↔ Cardano bridge

The [recursive trustless bridge](/bridges/midnight-cardano-recursive-bridge.md)
needs a proof that a Cardano verifier can check cheaply while that proof itself
attests to a large amount of Midnight-side (and consensus-side) computation. The
combination here is a good fit:

- **KZG over BLS12-381** (from
  [proving-system-curves](/midnight/proving-system-curves.md)) puts Midnight proofs
  on the *same* pairing curve Cardano already exposes via CIP-0381 builtins, so a
  final proof is verifiable on-chain.
- **In-circuit KZG verification with 128-bit truncated challenges** makes it
  feasible to recursively compress a chain of proofs (aggregation / IVC) into a
  single succinct proof before it ever reaches Cardano.
- **aPLONK committed instances** keep the public-input surface small, which both
  lowers recursion cost and reduces what the on-chain verifier must reconstruct and
  bind — important given Cardano's tight per-transaction budget.

The correction to carry forward: Midnight's recursion story is
**in-circuit proof verification + truncated challenges + aPLONK committed
instances + an aggregation/IVC toolkit**, all over a single KZG/BLS12-381
substrate — *not* a two-curve cycle.

## Caveats

The README states the *mechanisms* (feature flags and their effect) but does not
give circuit-size numbers, the concrete aggregation scheme used by the
`aggregator`, or a security proof for 128-bit truncation; those live in the crate
source and the aPLONK paper. Claims on this page are limited to what the README
asserts.
