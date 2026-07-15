---
type: Concept
title: 'The Omega proof: genesis-anchored ZK attestation of any Cardano claim'
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
- applications
status: draft
okf_version: '1.0'
---

# The Omega proof: genesis-anchored ZK attestation of any Cardano claim

> **Status: draft design with measured feasibility.** This page answers one
> question: is it possible to generate a proof about any of the
> [42 provable Cardano properties](../proof-claims/claim-interface-schema.md)
> such that a verifier can validate it against all epochs from genesis to the
> time the proof was committed? The answer is yes. The per-block circuit cost
> is measured, not estimated (see the Phase 0 spike in §6). Chain statistics
> cited here were live-fetched 2026-07-15 (Koios / AdaStat, mainnet epoch
> 643); they are session research, not yet verbatim-gated KB pages.

## 1. Thesis

The [42-claim catalog](../proof-claims/claim-interface-schema.md) grades every
claim by its anchor, meaning the commitment the proof is checked against.
Today's practical anchors each attest a snapshot that you trust because a
stake quorum signed it: a
[Mithril certificate](../cardano/mithril-bls-certificates.md), a
[Peras certificate](../cardano/ouroboros-peras-finality.md), or a
[CIP-0165 SCLS root](../standards/cip-0165.md). The Omega proof replaces the
snapshot anchor with something that needs no signer set at all:

> One recursively maintained accumulator digest Ω that provably summarizes the
> entire Cardano chain, headers verified and ledger state re-derived, from the
> genesis block to the moment the proof lands on-chain. Any of the 42 claims,
> about any epoch in history, is then a short Merkle lookup against Ω.

Three facts make this buildable now:

1. **Mina precedent.** A whole proof-of-stake chain can be compressed into one
   recursive SNARK; incrementally verifiable computation (IVC) is deployed
   technology, not a research bet. Midnight's own stack does recursion by
   [in-circuit KZG verification](../midnight/midnight-proofs-recursion.md)
   (128-bit truncated Fiat-Shamir challenges, aPLONK committed instances). No
   curve cycle is needed.
2. **The Cardano landing is proven live.** A commitment-Groth16 verifier
   already [runs on Cardano Preview](groth16-cardano-preview-deployment.md)
   over the [CIP-0381](../standards/cip-0381.md) builtins at 32 to 39% of one
   transaction budget, with 336-byte proofs and one public input.
3. **The per-block circuit is the size of a circuit already proven in 43
   seconds.** The Phase 0 spike (§6) measured the full Praos header validity
   check at 3,514,285 R1CS constraints (K=22), within 2% of the deployed
   recovery circuit (3,450,403, K=22) that proves in 43 s on a 24 GB machine.

## 2. The problem Omega must solve: Cardano headers commit no state

Verified against the ledger CDDL (shelley/babbage/conway): a Cardano header
carries `prev_hash`, `block_body_hash`, the VRF result, the KES signature and
operational certificate, and the protocol version. There is no state root.
Unlike Ethereum or Mina, nothing in a Cardano header commits to the UTxO set,
the stake distribution, reward accounts, or governance state. All of that is
derived by folding the ledger rules over every transaction since genesis.
This is why [Mithril](../cardano/mithril-bls-certificates.md) exists, and why
[CIP-0165](../standards/cip-0165.md) proposes a canonical ledger-state
commitment going forward.

Two consequences shape the whole design:

- **The fold must carry the state itself.** A header-only light client cannot
  even validate headers, because the VRF check needs the epoch's stake
  distribution and nonce, and those come from block bodies. So the Omega
  accumulator re-derives ledger state in-circuit and commits to it. That is
  the dominant cost. It is also the payoff (§4): every claim the catalog
  grades "hard, needs ledger replay or a closed authenticated range" becomes a
  cheap lookup against state the fold already derived once, amortized over
  all claims forever.
- **History is finite and known.** Mainnet at epoch 643 (2026-07-15):
  13,681,784 blocks, split into 4.49M Byron headers and 9.19M Shelley-family
  (Praos) headers, across 435 Shelley-family epochs, roughly 220 GB of chain,
  about 122.4M transactions, about 2,900 active SPOs, and about 1.35M
  delegators. These numbers bound the one-time backfill (§6).

## 3. Architecture: four layers

### 3.1 Layer 1: the chain-fold IVC (the Ω-accumulator)

An IVC over every block since genesis, built on the
[Halo2/Plonkish](../proof-systems/halo2-plonkish.md) stack with
[midnight-proofs recursion](../midnight/midnight-proofs-recursion.md)
(KZG over BLS12-381, the same
[unified substrate](midnight-cardano-recursive-bridge.md) as the bridge).
The carried state Σ is a bundle of commitment roots:

```
Σ = { utxo_root         : SMT over created outputs, with spent markers
                           (gives membership AND nonmembership/spent-status)
      tx_mmr            : our own MMR of tx ids per block (block_body_hash is a
                           flat hash, not proof-friendly; we build the tree Cardano didn't)
      stake_mark/set/go : the three stake-snapshot roots (set gates the VRF check)
      pool_root         : pool registrations incl. VRF key hashes (header checks need them)
      reward_root       : reward accounts;  reward_event_mmr : reward/MIR/treasury events
      asset_root        : cumulative mint/burn accounting per (policy, asset)
      params_hash, era_id, nonce_state (evolving/candidate nonces)
      gov_root          : Conway governance state (proposals, votes, DReps, committee)
      epoch_mmr         : MMR of per-epoch bundles E_e (see below)              }
```

**Hash discipline** (driven by the measured costs in §6): one Blake2b-256
compression costs about 33k R1CS and one SHA-512 compression about 128k. So
every Omega-internal structure (SMTs, MMRs, epoch bundles) uses an algebraic
hash (Poseidon-class over the BLS12-381 scalar field, roughly two orders of
magnitude cheaper). The bit-faithful Blake2b/SHA-512 price is paid only where
Cardano consensus fixes the hash: header hashes, tx ids, credentials, and the
VRF/KES internals.

**Per-block step circuit `S_block`** (measured: 3.51M R1CS, K=22, §6):

1. chain link: `prev_hash` = Blake2b-256(previous header);
2. era-dependent VRF check: ECVRF-ED25519-SHA512-Elligator2 verify (two certs
   for TPraos epochs 208 to 364, one for Babbage and later), input
   Blake2b(slot ‖ η_e), plus the leader-value and nonce-contribution
   derivations and the stake-threshold comparison against the pool's σ in
   `stake_set`;
3. Sum6 KES verification of the body signature (one Ed25519 leaf verify plus a
   6-level Blake2b vkey tree, not seven signature checks);
4. operational certificate: Ed25519 verify under the pool cold key registered
   in `pool_root`, opcert counter monotonicity;
5. body application: parse the block body against `block_body_hash`, hash tx
   ids (Blake2b, consensus-fixed), apply inputs/outputs/certs/mint/withdrawals
   to the Σ roots (Poseidon SMT updates), fold the VRF output into
   `nonce_state`, append tx ids to `tx_mmr`.

**Per-epoch circuit `S_epoch`:** snapshot rotation (mark→set→go), the reward
calculation (unavoidable: rewards compound into stake, and stake gates the
VRF threshold, so an Omega that skipped rewards could not validate the next
epoch's headers), nonce finalization η_{e+1} = Blake2b(candidate ‖
lastBlockNonce), protocol-parameter and era transitions, then append the epoch
bundle E_e = Poseidon(e, η_e, all Σ roots) to `epoch_mmr`. The epoch MMR is
the "all epochs from genesis" mechanism: one digest, any historical epoch
extractable with a logarithmic path.

**Byron prologue:** a separate, cheaper step circuit (about 1.2M R1CS from the
same components): Ed25519 signature against the federated genesis delegation,
Blake2b chain links, epoch-boundary-block handling, no VRF/KES. The
alternative is a pinned checkpoint past Byron, which is what Ouroboros Genesis
deployments do. That is weaker, and unnecessary given the modest cost.

**Backfill and steady state:** the fold is proof-carrying data, so the 13.7M
historical steps prove in parallel (chunk the chain, prove chunks
independently, binary-merge). That is a one-time compute (§6). At the tip,
one block arrives every ~20 s on average and one S_block step is a
3.5M-constraint proof, so a single GPU-class prover keeps the accumulator
current in real time.

### 3.2 Layer 2: the claim layer (where "Omega" universality lives)

The universality is in the accumulator, not in a mega-circuit. Each of the 42
claims gets a small claim circuit C_j whose public inputs are the
[claim envelope](../proof-claims/claim-envelope.md) and the Ω-digest, and whose
witness is: an `epoch_mmr` path → epoch bundle E_e → Merkle/SMT path(s) into
the relevant root(s) → the claim-specific predicate. Claim circuits are small
(tens of thousands to a few million constraints, K of about 15 to 22).
Dispatch is exactly the
[claim-interface-schema](../proof-claims/claim-interface-schema.md) verifier
registry: `predicateId` maps to a pinned VK, and the Omega anchor slots into
the existing envelope as `anchor_type = omega_accumulator`,
`anchor_digest = Ω`.

### 3.3 Layer 3: the landing wrap

- **On Cardano (Groth16):** one
  [commitment-Groth16](../proof-systems/commitment-groth16.md) wrapper proves
  "a valid Halo2 chain-fold proof for Ω and a valid claim proof against Ω
  exist", with public input `pub = H(envelope ‖ Ω)`. The verifier is an
  extension of the live
  [Preview deployment](groth16-cardano-preview-deployment.md)'s
  `groth16VerifyCommitted` (measured 3.2 to 3.9×10⁹ ExCPU, or 32 to 39% of one
  tx budget). The open cost item is the Halo2-verifier-inside-Groth16 circuit
  (§10); the fallback is IOG's
  [Halo2-Plutus verifier](../cardano/halo2-plutus-verifier.md) directly (no
  wrap, no per-circuit setup, the same trade the
  [bridge design](midnight-cardano-recursive-bridge.md) weighs for its
  Midnight-to-Cardano landing).
- **On Midnight:** verify the Halo2 proof natively. Recursion is free there.

### 3.4 Layer 4: self-checkpointing (closing the "time of commitment")

Every Omega proof committed on Cardano pins its Ω-digest on-chain, and the
next proof must extend from the last committed digest. Cardano thereby becomes
the checkpoint ledger for the proof of its own history. Combined with the
in-circuit chain-selection rule (§5), this makes "genesis to the time the
proof was committed" literal: the commitment transaction itself closes the
interval, and a verifier of any later claim can walk the on-chain digest
lineage instead of trusting a prover-supplied tip.

## 4. Coverage: all 42 claims against Σ

Every claim in the catalog reads one or more Σ roots via an epoch bundle. The
formerly-"hard" rows are the point: the expensive ledger replay is done once
inside the fold and amortized over every claim forever.

| Claims (catalog IDs) | Group | Σ root(s) consumed | Notes |
|---|---|---|---|
| 1 to 4 | Chain and epoch context | `epoch_mmr` bundle fields (era_id, params_hash, η_e) | direct bundle reads |
| 5 to 9 | Tx and block facts | `tx_mmr` (plus witnessed tx body against its Blake2b tx id) | Omega builds the per-tx tree Cardano's flat `block_body_hash` never gave us |
| 10 | UTxO membership | `utxo_root` | SMT membership |
| 11 | UTxO nonmembership / spent status | `utxo_root` spent markers | catalog grade "hard, needs closed authenticated range" becomes free: the fold derived the full set |
| 12 to 15 | Output address/value/datum/script | `utxo_root` leaf = H(outref ‖ output) | leaf opening |
| 16, 18 | Mint/burn, metadata | `tx_mmr` plus tx body | tx-level facts |
| 17 | Asset supply at epoch E | `asset_root` | catalog grade "derived/hard" becomes a running total maintained by the fold |
| 19 to 25 | Script outcomes (all 7 purposes) | `tx_mmr` plus block validity | acceptance-implies-valid under Model B (§5): a tx in a canonical block and not in `invalid_transactions` had all scripts pass; per-claim replay = Model A opt-in |
| 26 to 32 | Stake, delegation, pools | `stake_*`, `pool_root` | maintained anyway; the VRF check needs them |
| 33 to 37 | Rewards, deposits, treasury, MIR | `reward_root`, `reward_event_mmr` | catalog grade "hard; spans epochs" becomes a natural byproduct of S_epoch's mandatory reward fold |
| 38 to 42 | Governance (CIP-1694) | `gov_root` plus epoch-boundary bundles | ratification/expiry/enactment are epoch-boundary state transitions the fold already executes |

## 5. Security models: full replay vs consensus-anchored

**Model A, full validation replay.** The fold re-executes phase-1 ledger
rules and phase-2 Plutus evaluation (an untyped-Plutus-Core CEK machine
in-circuit, in other words a Plutus zkVM). Strongest possible statement:
"this chain is valid under the ledger rules, full stop." The cost is a zkVM
for UPLC plus cost-model accounting across 10 protocol versions. That
multiplies proving cost severalfold and is the single largest engineering
item. Not recommended as the base.

**Model B, consensus-anchored (recommended).** The fold verifies everything
consensus-cryptographic: header chain, VRF against stake and nonce, KES,
opcerts, era and parameter transitions, plus the chain-selection rule
(density / Genesis-style within the fold; self-checkpointing pins the
canonical tip externally). It then applies block bodies without re-running
Plutus. The soundness assumption is honest stake majority, that is, the
canonical chain contains only blocks honest nodes fully validated. This is
the same assumption every Cardano full node already makes when it selects
the densest or longest valid chain, so Omega adds no new trust.
Script-outcome claims come free via acceptance-implies-valid (§4, claims 19
to 25).

The recommendation: Model B as the accumulator's base, Model A as a per-claim
opt-in. When a consumer demands it, a claim circuit can re-execute one
transaction's scripts (bounded, known cost) against inputs proven from
`utxo_root`, without ever paying for a full-chain zkVM.

| | Model A (full replay) | Model B (consensus-anchored) |
|---|---|---|
| Statement | chain valid under ledger rules | chain canonical under honest-majority consensus |
| Extra assumption | none beyond crypto | honest stake majority (same as every node) |
| Plutus zkVM | required, full-chain | none (opt-in per claim) |
| Relative fold cost | several × | 1× (measured, §6) |

## 6. K complexity: measured, then totaled

Phase 0 spike: `spikes/omega-header-circuit` (private workspace; results file
`RESULTS.md`), gnark v0.15.0 over the BLS12-381 scalar field, reusing the
audited proof-zk-recovery gadgets (emulated Ed25519, SHA-512, Blake2b) plus
new variable-base scalar-mult, ECVRF (draft-03 including Elligator2), Sum6
KES and RFC-8032 gadgets. Compile-only counts (structurally faithful, not yet
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

- TPraos step (epochs 208 to 364, two VRF certs): add about 1.15M, for about
  4.7M R1CS.
- Byron step: about 1.2M R1CS (Ed25519 plus Blake2b only).
- Body application (Model B): tx-id hashing is consensus-Blake2b over an
  average tx of about 1.8 KB (about 14 compressions, 0.47M R1CS per tx);
  Σ-root updates are Poseidon SMT paths (10k to 30k R1CS per update). Body
  work lands at roughly 1 to 3 times the header check per block and, over the
  122.4M historical transactions, about 2^45 to 2^46 total.
- S_epoch reward fold: per-delegator Poseidon updates over about 1.35M
  delegators come to 2^36 to 2^38 per epoch, tree-split into K=22 sub-proofs,
  or about 2^45 to 2^46 over 435 epochs. Co-dominant with headers, and
  unavoidable (stake gates VRF).
- Recursion overhead: in-circuit KZG verification per step
  ([midnight-proofs recursion](../midnight/midnight-proofs-recursion.md)),
  about 2^17 to 2^19 rows. Noise against a 12M-row step.
- Claim circuits: K = 15 to 22 (epoch-MMR path plus SMT openings plus the
  predicate).
- Groth16 landing wrap (Halo2 verifier in a Groth16 circuit): estimated 20M
  to 40M constraints, K = 25 to 26. This is the riskiest unmeasured item
  (§10), with the direct Halo2-Plutus landing as fallback.

**Totals.** Headers: 9.19M × 3.5 to 4.7M plus 4.49M × 1.2M, about 2^45.
Bodies: about 2^45 to 2^46. Rewards: about 2^45 to 2^46. The grand total is
roughly 2^46 to 2^47 constraint-work from genesis to epoch 643, compressed by
IVC/PCD into one proof whose verifier is O(1) regardless of history length:
one Groth16 verify on Plutus V3, already measured live at 32 to 39% of a
transaction budget.

**Proving economics.** Backfill is roughly 0.7 to 1.4×10¹⁴ constraints. At
10⁶ to 10⁷ constraints per second per GPU-class worker, that is 100 to 1,600
GPU-days, and the work is embarrassingly parallel (a 100-worker fleet
finishes in days to weeks, once). Steady state is about 3.5M R1CS (12M
Plonkish rows) per ~20 s block, the same class as the recovery circuit's
measured 43 s CPU prove, so one accelerated box (or a couple of CPU boxes
pipelined) holds the tip. Epoch boundaries add a burst once per 5 days.

## 7. What lands on-chain

The same shape as the [bridge](midnight-cardano-recursive-bridge.md)
Midnight-to-Cardano landing: a 336-byte commitment-Groth16 proof, one public
input `pub = H(claim envelope ‖ Ω)`, and a validator that reconstructs `pub`
itself ([zk-recovery architecture](zk-recovery-architecture.md) discipline:
never trust a prover-supplied public input), a VK pinned as an immutable
parameter, a nullifier spent-map for consumable claims, plus the Layer-4
digest-lineage datum. Budget: verify costs about 32%, the full claim-consume
branch 39 to 55% as measured on Preview, and batching amortizes to roughly 8
to 15 claims per transaction.

## 8. Applications and user experience

The design so far describes machinery. This section describes what the
machinery is for, and what it feels like to use. One structural fact drives
all of the user experience: the expensive part (the chain fold) is shared
public infrastructure, maintained once for everyone, while the part a user
runs (a claim circuit, K of 15 to 22) proves in seconds on consumer hardware.
Users never touch the fold. They fetch the current Ω and a witness path from
an indexer they do not need to trust, prove their small claim locally, and
hand over a proof that verifies in one shot.

### 8.1 Application domains

**Trustless bridge transfers (claims 1 to 9 plus finality).** The founding
use case. A user locks ADA or cNIGHT at the bridge script on Cardano; a
prover attests the lock UTxO against Ω; Midnight mints the wrapped asset.
Today's federated `c2m-bridge` asks users to trust a committee that approves
transaction hashes. With Omega the flow looks the same from the outside
(send, wait some minutes, receive), but the waiting is finality plus proving
latency rather than committee sign-off, and there is no committee to
compromise. The wallet can show plain stages: confirming on Cardano, proving,
minted.

**Private credentials from chain history (claims 26 to 37, plus 10 and 12 to
15).** This is where the catalog and Midnight's selective-disclosure model
reinforce each other. The address, the amounts, and the transaction ids sit
in the witness; only the predicate is public. So a user can prove statements
like "I delegated at least 10,000 ADA to pool P for epochs 400 through 500"
or "this wallet has earned staking rewards continuously since 2021" without
revealing which wallet they mean. Products this enables:

- airdrop and ISPO eligibility checks that do not ask anyone to paste an
  address into a form;
- loyalty tiers for long-term delegators, provable rather than asserted;
- sybil-resistant reputation ("wallet older than epoch 300 with continuous
  activity") for governance weighting or allowlists;
- DAO membership gated on historical holdings without doxxing members.

The proof is generated inside the wallet. To the user it looks like a "prove
eligibility" button followed by a QR code or a small file. To the verifier it
looks like a signature check: milliseconds, no callback to any server. The
comparison that fits best is OAuth, except the only thing that leaves the
user's device is the yes.

**Proof of reserves and supply audits (claims 10 to 15 and 17).** An exchange
or a stablecoin issuer proves "these outputs held X ADA at epoch E and were
unspent" on a schedule. Claim 11 (nonmembership and spent status) is what
makes such an attestation honest: without it, a reserves proof can
double-count outputs that were already spent. The catalog graded claim 11
hard for exactly this reason, and the Omega fold makes it a plain lookup.
Claim 17 adds provable circulating supply per asset policy. For the
institution the experience is a scheduled job that publishes one proof per
epoch. For the public it is a dashboard tile whose caption changes from
"attested by an auditor" to "verified against the chain from genesis."

**Notarization and timestamping (claims 6 and 18).** Prove that a metadata
hash was anchored in a transaction at slot S. Because the anchor is Ω rather
than a service, the proof stays checkable decades later by anyone with the
verifier and the on-chain digest lineage: no node, no explorer, no archive
service. Uses include legal evidence, publication priority, and supply-chain
records. The experience: drop a file in, get a proof file out, and anyone can
check it in a browser in milliseconds.

**Governance accountability (claims 38 to 42).** Prove a DRep's complete
voting record; prove that you voted, or abstained, without revealing your
stake; let a Midnight contract or a partner chain react automatically to an
enacted Cardano governance action, for instance releasing matching funds when
a treasury withdrawal is ratified. Cross-chain governance becomes
event-driven: the consuming contract verifies the governance fact itself
instead of polling an oracle.

**A ZK coprocessor for Plutus (any claim, consumed on-chain).** Plutus
validators run under tight budgets and cannot see history. With the landing
verifier (§7), a validator can consume any historical fact for 32 to 39% of
one transaction budget: insurance contracts settling on proven historical
protocol parameters, derivatives referencing proven epoch-boundary stake
distributions, lending protocols pricing against a wallet's proven history.
The [claim envelope](../proof-claims/claim-envelope.md) already defines the
interface a validator sees: `predicateId`, context binding, nullifier,
expiry. This is the same pattern Ethereum projects such as Axiom and
Herodotus sell as "ZK coprocessing," here with a genesis-anchored rather than
contract-storage anchor.

**Genesis-grade light clients and untrusted indexers.** A phone wallet or an
embedded device verifies one proof instead of syncing 220 GB or trusting a
hosted API. Sync takes seconds and the security model matches a full node
under Model B's assumption. The quieter consequence is what it does to
infrastructure trust: today nearly every "decentralized" Cardano application
trusts Blockfrost or Koios to tell it the truth. Against Ω, an indexer
becomes a convenience that serves data plus witness paths, and everything it
serves is checkable. A lying indexer can only fail to answer; it cannot
deceive.

**Partner-chain bootstrapping.** Any new chain gets Cardano finality and
state with one verifier contract, no federation phase, by verifying the fold
proof (or its wrap) natively. Midnight is the first consumer; nothing in the
design is Midnight-specific on the consuming side.

### 8.2 The experience, by role

**End users** mostly never learn any of this exists. Proofs hide behind
actions they already perform: bridging, claiming, checking in. Two latencies
are visible if you look. First, anchor freshness: Ω trails the chain tip by
finality plus one fold step, which is minutes; claims about anything
historical have no wait at all. Second, proving time: claim circuits at K of
15 to 22 prove in seconds on a laptop or a recent phone, and a wallet can
also delegate proving to a service when the witness is not private. In
practical terms: bridging feels like a normal cross-chain send, and
credentials feel like Face ID followed by a share sheet.

**Prover operators** are the new infrastructure role, comparable to running a
Mithril aggregator or an L2 prover. The job: run the one-time backfill (a
fleet burst, §6), then keep pace with one S_block step per 20-second block
and an S_epoch burst every 5 days. The trust story is what makes the role
easy to decentralize: a wrong fold does not verify, so operators cannot cheat
anyone. Several can run side by side, and users switch by changing a URL.

**Application developers** see an SDK and a registry. The write path is one
call, `prove(predicateId, params)`, returning an envelope and a proof; the
read path is a registry lookup plus a verify. It feels like calling an
indexer API, except the response is portable, permanent, and carries its own
verification. The anchor field in the envelope also gives developers a
low-risk adoption path: ship today against a Mithril anchor
(`anchor_type = mithril_certificate`, the Phase 1 configuration in §9), then
flip to `anchor_type = omega_accumulator` when the genesis-anchored fold is
live. No user-facing flow changes; the trust model underneath gets stronger.

**Verifiers** have the shortest description: one Groth16 check. On Cardano
that is a third of a transaction budget; on Midnight it is native; in a
browser or a phone it is milliseconds. A verifier needs the pinned VK, the
registry entry, and the on-chain digest lineage, and nothing else.

### 8.3 A worked example: private delegation credential

To make the pipeline concrete, the full path for one flagship flow, a
delegation-history credential used for an airdrop:

1. A project publishes predicate `delegated_epochs(pool, min_stake, e_from,
   e_to)` in the registry, pinned to a VK.
2. The user's wallet fetches the current Ω, the `epoch_mmr` paths for epochs
   400 through 500, and the `stake_set` SMT openings for its own stake
   credential, all from an untrusted indexer.
3. The wallet proves the claim circuit locally (seconds): the openings chain
   up to Ω, the stake amounts clear the threshold in every epoch, and the
   stake credential stays in the witness.
4. The wallet wraps the claim in an envelope: `predicateId`, `anchor_digest =
   Ω`, a context hash binding the airdrop campaign, a nullifier so the
   credential cannot be claimed twice, and an expiry.
5. The project's validator (or off-chain checker) verifies the proof against
   the registry VK and the on-chain Ω lineage, marks the nullifier spent, and
   pays out.

The user pressed one button and revealed one bit. The project learned nothing
about the wallet except that it qualifies, and it never operated or trusted
an indexer, an oracle, or a KYC vendor to establish that fact.

## 9. Roadmap

- **Phase 0, header-circuit spike: done** (§6). Real K for S_block: 22
  (R1CS) / 24 (Plonkish, untuned).
- **Phase 1, consensus fold with an interim anchor:** implement the S_block
  IVC in the midnight-zk stack with Mithril-certified stake snapshots as
  witness anchors (skipping reward derivation). Omega inherits Mithril's
  trust temporarily, but the pipeline, epoch MMR, and claim layer are real.
- **Phase 2, full state derivation:** add S_epoch (rewards, snapshots, era
  transitions) and the Byron prologue, then drop the Mithril anchor. Omega is
  now genesis-anchored. Run the backfill fleet.
- **Phase 3, claim layer:** the 42 claim circuits plus registry entries
  (`anchor_type = omega_accumulator`), per the existing
  [claim-interface-schema](../proof-claims/claim-interface-schema.md).
- **Phase 4, landing and self-checkpointing:** extend the Preview
  `groth16VerifyCommitted` validator with the digest-lineage datum; measure
  the Halo2-in-Groth16 wrap against the direct Halo2-Plutus verifier and
  pick one.

## 10. Open problems

1. **Reward-rule fidelity.** The Shelley reward calculation (spec figures 46
   to 52), pool ranking, and its era-by-era patches must be mirrored
   in-circuit exactly. This is the largest spec-to-circuit surface. The
   "one relation, four descriptions" discipline from proof-zk-recovery
   (spec / circuit / on-chain / Lean) applies.
2. **Halo2-verifier-in-Groth16 cost.** Unmeasured (estimated K = 25 to 26);
   the fallback is the direct
   [Halo2-Plutus verifier](../cardano/halo2-plutus-verifier.md).
3. **Chain selection in-circuit.** Model B needs a density/Genesis-style rule
   or an explicit statement that canonicity is pinned by Layer-4
   self-checkpointing plus the honest-majority assumption. The exact
   formulation deserves its own page.
4. **Data availability for proving.** The backfill needs all ~220 GB with
   deterministic serialization (an archive node or Mithril DB snapshots as a
   data source only; no trust is inherited from them).
5. **Era-rule divergence.** Ten protocol versions of header, body, and ledger
   deltas (TPraos vs Praos VRF format, Alonzo `invalid_transactions`, Conway
   governance). Each is a circuit variant the IVC must dispatch on `era_id`.
6. **Poseidon parameterization** over BLS12-381 Fr for the Σ structures
   (choice, security margin, lookup-friendly alternatives such as Griffin or
   Anemoi). Pick once, early; it is baked into every root.
7. **Spike hardening.** The Phase 0 circuits are compile-measured but not
   test-vectored. Wire real header vectors (Koios) through witness solving
   before trusting the gadgets themselves.

## 11. Provenance

- Measured circuit numbers: `spikes/omega-header-circuit/RESULTS.md`
  (2026-07-15, gnark v0.15.0, reusing proof-zk-recovery gadgets; private
  workspace, not in this repo).
- Deployed Groth16 verifier numbers:
  [Preview deployment](groth16-cardano-preview-deployment.md) /
  [on-chain cost](../cardano/groth16-onchain-cost.md).
- Chain statistics (block heights, era boundaries, epoch/delegator/SPO counts,
  chain size): live Koios and AdaStat fetches, 2026-07-15, mainnet epoch 643.
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
