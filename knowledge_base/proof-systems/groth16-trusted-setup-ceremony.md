---
type: Concept
title: Groth16 trusted-setup ceremony (per-circuit MPC)
timestamp: '2026-07-12T02:09:54Z'
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
source_receipts:
- source.external.gnark-bsb22-mpc.2026-07-12
- source.external.proof-zk-recovery-mpc.2026-07-12
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
what that ceremony is, the trust it demands, and how its per-circuit setup differs
from the Halo2/KZG side's universal SRS. It is grounded in a design note for
the ZK recovery circuit (gnark Groth16, BLS12-381, 3,450,403 constraints →
domain size N = 2^22). See the [knowledge base index](/index.md) and the
[sources index](/sources/index.md). The commitment-aware setup details below are
bound to the [fresh gnark MPC source receipt](../program-wiki/raw/source-receipts/gnark-bsb22-mpc-2026-07-12.md).

No bridge ceremony has run. This page separates behavior observed in pinned
source from controls the bridge must implement before any human contribution can
count.

## Two phases: Powers of Tau, then a per-circuit phase 2

The setup is a **two-phase MPC**. The bridge pins the commitment-aware BSB22
implementation in a pinned, not yet reviewed gnark fork, so its setup variables and checks
must be described exactly rather than inferred from vanilla Groth16:

- **Groth16 Phase 1 (Powers of Tau)** is **circuit-independent**: a single Phase 1 of
  size N is *reusable* for any future circuit up to that size, so it is paid for
  once.
- **commitment-aware (BSB22) Phase 2** is **circuit-specific**. This is the sense in which "Groth16 needs
  a per-circuit trusted setup": every distinct circuit requires its own fresh
  phase-2 ceremony (which consumes the shared phase-1 output). Change the circuit
  and phase 2 must be
  re-run.

In the pinned suite, contributors update **tau, alpha, and beta in Phase 1**.
Each circuit's Phase 2 updates **delta** and one **sigma** value for every
commitment group. The verifier checks a PoK for delta across the G1 and G2 delta
points and the inverse-scaled proving-key terms. It also checks each sigma PoK
across the matching G1 commitment bases and G2 sigma point. Key sealing derives
`GSigmaNeg = -[sigma]G2`. The suite sets `gamma` to the standard BLS12-381 G2
generator; gamma is not a contributed Phase 2 secret. Soundness therefore
requires at least one honest contributor in Phase 1 to delete that contributor's
tau, alpha, and beta secrets, and at least one honest contributor in each
distinct circuit-specific Phase 2 to delete that contributor's delta and every
sigma secret.

## The MPC structure and the 1-of-N trust assumption

The ceremony implements the **BGM17** protocol with a **proof-of-knowledge per
contribution**, a **SHA-256 hash-chained transcript**, and a **final beacon
step**. Participants contribute sequentially: each folds fresh randomness into
the transcript, emits the required PoKs, and destroys its secrets.

The load-bearing property is the **1-of-N honest-participant assumption**: the
setup is *sound if at least one participant in each phase honestly samples and
deletes its secret*. The participants **need not trust each other**, and the
phase-1 and phase-2 participant sets can be **disjoint**. An adversary can only
recover the toxic waste (and thus forge proofs) if it compromises *every*
participant of a phase. This is why ceremonies recruit dozens of diverse,
jurisdictionally-independent contributors: the goal is to make "all of them are
malicious" implausible.

The pinned prototype does not yet provide the bridge safeguards below: it
accepts a caller-supplied beacon and its example path compiles a mini circuit.
The bridge requires:

- In `new-or-update` mode, each distinct transcript must have its own precommitted future **randomness beacon**
  applied after that transcript's last human contribution. The KZG ceremony,
  Groth16 Phase 1, and every circuit-specific Phase 2 use separate domains,
  close points, beacon resolutions, sealed heads, acknowledgements, and public
  anchors. The policy must select a publicly verifiable, independently operated
  source with authenticated timestamped output, unpredictability until a
  post-close resolution point, a stable archive, and an independent verifier. A
  beacon disclosed for one transcript cannot seal a later one. Historical
  qualification verifies the original beacon and never attaches a new one to
  old bytes.
- The **coordinator** can censor or abort the ceremony but, by BGM17, **cannot
  break soundness** because it never holds a secret. The worst it can do is force a
  re-run.

## Verifiability

The bridge ceremony must be **publicly re-verifiable**, which is what lets a
bridge treat the resulting verifying key as trustworthy without trusting the
operators:

- **Any independent verifier must be able to re-verify the whole ceremony** by replaying `VerifyPhase1` and
  `VerifyPhase2` over the public transcripts, including every delta and sigma
  update and PoK.
- The **per-contribution PoK + hash chain** means reordering, inserting, or
  editing any contribution breaks the chain, and a zero-multiplier
  ("contribute 1") no-op is rejected by the PoK.
- **Deployment must be checked separately.** A sound transcript does not protect
  a destination that embeds different verifier bytes. The verifying key and
  commitment keys actually deployed on-chain must be byte-equal to the values
  recomputed from the sealed transcript, including the fixed gamma rule and all
  `GSigmaNeg` points. The deployment suite also needs a forgery rejection test.

A recurring lesson from the design note is that participant count cannot offset
**software monoculture**. One backdoored binary turns an M-of-M ceremony into
0-of-M, so an independent second verifier implementation is the strongest
control.

## Implication for the bridge: setup asymmetry between the two directions

Both proof directions inherit KZG SRS trust. The extra setup cost lies on the
Midnight-to-Cardano path:

- **Midnight → Cardano (Groth16):** depends on the Halo2/KZG SRS used by the
  inner proof and also carries a separate reusable Groth16 Phase 1 (Powers of Tau) plus a
  **per-circuit commitment-aware (BSB22) Phase 2 trust assumption**. Soundness rests on
  the required 1-of-N honesty for each setup transcript plus correct deployment.
  Every circuit revision incurs a fresh Phase 2 ceremony. The result is a small
  pairing-checkable proof that Cardano can verify.
- **Cardano → Midnight (Plonk/Halo2):** the
  [PLONKish/Halo2 side](/proof-systems/halo2-plonkish.md) uses a universal KZG
  SRS that can serve many circuits. It does not require a fresh Groth16 Phase 2
  for each circuit, but the KZG SRS still has its own setup trust, transcript,
  and qualification requirements.

The asymmetry is a KZG universal SRS versus that same KZG trust plus a separate
reusable Groth16 Phase 1 (Powers of Tau) and per-circuit commitment-aware (BSB22) Phase 2, not trusted setup versus no
trusted setup. Both paths require an authenticated, qualified KZG SRS. Midnight
to Cardano also requires independently verified commitment-Groth16
ceremonies and byte-equal deployment of their VK and commitment keys.

> Note: the original recovery-circuit design note supplies context. The exact
> commitment-aware `tau/alpha/beta/delta/sigma/gamma` behavior comes from the
> pinned gnark source receipt linked above. The broader setup comparison should
> also be checked against BGM17 and setup-ceremony guidance.
