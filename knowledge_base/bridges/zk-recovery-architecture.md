---
type: Concept
title: ZK recovery system architecture (client prover → on-chain Groth16 validator)
timestamp: '2026-07-09T14:26:26Z'
description: A client-side gnark/Groth16 prover paired with an on-chain Cardano validator
  that reconstructs its own public input, a reference pattern for a Midnight to Cardano
  bridge.
resource: https://github.com/CharlesHoskinson/proof-zk-recovery/blob/proto/preprod-experiments/docs/ARCHITECTURE.md
tags:
- cardano
- groth16
- architecture
- prover
- validator
- zk
- client-side
source: src-0015
status: researched
okf_version: '1.0'
---

# ZK recovery system architecture (client prover → on-chain Groth16 validator)

The `proof-zk-recovery` system is a working reference for the exact shape a
Midnight→Cardano (Groth16) bridge needs: a **prover that runs off-chain** producing a
small Groth16 proof, and an **on-chain Cardano validator** that verifies it and — the
load-bearing detail — **reconstructs its own public input from trusted on-chain state
instead of trusting the prover**. It is being ground-truthed on Cardano Preview, so the
cost and trust boundaries are measured rather than assumed.

## The prover → validator split

Proof generation happens entirely on an air-gapped client. The client runs a **gnark
prover over BLS12-381** and the single secret witness **never leaves the client** (it is
held in RAM only). The output handed to the chain is deliberately tiny: a **192-byte
Groth16 proof** `π = (A:G1, B:G2, C:G1)`, the destination address `D`, a Merkle path, and
the reconstructed public input. Everything expensive (the ~3.5–5M-R1CS circuit, HMAC-SHA512,
Ed25519, Blake2b) is off-chain; the chain only ever sees the constant-size proof and a few
public fields.

The on-chain **recovery validator** is written in Plinth and compiled to UPLC. Its
pipeline is:

1. Uncompress the proof points.
2. **Reconstruct the public input from the datum + transaction output** — never from the
   prover (`REQ-V-06`, marked "NEVER prover-sup").
3. Compute `vk_x = IC·pub` and check the Groth16 pairing equation
   `e(A,B) = e(α,β)·e(vk_x,γ)·e(C,δ)` via `millerLoop`/`finalVerify`.
4. Check the credential is in the committed Merkle root.
5. Flip exactly one cell `0→1` in a sharded sparse-Merkle spent set (nullifier) to block
   double claims.
6. Pay the entitlement to the bound destination `D` and enforce value conservation
   (`Σ custody-in = Σ payouts + Σ continuing + fee`).

## Why the trust boundary is the reusable part

Two design decisions make this a safe bridge pattern rather than a trust hole:

- **The verifier reconstructs its own public input.** The prover cannot assert what was
  proven; the validator derives the public input from the on-chain datum (the committed
  snapshot root, version, script hash) and the transaction's own output (destination `D`,
  entitlement). This is the invariant that makes the proof binding on Cardano.
- **The verification key is pinned as an immutable script parameter, and any
  redeemer-supplied VK is rejected.** Each circuit gets one VK from a 2-phase MPC trusted
  setup (public BLS12-381 Powers-of-Tau + independent Phase-2). There is no path for a
  caller to swap in a VK for a different circuit.

## Cost profile

Because the circuit exposes **exactly one aggregated public input** (a single field
element that binds domain separator, script hash, version, root, credential, entitlement,
destination `D`, and role), `vk_x` is a **1-element MSM** and verification cost collapses
to **fixed pairing work independent of circuit size**. A single verify is hypothesized at
~1.4–1.6B CPU (~14–16% of the per-tx budget); an RLC batch verifier amortizes this to
roughly **10–15 claims per transaction**. This is exactly the regime a bridge needs: proof
size and verify cost stay flat no matter how heavy the statement being proven. See
[groth16-verifier-plutus](/cardano/groth16-verifier-plutus.md) and
[CIP-0381 BLS12-381 builtins](/standards/cip-0381.md) for the on-chain verification
primitives this relies on.

## Mapping onto a Midnight → Cardano bridge

For the Midnight→Cardano direction, the roles map cleanly:

- **Midnight-side client / relayer = the prover.** Whatever cross-chain fact must be
  attested (a Midnight state transition, a burn, a commitment) is proven off-chain into a
  constant-size Groth16 proof. The relayer is untrusted — it only carries the proof and the
  target output; it holds no secret the validator relies on.
- **Cardano validator = the on-chain verifier.** It pins the circuit VK immutably,
  reconstructs the public input from Cardano-side state (bridge datum + the destination
  output being created), runs the fixed-cost pairing check, and uses a nullifier / spent
  set to make each attested event settle exactly once.
- **The aggregated single public input** is the template for the bridge's cross-chain
  commitment: fold every field that must be bound (source event id, amount, destination
  address, version) into one field element the circuit proves and the validator
  independently recomputes.

The key lesson to carry over: **the validator must never accept the public input (or the
VK) from the party submitting the proof.** That single rule is what turns "a Groth16 proof
verified on Cardano" into a trustless bridge.

## References

- Source: [sources index](/sources/index.md) · [knowledge base index](/index.md)
- Related: [groth16-verifier-plutus](/cardano/groth16-verifier-plutus.md) ·
  [Midnight overview](/midnight/overview.md) ·
  [CIP-0381 — BLS12-381 builtins](/standards/cip-0381.md)
