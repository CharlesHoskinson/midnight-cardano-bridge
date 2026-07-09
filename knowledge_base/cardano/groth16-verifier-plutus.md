---
type: Tool
title: plutus-groth — pure-Plutus Groth16 verifier
timestamp: '2026-07-09T14:06:53Z'
description: A proof-of-concept pure-Plutus V2 Groth16 verifier over BLS12-381, benchmarked
  for on-chain execution cost.
resource: https://raw.githubusercontent.com/Modulo-P/plutus-groth/main/README.md
tags:
- cardano
- plutus
- groth16
- bls12-381
- zk-snark
- verifier
source: src-0002
status: researched
okf_version: '1.0'
---

# plutus-groth — pure-Plutus Groth16 verifier

`plutus-groth` (Modulo-P, Project Catalyst Fund 10) is a proof-of-concept Groth16
proof verifier written in **pure Plutus V2**, with no reliance on curve builtins.
Because Plutus V2 had no native elliptic-curve support, the authors hand-implemented
all of the [BLS12-381](/standards/cip-0381.md) arithmetic — field, group, and pairing
operations — inside the on-chain language itself. It matters to the Midnight→Cardano
(Groth16) direction because it directly measures the on-chain cost of Groth16
verification on Cardano and pinpoints why the pure approach is infeasible on mainnet.

## What it implements

The verifier reconstructs the full Groth16 check from scratch: BLS12-381 curve
operations plus the **optimal ate pairing**. To make this even runnable, several
optimizations were required — tower extension field arithmetic, the Frobenius operator
for exponentiation, and point arithmetic in Jacobian coordinates (dbl-2009-l doubling,
add-2007-bl addition). A unit test exercises a fixed verification key and proof, and the
validator accepts only the correct public instance (integer `168932`), demonstrating
soundness.

## Execution cost and feasibility

The headline finding is a hard cost wall. Against a per-validation ceiling of
**10,000,000,000 CPU / 14,000,000 MEM**, the measured actual costs are:

- Single pairing: **362,874,651,295 CPU** (~36× the CPU budget).
- Point multiplication: 170,244,281,089 CPU.
- Complete proof verification: **1,334,647,992,336 CPU / 1,663,887,424 MEM** (~133× CPU, ~119× MEM).

A pure-Plutus-V2 Groth16 verifier therefore **cannot run within Cardano mainnet
budgets**; it is only feasible on Hydra, whose execution budget is effectively
unlimited, which is exactly what this validator targets.

## Path forward (Plutus V3)

The authors leave the repo as a proof of concept and note that **Plutus V3 adds builtin
primitives for BLS12-381 curve operations** (per CIP-0381), which are expected to make
Groth16 verification feasible on-chain within a reasonable budget. For a production
Midnight→Cardano Groth16 bridge verifier, the V3 builtin-backed path — not this
pure-Plutus implementation — is the viable route; this study is the cost baseline that
motivates using those builtins.

## References

- Source: [sources index](/sources/index.md) · [knowledge base index](/index.md)
- Related standard: [CIP-0381 — BLS12-381 builtins](/standards/cip-0381.md)
