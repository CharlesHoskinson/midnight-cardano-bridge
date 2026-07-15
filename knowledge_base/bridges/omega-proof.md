---
type: Concept
title: The Omega Proof — Genesis-Anchored ZK Attestation of Any Cardano Claim
timestamp: '2026-07-15T12:00:00Z'
description: Design for a single recursive accumulator proving Cardano chain validity and derived ledger state from genesis, against which any of the 42 catalogued Cardano claims can be proven and verified at O(1) cost, with measured per-block circuit sizes (K=22 R1CS / K=24 PLONKish).
aliases:
- omega proof
- genesis-anchored cardano proof
- cardano chain-fold accumulator
tags:
- bridge
- design
- recursion
- ivc
- groth16
- halo2
- cardano
- proof-claims
- omega
status: draft
okf_version: '1.0'
---

# The Omega Proof — Genesis-Anchored ZK Attestation of Any Cardano Claim

> **Status: draft design with measured feasibility.** The question this page
> answers: *is it possible to generate a proof about any of the
> [42 provable Cardano properties](../proof-claims/claim-interface-schema.md)
> such that a verifier can validate it against ALL epochs from genesis to the
> time the proof was committed?* The answer is **yes**, and the per-block
> circuit cost has been **measured, not estimated** (§6, Phase 0 spike). Chain
> statistics cited here were live-fetched 2026-07-15 (Koios / AdaStat, mainnet
> epoch 643); they are session research, not yet verbatim-gated KB pages.

## 1. Thesis

The [42-claim catalog](../proof-claims/claim-interface-schema.md) grades every
claim by its **anchor**: the commitment the proof is checked against. Today's
practical anchors — a [Mithril certificate](../cardano/mithril-bls-certificates.md),
a [Peras certificate](../cardano/ouroboros-peras-finality.md), a
[CIP-0165 SCLS root](../standards/cip-0165.md) — each attest a *snapshot*,
trusted because a stake quorum signed it. The **Omega proof** replaces the
snapshot anchor with the strongest anchor that can exist:

> **One recursively-maintained accumulator digest Ω that provably summarizes
> the entire Cardano chain — headers verified, ledger state re-derived — from
> the genesis block to the moment the proof lands on-chain.** Any of the 42
> claims, about any epoch in history, is then a short Merkle lookup against Ω.

Three facts make this buildable now rather than aspirational:

1. **Mina precedent.** A whole PoS chain can be compressed into one recursive
   SNARK; incrementally verifiable computation (IVC) is deployed technology.
   Midnight's own stack does recursion by
   [in-circuit KZG verification](../midnight/midnight-proofs-recursion.md)
   (128-bit truncated Fiat–Shamir, aPLONK committed instances) — no curve
   cycle needed.
2. **The Cardano landing is proven live.** A commitment-Groth16 verifier
   already [runs on Cardano Preview](groth16-cardano-preview-deployment.md)
   over the [CIP-0381](../standards/cip-0381.md) builtins at 32–39% of one
   transaction budget, 336-byte proofs, one public input.
3. **The per-block circuit is the size of a circuit already proven in 43
   seconds.** The Phase 0 spike (§6) measured the full Praos header validity
   check at **3,514,285 R1CS constraints (K=22)** — within 2% of the deployed
   recovery circuit (3,450,403, K=22) that proves in 43 s on a 24 GB machine.

## 2. The problem Omega must solve: Cardano headers commit no state

Verified against the ledger CDDL (shelley/babbage/conway): a Cardano header
carries `prev_hash`, `block_body_hash`, the VRF result, the KES signature and
operational certificate, and the protocol version. **There is no state root.**
Unlike Ethereum or Mina, nothing in a Cardano header commits to the UTxO set,
the stake distribution, reward accounts, or governance state — all of it is
*derived* by folding the ledger rules over every transaction since genesis.
This is exactly why [Mithril](../cardano/mithril-bls-certificates.md) exists,
and why [CIP-0165](../standards/cip-0165.md) proposes a canonical ledger-state
commitment going forward.

Two consequences shape the whole design:

- **The fold must carry the state itself.** A header-only light client cannot
  even validate headers (the VRF check needs the epoch's stake distribution
  and nonce, which come from *bodies*). So the Omega accumulator re-derives
  ledger state in-circuit and commits to it — this is the dominant cost, and
  also the payoff (§4): every claim the catalog grades "hard — needs ledger
  replay or a closed authenticated range" becomes a cheap lookup against
  state the fold already derived once, amortized over all claims forever.
- **History is finite and known.** Mainnet at epoch 643 (2026-07-15):
  13,681,784 blocks = **4.49M Byron headers + 9.19M Shelley-family (Praos)
  headers**, 435 Shelley-family epochs, ~220 GB chain, ~122.4M transactions,
  ~2,900 active SPOs, ~1.35M delegators. These numbers bound the one-time
  backfill (§6).

## 3. Architecture — four layers

### 3.1 Layer 1: the chain-fold IVC (the Ω-accumulator)

An IVC over every block since genesis, built on the
[Halo2/Plonkish](../proof-systems/halo2-plonkish.md) stack with
[midnight-proofs recursion](../midnight/midnight-proofs-recursion.md)
(KZG over BLS12-381 — the same
[unified substrate](midnight-cardano-recursive-bridge.md) as the bridge).
The carried state Σ is a bundle of commitment roots:

```
Σ = { utxo_root          — SMT over created outputs, with spent markers
                            (gives membership AND nonmembership/spent-status)
      tx_mmr             — our own MMR of tx ids per block (block_body_hash is a
                            flat hash, not proof-friendly; we build the tree Cardano didn't)
      stake_mark/set/go  — the three stake-snapshot roots (set gates the VRF check)
      pool_root          — pool registrations incl. VRF key hashes (header checks need them)
      reward_root        — reward accounts;  reward_event_mmr — reward/MIR/treasury events
      asset_root         — cumulative mint/burn accounting per (policy, asset)
      params_hash, era_id, nonce_state (evolving/candidate nonces)
      gov_root           — Conway governance state (proposals, votes, DReps, committee)
      epoch_mmr          — MMR of per-epoch bundles E_e (see below)              }
```

**Hash discipline (measured-cost-driven, §6):** one Blake2b-256 compression
costs ≈33k R1CS and one SHA-512 compression ≈128k. Therefore every
*Omega-internal* structure (SMTs, MMRs, epoch bundles) uses an **algebraic
hash (Poseidon-class over the BLS12-381 scalar field, ~2 orders of magnitude
cheaper)**; the bit-faithful Blake2b/SHA-512 price is paid only where Cardano
consensus fixes the hash — header hashes, tx ids, credentials, VRF/KES
internals.

**Per-block step circuit `S_block`** (measured: 3.51M R1CS, K=22 — §6):

1. chain link: `prev_hash` = Blake2b-256(previous header);
2. era-dependent VRF check: ECVRF-ED25519-SHA512-Elligator2 verify (two certs
   for TPraos epochs 208–364, one for Babbage+), input Blake2b(slot ‖ η_e),
   plus the leader-value / nonce-contribution derivations and the
   stake-threshold comparison against the pool's σ in `stake_set`;
3. Sum6 KES verification of the body signature (one Ed25519 leaf verify + a
   6-level Blake2b vkey tree — *not* seven signature checks);
4. operational certificate: Ed25519 verify under the pool cold key registered
   in `pool_root`, opcert counter monotonicity;
5. body application: parse the block body against `block_body_hash`, hash tx
   ids (Blake2b, consensus-fixed), apply inputs/outputs/certs/mint/withdrawals
   to the Σ roots (Poseidon SMT updates), fold the VRF output into
   `nonce_state`, append tx ids to `tx_mmr`.

**Per-epoch circuit `S_epoch`:** snapshot rotation (mark→set→go), **the reward
calculation** (unavoidable: rewards compound into stake, and stake gates the
VRF threshold — an Omega that skipped rewards could not even validate the next
epoch's headers), nonce finalization η_{e+1} = Blake2b(candidate ‖
lastBlockNonce), protocol-parameter and era transitions, then append the epoch
bundle **E_e = Poseidon(e, η_e, all Σ roots)** to `epoch_mmr`. The epoch MMR
is the "all epochs from genesis" mechanism: one digest, any historical epoch
extractable with a logarithmic path.

**Byron prologue:** a separate, cheaper step circuit (≈1.2M R1CS from the same
components): Ed25519 signature against the federated genesis delegation,
Blake2b chain links, epoch-boundary-block handling, no VRF/KES. Alternative: a
pinned checkpoint past Byron (what Ouroboros Genesis deployments do) — weaker,
and unnecessary given the modest cost.

**Backfill and steady state:** the fold is proof-carrying data, so the 13.7M
historical steps prove in parallel (chunk the chain, prove chunks
independently, binary-merge) — a one-time compute (§6). At the tip, one block
arrives every ~20 s on average and one S_block step is a 3.5M-constraint
proof: a single GPU-class prover keeps the accumulator current in real time.

### 3.2 Layer 2: the claim layer (where "Omega" universality lives)

The universality is **in the accumulator, not in a mega-circuit**. Each of the
42 claims gets a small claim circuit C_j whose public inputs are the
[claim envelope](../proof-claims/claim-envelope.md) and the Ω-digest, and whose
witness is: an `epoch_mmr` path → epoch bundle E_e → Merkle/SMT path(s) into
the relevant root(s) → the claim-specific predicate. Claim circuits are small
(tens of thousands to a few million constraints, K≈15–22). Dispatch is exactly
the [claim-interface-schema](../proof-claims/claim-interface-schema.md)
verifier registry: `predicateId` → pinned VK; the Omega anchor slots into the
existing envelope as `anchor_type = omega_accumulator`, `anchor_digest = Ω`.

### 3.3 Layer 3: the landing wrap

- **On Cardano (Groth16):** one
  [commitment-Groth16](../proof-systems/commitment-groth16.md) wrapper proves
  "a valid Halo2 chain-fold proof for Ω **and** a valid claim proof against Ω
  exist", public input `pub = H(envelope ‖ Ω)`. The verifier is an extension
  of the live
  [Preview deployment](groth16-cardano-preview-deployment.md)'s
  `groth16VerifyCommitted` (measured 3.2–3.9×10⁹ ExCPU = 32–39% of one tx
  budget). The open cost item is the Halo2-verifier-inside-Groth16 circuit
  (§9); the fallback is IOG's
  [Halo2-Plutus verifier](../cardano/halo2-plutus-verifier.md) directly (no
  wrap, no per-circuit setup — the same trade the
  [bridge design](midnight-cardano-recursive-bridge.md) weighs for its
  Midnight-to-Cardano landing).
- **On Midnight:** verify the Halo2 proof natively — recursion is free there.

### 3.4 Layer 4: self-checkpointing (closing the "time of commitment")

Every Omega proof committed on Cardano **pins its Ω-digest on-chain**; the
next proof must extend from the last committed digest. Cardano thereby becomes
the checkpoint ledger for the proof of its own history. Combined with the
in-circuit chain-selection rule (§5), this is what makes "genesis → the time
the proof was committed" literal: the commitment transaction itself closes the
interval, and a verifier of any later claim can walk the on-chain digest
lineage instead of trusting a prover-supplied tip.

## 4. Coverage: all 42 claims against Σ

Every claim in the catalog reads one or more Σ roots via an epoch bundle. The
formerly-"hard" rows are the point: **the expensive ledger replay is done once
inside the fold and amortized over every claim forever.**

| Claims (catalog IDs) | Group | Σ root(s) consumed | Notes |
|---|---|---|---|
| 1–4 | Chain & epoch context | `epoch_mmr` bundle fields (era_id, params_hash, η_e) | direct bundle reads |
| 5–9 | Tx & block facts | `tx_mmr` (+ witnessed tx body against its Blake2b tx id) | Omega builds the per-tx tree Cardano's flat `block_body_hash` never gave us |
| 10 | UTxO membership | `utxo_root` | SMT membership |
| **11** | **UTxO nonmembership / spent status** | `utxo_root` spent markers | **catalog grade "hard — needs closed authenticated range" → free**: the fold derived the full set |
| 12–15 | Output address/value/datum/script | `utxo_root` leaf = H(outref ‖ output) | leaf opening |
| 16, 18 | Mint/burn, metadata | `tx_mmr` + tx body | tx-level facts |
| **17** | **Asset supply at epoch E** | `asset_root` | catalog grade "derived/hard" → running total maintained by the fold |
| 19–25 | Script outcomes (all 7 purposes) | `tx_mmr` + block validity | **acceptance-implies-valid** under Model B (§5): a tx in a canonical block and not in `invalid_transactions` had all scripts pass; per-claim replay = Model A opt-in |
| 26–32 | Stake, delegation, pools | `stake_*`, `pool_root` | maintained anyway — the VRF check needs them |
| **33–37** | **Rewards, deposits, treasury, MIR** | `reward_root`, `reward_event_mmr` | catalog grade "hard; spans epochs" → natural byproduct of S_epoch's mandatory reward fold |
| 38–42 | Governance (CIP-1694) | `gov_root` + epoch-boundary bundles | ratification/expiry/enactment are epoch-boundary state transitions the fold already executes |

## 5. Security models — full replay vs consensus-anchored

**Model A — full validation replay.** The fold re-executes phase-1 ledger
rules *and* phase-2 Plutus evaluation (an untyped-Plutus-Core CEK machine
in-circuit, i.e. a Plutus zkVM). Strongest possible statement: "this chain is
valid under the ledger rules, full stop." Cost: a zkVM for UPLC plus cost-model
accounting across 10 protocol versions — multiplies proving cost severalfold
and is the single largest engineering item. Not recommended as the base.

**Model B — consensus-anchored (recommended).** The fold verifies everything
consensus-cryptographic — header chain, VRF against stake and nonce, KES,
opcerts, era/parameter transitions, plus the chain-selection rule (density /
Genesis-style within the fold; self-checkpointing pins the canonical tip
externally) — and *applies* block bodies without re-running Plutus. Soundness
assumption: **honest stake majority**, i.e. the canonical chain contains only
blocks honest nodes fully validated. This is *identical* to the assumption
every Cardano full node already makes when it selects the densest/longest
valid chain — Omega adds no new trust. Script-outcome claims come free via
acceptance-implies-valid (§4, claims 19–25).

**The doc's recommendation: Model B as the accumulator's base, Model A as a
per-claim opt-in** — when a consumer demands it, a claim circuit can re-execute
*one transaction's* scripts (bounded, known cost) against inputs proven from
`utxo_root`, without ever paying for a full-chain zkVM.

| | Model A (full replay) | Model B (consensus-anchored) |
|---|---|---|
| Statement | chain valid under ledger rules | chain canonical under honest-majority consensus |
| Extra assumption | none beyond crypto | honest stake majority (same as every node) |
| Plutus zkVM | required, full-chain | none (opt-in per claim) |
| Relative fold cost | several × | 1× (measured, §6) |

## 6. K complexity — measured, then totaled

Phase 0 spike: `spikes/omega-header-circuit` (private workspace; results file
`RESULTS.md`), gnark v0.15.0 over the BLS12-381 scalar field, reusing the
audited proof-zk-recovery gadgets (emulated Ed25519, SHA-512, Blake2b) plus
new variable-base scalar-mult, ECVRF (draft-03 incl. Elligator2), Sum6 KES and
RFC-8032 gadgets. Compile-only counts (structurally faithful, not yet
test-vectored); K = ⌈log₂(constraints)⌉.

| circuit | R1CS | K | PLONKish (scs) | K |
|---|---:|:-:|---:|:-:|
| SHA-512, one block region | 256,668 | 18 | 799,300 | 20 |
| Blake2b-256, 896-byte header | 230,189 | 18 | 760,935 | 20 |
| `[s]B` fixed-base (windowed) | 60,889 | 16 | 215,994 | 18 |
| `[s]P` variable-base, 256-bit | 370,440 | 19 | 1,273,989 | 21 |
| Ed25519 verify (opcert shape) | 978,410 | 20 | 3,308,257 | 22 |
| ECVRF verify (full, incl. β) | 1,147,114 | 21 | 3,834,727 | 22 |
| Sum6 KES verify (header msg) | 1,539,233 | 21 | 5,100,199 | 23 |
| **S_block composed (Babbage+)** | **3,514,285** | **22** | **11,859,251** | **24** |

Derived figures (estimates around the measured core):

- **TPraos step** (epochs 208–364, two VRF certs): ≈ +1.15M → ~4.7M R1CS.
- **Byron step:** ≈1.2M R1CS (Ed25519 + Blake2b only).
- **Body application** (Model B): tx-id hashing is consensus-Blake2b over ~1.8
  KB average tx (~14 compressions ≈ 0.47M R1CS/tx); Σ-root updates are
  Poseidon SMT paths (~10–30k R1CS per update) — body work lands at roughly
  1–3× the header check per block and, over history (122.4M txs), ≈2^45–2^46
  total.
- **S_epoch reward fold:** per-delegator Poseidon updates over ~1.35M
  delegators ≈ 2^36–2^38 per epoch, tree-split into K=22 sub-proofs; ≈2^45–2^46
  over 435 epochs. Co-dominant with headers — and unavoidable (stake gates
  VRF).
- **Recursion overhead:** in-circuit KZG verification per step
  ([midnight-proofs recursion](../midnight/midnight-proofs-recursion.md)),
  ~2^17–2^19 rows — noise against a 12M-row step.
- **Claim circuits:** K = 15–22 (epoch-MMR path + SMT openings + predicate).
- **Groth16 landing wrap** (Halo2 verifier in a Groth16 circuit): estimated
  20–40M constraints, K = 25–26 — **the riskiest unmeasured item** (§9), with
  the direct Halo2-Plutus landing as fallback.

**Totals.** Headers: 9.19M × 3.5–4.7M + 4.49M × 1.2M ≈ 2^45. Bodies ≈
2^45–2^46. Rewards ≈ 2^45–2^46. **Grand total ≈ 2^46–2^47 constraint-work from
genesis to epoch 643**, compressed by IVC/PCD into **one proof whose verifier
is O(1) regardless of history length** — one Groth16 verify on Plutus V3,
already measured live at 32–39% of a transaction budget.

**Proving economics.** Backfill ≈ 0.7–1.4×10¹⁴ constraints: at 10⁶–10⁷
constraints/s per GPU-class worker, ~100–1,600 GPU-days — embarrassingly
parallel (a 100-worker fleet: days to weeks, one time). Steady state: ~3.5M
R1CS (12M Plonkish rows) per ~20 s block — the same class as the recovery
circuit's measured 43 s CPU prove, i.e. one accelerated box (or a couple of
CPU boxes pipelined) holds the tip. Epoch boundaries add a burst once per 5
days.

## 7. What lands on-chain

Identical shape to the [bridge](midnight-cardano-recursive-bridge.md) Direction
A landing: 336-byte commitment-Groth16 proof, one public input
`pub = H(claim envelope ‖ Ω)`, validator reconstructs `pub` itself
([zk-recovery architecture](zk-recovery-architecture.md) discipline: never
trust a prover-supplied public input), VK pinned as an immutable parameter,
nullifier spent-map for consumable claims, plus the Layer-4 digest-lineage
datum. Budget: verify ≈32%, full claim-consume branch ≈39–55% measured on
Preview — batching amortizes ~8–15 claims per transaction.

## 8. Roadmap

- **Phase 0 — header-circuit spike: DONE** (§6). Real K for S_block: 22
  (R1CS) / 24 (Plonkish, untuned).
- **Phase 1 — consensus fold, interim anchor:** implement S_block IVC in the
  midnight-zk stack with **Mithril-certified stake snapshots as witness
  anchors** (skip reward derivation); Omega inherits Mithril's trust
  temporarily but the pipeline, epoch MMR, and claim layer are real.
- **Phase 2 — full state derivation:** add S_epoch (rewards, snapshots, era
  transitions) and the Byron prologue → drop the Mithril anchor; Omega is now
  genesis-anchored. Backfill fleet run.
- **Phase 3 — claim layer:** the 42 claim circuits + registry entries
  (`anchor_type = omega_accumulator`), per the existing
  [claim-interface-schema](../proof-claims/claim-interface-schema.md).
- **Phase 4 — landing + self-checkpointing:** extend the Preview
  `groth16VerifyCommitted` validator with the digest-lineage datum; measure
  the Halo2-in-Groth16 wrap vs the direct Halo2-Plutus verifier and pick.

## 9. Open problems

1. **Reward-rule fidelity.** The Shelley reward calculation (spec figures
   46–52), pool ranking, and its era-by-era patches must be mirrored
   in-circuit exactly; largest spec-to-circuit surface. The
   "one relation, four descriptions" discipline from proof-zk-recovery
   (spec / circuit / on-chain / Lean) applies.
2. **Halo2-verifier-in-Groth16 cost** — unmeasured (est. K=25–26); fallback =
   direct [Halo2-Plutus verifier](../cardano/halo2-plutus-verifier.md).
3. **Chain-selection in-circuit.** Model B needs a density/Genesis-style rule
   or an explicit statement that canonicity is pinned by Layer-4
   self-checkpointing plus the honest-majority assumption; the exact
   formulation deserves its own page.
4. **Data availability for proving.** The backfill needs all ~220 GB with
   deterministic serialization (archive node or Mithril DB snapshots as *data
   source only* — no trust inherited).
5. **Era-rule divergence.** Ten protocol versions of header/body/ledger deltas
   (TPraos↔Praos VRF format, Alonzo `invalid_transactions`, Conway
   governance) — each is a circuit variant the IVC must dispatch on `era_id`.
6. **Poseidon parameterization** over BLS12-381 Fr for the Σ structures
   (choice, security margin, lookup-friendly alternative like Griffin/Anemoi) —
   pick once, early; it is baked into every root.
7. **Spike hardening.** The Phase 0 circuits are compile-measured but not
   test-vectored; wire real header vectors (Koios) through witness solving
   before trusting the gadgets themselves.

## 10. Provenance

- Measured circuit numbers: `spikes/omega-header-circuit/RESULTS.md`
  (2026-07-15, gnark v0.15.0, reusing proof-zk-recovery gadgets; private
  workspace, not in this repo).
- Deployed Groth16 verifier numbers:
  [Preview deployment](groth16-cardano-preview-deployment.md) /
  [on-chain cost](../cardano/groth16-onchain-cost.md).
- Chain statistics (block heights, era boundaries, epoch/delegator/SPO counts,
  chain size): live Koios + AdaStat fetches, 2026-07-15, mainnet epoch 643.
- Header/CDDL structure (no state root; TPraos vs Praos VRF fields; Byron
  formats): IntersectMBO/cardano-ledger CDDL specs, fetched 2026-07-15.
- Claim catalog and envelope:
  [claim-interface-schema](../proof-claims/claim-interface-schema.md),
  [claim-envelope](../proof-claims/claim-envelope.md),
  [anchor-trust-models](../proof-claims/anchor-trust-models.md).
- Substrate and recursion context:
  [recursive bridge design](midnight-cardano-recursive-bridge.md),
  [midnight-proofs recursion](../midnight/midnight-proofs-recursion.md),
  [halo2-plonkish](../proof-systems/halo2-plonkish.md),
  [CIP-0381](../standards/cip-0381.md), [CIP-0165](../standards/cip-0165.md).
