---
type: Concept
title: Groth16 trusted-setup ceremony (per-circuit MPC)
timestamp: '2026-07-09T14:27:04Z'
description: Why Groth16 needs a per-circuit MPC trusted setup (Powers of Tau + circuit-specific
  phase 2), its 1-of-N honest-participant trust assumption and toxic-waste risk, and
  what that means for the Midnight to Cardano proof direction.
resource: https://github.com/CharlesHoskinson/proof-zk-recovery/blob/proto/preprod-experiments/docs/trusted-setup-ceremony.md
tags:
- groth16
- trusted-setup
- mpc
- powers-of-tau
- ceremony
- trust-assumption
source: src-0014
status: researched
okf_version: '1.0'
---

# Groth16 trusted-setup ceremony (per-circuit MPC)

Groth16 is the proof system chosen for the **Midnight → Cardano** direction of
the recursive bridge study: it produces the compact, pairing-checkable proofs
that Cardano's on-chain BLS12-381 primitives can verify (see
[commitment to Groth16](/proof-systems/commitment-groth16.md)). Its one hard
caveat is that Groth16 needs a **trusted setup** to generate its structured
reference string, and part of that setup is **per circuit**. This page captures
what that ceremony is, the trust it demands, and how that contrasts with the
no-trusted-setup Halo2 side of the bridge. It is grounded in a design note for
the ZK recovery circuit (gnark Groth16, BLS12-381, 3,450,403 constraints →
domain size N = 2^22). See the [knowledge base index](/index.md) and the
[sources index](/sources/index.md).

## Two phases: Powers of Tau, then a per-circuit phase 2

The setup is a **two-phase MPC** — gnark ships a native two-phase implementation
for BLS12-381, run twice with the same machinery:

- **Phase 1 (Powers of Tau)** is **circuit-independent**: a single Phase 1 of
  size N is *reusable* for any future circuit up to that size, so it is paid for
  once.
- **Phase 2** is **circuit-specific**. This is the sense in which "Groth16 needs
  a per-circuit trusted setup": every distinct circuit requires its own fresh
  phase-2 ceremony (which consumes the shared phase-1 output). Change the circuit
  — and a bridge that upgrades its verifier statement will — and phase 2 must be
  re-run.

The toxic waste (the secrets that must be destroyed) is **τ, α, β in phase 1**
and **γ, δ in phase 2**; each is a uniformly random multiplier that stays secret
so long as the ceremony is honest.

## The MPC structure and the 1-of-N trust assumption

The ceremony implements the **BGM17** protocol with a **proof-of-knowledge per
contribution**, a **SHA-256 hash-chained transcript**, and a **final beacon
step**. Participants contribute sequentially: each folds fresh randomness into
the transcript, emits a PoK, and destroys its secret.

The load-bearing property is the **1-of-N honest-participant assumption**: the
setup is *sound if at least one participant in each phase honestly samples and
deletes its secret*. The participants **need not trust each other**, and the
phase-1 and phase-2 participant sets can be **disjoint**. An adversary can only
recover the toxic waste (and thus forge proofs) if it compromises *every*
participant of a phase. This is why ceremonies recruit dozens of diverse,
jurisdictionally-independent contributors: the goal is to make "all of them are
malicious" implausible.

Two structural safeguards back this up:

- A public **randomness beacon** (drand) is applied after the last human
  contribution as the final, non-secret step, removing any residual bias the
  last participant could introduce.
- The **coordinator** can censor or abort the ceremony but, by BGM17, **cannot
  break soundness** — it never holds a secret. The worst it can do is force a
  re-run.

## Verifiability

The ceremony is designed to be **publicly re-verifiable**, which is what lets a
bridge treat the resulting verifying key as trustworthy without trusting the
operators:

- **Anyone can re-verify the whole ceremony** by replaying `VerifyPhase1` /
  `VerifyPhase2` over the public transcript.
- The **per-contribution PoK + hash chain** means reordering, inserting, or
  editing any contribution breaks the chain, and a zero-multiplier
  ("contribute 1") no-op is rejected by the PoK.
- **Deployment must be checked separately.** The setup output being sound is not
  enough: the **Veil Cash** drain came from a *deployed* verifier with
  γ = δ = generator while the ceremony itself was fine. The verifying key
  actually embedded on-chain must be proven byte-equal to the one recomputed from
  the sealed transcript (plus a forgery test). For the bridge this means the
  Cardano-side Groth16 validator's VK must be provably the ceremony's output.

A recurring lesson from the design note: the historical failure mode is not too
few participants but **software monoculture** — one backdoored binary turns an
M-of-M ceremony into 0-of-M — so an independent second verifier implementation
is the highest-value control.

## Implication for the bridge: setup asymmetry between the two directions

The two proof directions of the bridge sit on opposite sides of the
trusted-setup line, and this ceremony is exactly why:

- **Midnight → Cardano (Groth16):** carries a **trust assumption from a
  per-circuit MPC ceremony**. Soundness rests on 1-of-N honesty plus a correct
  deployment check. Every circuit revision incurs a fresh phase-2 ceremony. The
  upside is small, pairing-checkable proofs that Cardano can verify cheaply.
- **Cardano → Midnight (Plonk/Halo2):** the
  [PLONKish/Halo2 side](/proof-systems/halo2-plonkish.md) uses a **universal
  setup that serves many circuits** — no fresh per-circuit trusted-setup MPC, and
  in the Halo2 accumulation setting no toxic waste of the Groth16 kind to
  destroy. This is what makes iterated proof composition (recursion) practical on
  that side.

So the trust caveat of the whole bridge is concentrated on the **Groth16
direction**: it is the only side whose soundness depends on a trusted-setup
ceremony having been run honestly and deployed faithfully. That is the risk to
manage — via a credible, diverse, independently-verified ceremony and a
VK-equality check at deployment — rather than a property that can be assumed
away.

> Note: this page is grounded in a single design note about a specific gnark
> Groth16 / BLS12-381 recovery circuit and its planned ceremony; the general
> Groth16-vs-Halo2 setup contrast is synthesis for the bridge study and should be
> corroborated against the dedicated proof-system pages and primary sources
> (BGM17, ZKProof setup-ceremony guidance).
