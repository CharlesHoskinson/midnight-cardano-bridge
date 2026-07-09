---
type: Concept
title: Recursive Trustless Midnight ↔ Cardano Bridge — Design
timestamp: '2026-07-09T18:20:00Z'
description: Synthesized architecture for a recursive, trustless two-way bridge using Groth16 (Midnight→Cardano) and Plonk/Halo2 (Cardano→Midnight), grounded in the project knowledge base.
aliases:
- recursive trustless bridge
- midnight cardano bridge design
tags:
- bridge
- design
- groth16
- halo2
- plonk
- recursion
- trustless
- cardano
- midnight
status: draft
okf_version: '1.0'
---

# Recursive Trustless Midnight ↔ Cardano Bridge — Design

> **Status: draft synthesis.** Every load-bearing claim links to a verbatim-gated
> knowledge-base page. Items the corpus does *not* yet substantiate are called out
> explicitly in [§9 Open problems](#9-open-problems--next-research). This is a
> design *direction* backed by measured feasibility, not a finished protocol spec.

## 1. Thesis

A trustless bridge replaces a trusted validator set / multisig with **proofs that
each chain verifies for itself**. Security then reduces to (a) each source chain's
own consensus/finality and (b) the soundness of the proof systems used. The design
is **asymmetric by necessity**, because the two chains can cheaply verify different
things:

- **Midnight → Cardano: Groth16.** Cardano can only cheaply verify *pairing-based*
  proofs, via the BLS12-381 builtins added in [CIP-0381](../standards/cip-0381.md)
  (and the MSM builtin in [CIP-0133](../standards/cip-0133.md)). Groth16 has a
  constant-size proof and a fixed, small verifier that reduces to a handful of
  pairings — the one SNARK family that fits inside a Plutus script budget.
- **Cardano → Midnight: Plonk/Halo2.** Midnight natively proves and verifies with a
  Halo2/Plonkish stack ([PLONKish arithmetization](../proof-systems/halo2-plonkish.md)),
  which has a **universal (deterministic) setup — no per-circuit SRS** — and
  supports **recursion**. The heavier verification a Cardano light client needs is
  affordable off-chain / on the Midnight side.

The word **recursive** is load-bearing: the expensive work (verifying a chain's
header history + finality) is done where it is cheap and *recursively compressed*
into a single succinct proof that the destination chain verifies in one shot.

**Feasibility is already demonstrated, not hypothetical.** A real Groth16 verifier
runs [live on Cardano Preview](groth16-cardano-preview-deployment.md): a genuine
client proof released 5 tADA through a Plutus V3 validator using the CIP-0381
builtins. That deployment is the reference implementation this design leans on.

**The design is symmetric: each direction proves the *other* chain's BFT finality
certificate.** Midnight runs a **Substrate-based** consensus —
**[AURA](../consensus/midnight-consensus-aura-grandpa.md)** for block production and
**[GRANDPA](../consensus/grandpa-finality.md)** for finality — with a **validator set
delegated from Cardano SPOs** (it is a Cardano partner chain). So Midnight's finality
is a **GRANDPA justification** — a `>2/3` validator precommit-signature quorum.
Cardano's finality under [Peras](../cardano/ouroboros-peras-finality.md) is a **quorum
certificate** — a `>3/4` stake-weighted vote quorum. Both are BFT signature quorums
over an enumerable authority/stake set, so **each leg's circuit verifies a
signature-quorum certificate of the source chain** — the same cryptographic shape in
both directions, differing only in the proof system used to land it. (Because
Midnight's validators are Cardano SPOs, the two chains' validator sets are not just
similar — they *overlap*.)

> **Correction / provenance note.** An earlier draft said Midnight uses *BABE* for
> block production; the authoritative
> [Midnight consensus docs](../consensus/midnight-consensus-aura-grandpa.md) state it
> is **AURA** (a PoA round-robin), not BABE. Only the block-production layer changes —
> the bridge attests **GRANDPA finality**, which is unchanged. The
> [Polkadot BABE page](../consensus/babe-block-production.md) is retained as
> *ecosystem background*, not as a claim about Midnight.

### 1a. The unifying insight — one BLS12-381 substrate on both sides
Per project direction, **BLS can be used on both sides**, and the corpus shows the
two chains are *already* on the same pairing curve — which collapses most of the
cross-curve friction that makes bridges expensive:

- **Midnight** proves with **Plonk + KZG commitments over BLS12-381** (plus JubJub
  in-circuit) — its `midnight-proofs`/`midnight-zk` stack is a PSE-halo2 fork
  ([Midnight proving system](../midnight/proving-system-curves.md)). Crucially, KZG
  uses a **universal, updatable SRS**, not Groth16's per-circuit ceremony.
- **Cardano** has **BLS12-381 pairings ([CIP-0381](../standards/cip-0381.md)) + MSM
  ([CIP-0133](../standards/cip-0133.md))** as Plutus builtins, and IOG has built a
  **[Halo2-Plutus verifier](../cardano/halo2-plutus-verifier.md)** that verifies
  Halo2/KZG proofs on-chain (porting the optimal pairing check to BLS12-381 to make
  *recursive* proof verification feasible).
- **Both finality certificates are BLS aggregate signatures:** Midnight's
  **[BLS-BEEFY](../consensus/beefy.md)** signed commitment and Cardano's
  **[Mithril / ATMS](../cardano/mithril-bls-certificates.md)** stake-threshold
  multi-signature. A BLS aggregate verifies in a **single pairing check**.
- **The ≥2/3 threshold is proven the same way both directions** — the w3f
  **[committee-key / apk-proofs](../proof-systems/apk-proofs-committee-key.md)**
  scheme, purpose-built as "the cryptographic core for accountable light clients
  bridging PoS blockchains."

**Consequence.** Each chain can verify the *other's* finality certificate and state
proof with **native BLS12-381 pairing operations** — Cardano via CIP-0381, Midnight
in its own BLS12-381 circuits — rather than emulating a foreign curve. The recursive
trustless bridge becomes a **shared-substrate problem**, and Groth16's per-circuit
trusted setup is **optional** (replaceable by the universal KZG setup both sides
already rely on — potentially even a *single shared* Powers-of-Tau). Groth16 remains
useful purely as the *smallest/cheapest* on-chain landing (measured in §2); it is no
longer a trust requirement.

### 1b. From trusted-at-launch to trustless (what this bridge replaces)
The corpus makes the starting point explicit: **"at launch, Midnight will rely on
Cardano as a trusted layer"**
([CMST spec](cardano-system-transactions.md)). Concretely, today:

- **Cardano → Midnight is trusted observation.** Midnight block producers *observe*
  Cardano and persist events as **Cardano-based Midnight System Transactions (CMST)** —
  a `Header{ last Cardano block, next-tx index }` + type-tagged `Body` payloads;
  validators re-derive the body to guarantee *completeness*, but still **trust the
  producer's chosen Cardano range**. Bridge inflows arrive as the consensus-authorized
  **`DistributeNight(CardanoBridge)`** system transaction (one of 9
  [`SystemTransaction` variants](../midnight/transaction-types.md), which are
  *unproven — their authority is the consensus layer*), later withdrawn by a user's
  signature-only `ClaimRewards`. The current cNIGHT bridge pallet
  (`pallets/c2m-bridge`) approves mainchain tx hashes in batches — **federated, not
  trustless.**
- **Midnight → Cardano is moving toward trustless first** — the temporary
  `midnight-beefy-relay` already emits a verifiable finality certificate (§3).

**This document specifies the endpoint: replace the trusted observation with
proofs in both directions.** The trustless Cardano→Midnight leg proves *the same CMST
body* is the complete, correct set of events for a *Cardano-finalized* range (via a
Peras/Mithril certificate), instead of trusting the producer; the trustless
Midnight→Cardano leg proves a GRANDPA/BEEFY-finalized Midnight state. Framing the
work as an *evolution of the existing partner-chain plumbing* — not a greenfield
build — is what makes it tractable.

### 1c. Where bridge verifier circuits live: ZKIR v3
On the Midnight side, a verifier circuit (e.g. "this Cardano Mithril/Peras certificate
is valid") is authored through Midnight's real toolchain:
**Compact → [ZKIR v3](../midnight/zkir-v3.md) (JSON/binary) → PLONK (synthesised via
`midnight-zk` [ZkStdLib](../midnight/zk-stdlib-gadgets.md)) → proof**. ZKIR v3 exposes
first-class **Jubjub and emulated secp256k1** elliptic-curve ops (`EcMul`,
`EcMulGenerator`) and **Poseidon / SHA-256 / Keccak-256** hashes — precisely the
primitives needed to verify a foreign chain's signatures and header hashes in-circuit.
(ZKIR 3.0 ships in Ledger 9 but is **not yet frozen** — the released `midnight-zkir-v3`
crate is authoritative, so circuit-level specifics must be re-pinned against it.)

## 2. The cost result that makes it possible

The single most important engineering fact: **on-chain Groth16 verification is
affordable on Cardano — but only on Plutus V3 with the native CIP-0381 builtins.**

| Verifier | Measured CPU | ~% of 10¹⁰ per-tx budget | Source |
|---|---:|---:|---|
| Pure-Plutus **V2** (hand-rolled BLS) full verify | ~1.33×10¹² | ~13,300% (Hydra-only) | [plutus-groth](../cardano/groth16-verifier-plutus.md) |
| One pairing (millerLoop+finalVerify), **V3 builtin** | ~0.81×10⁹ | ~8% | [on-chain cost](../cardano/groth16-onchain-cost.md) |
| Vanilla Groth16 verify, **V3** | 1.36–1.61×10⁹ | ~14–16% | [on-chain cost](../cardano/groth16-onchain-cost.md) |
| Commitment-Groth16, single claim, **V3** | ~2.4–2.8×10⁹ | ~25% | [on-chain cost](../cardano/groth16-onchain-cost.md) |
| Live Preview custody branch (real proof) | 5.5×10⁹ | ~55% (declared 6.5×10⁹) | [preview](groth16-cardano-preview-deployment.md) |

The **V2→V3 flip** (from ~133× over budget to ~a quarter of the budget) is the
whole ballgame. Two consequences constrain the design:

1. **Keep public inputs tiny.** On-chain verifier cost is dominated by a
   multi-scalar multiplication whose size scales with the number of **public
   inputs**; a naive MSM over just **>129 points cannot fit in one transaction**
   ([CIP-0133](../standards/cip-0133.md)). The fix is the **commitment Groth16**
   variant ([commitment-groth16](../proof-systems/commitment-groth16.md)): gnark
   folds *all* heavy witness wires into a **single Pedersen commitment `D`**, so the
   validator sees **one public scalar** and a constant-size MSM regardless of
   circuit size — at a fixed cost of one extra pairing check.
2. **Memory and tx size bind before CPU.** The batch ceiling is ~8 commitment
   claims/tx (CPU), but [the cost analysis](../cardano/groth16-onchain-cost.md)
   flags that the **16.5M memory unit** and **16,384-byte tx-size** limits likely
   bind first — the real ceiling must be re-measured on preprod.

## 3. Direction A — Midnight → Cardano (Groth16)

### What is proven
That a **Midnight public-state event** — e.g. a bridged asset locked/burned on
Midnight, expressed as a commitment in Midnight's public ledger state — occurred
and is **final** on Midnight. Only Midnight's *public* state is on-chain and
therefore attestable; private state never leaves the client
([Midnight overview](../midnight/overview.md)). A Compact contract's public
transcript is exactly the public-input surface a cross-chain statement can bind to
([Compact circuits](../midnight/compact-circuits.md)).

### Proof & on-chain verifier
- **Proof:** a commitment-Groth16 proof over BLS12-381 (constant ~336 bytes), with
  the Midnight-event commitment as the single public scalar
  ([commitment-groth16](../proof-systems/commitment-groth16.md)).
- **Verifier:** a Plutus V3 validator following the proven
  [prover→validator pattern](zk-recovery-architecture.md): an untrusted relayer
  submits the proof, but **the validator reconstructs its own public input** from
  its datum/outputs — it never trusts a prover-supplied public input — and verifies
  against a **VK pinned as an immutable script parameter** (a redeemer-supplied VK
  is rejected). This is the single load-bearing rule that makes the proof binding.
- **Replay protection:** a Blake2b **nullifier** + spent-map (one-settlement-per-event),
  exactly as the [Preview deployment](groth16-cardano-preview-deployment.md) closes
  double-claims on-chain.

### Proving Midnight finality — a GRANDPA justification
Midnight's Substrate consensus is
**[AURA](../consensus/midnight-consensus-aura-grandpa.md) (block production) +
[GRANDPA](../consensus/grandpa-finality.md) (finality)**. This turns the
previously-open "hard part" into a concrete, tractable attestation target — and note
it is **GRANDPA finality**, independent of the block-production algorithm, that the
bridge proves.

> **⚠️ Current mechanism is temporary — design mechanism-agnostically.** Today
> `midnight-node` ships a **`midnight-beefy-relay`** (BEEFY over ECDSA) that reads a
> BEEFY signed commitment + an `AuthoritiesProof` + MMR and encodes them as **Cardano
> `PlutusData`** (via the `pallas` library) for on-chain verification — a real, working
> reference for Direction A. **But BEEFY here is explicitly a stopgap: a future Midnight
> release pivots to a BABE-based design.** So this document treats the finality object
> abstractly as **"Midnight's finality certificate"** — currently a BEEFY-ECDSA signed
> commitment, later whatever the BABE-design release emits. The bridge's *structure*
> (relay submits an untrusted certificate → a Cardano validator checks a signature
> quorum + set-membership + MMR/state inclusion → settle) is invariant across that
> pivot; only the certificate's signature scheme and payload layout change.

The circuit must attest not that a Midnight event merely *happened* (AURA's tip is
only probabilistically final and can reorg before finalization) but that it is in the
**GRANDPA-finalized prefix**, which is *deterministic and irreversible*. GRANDPA
gives us exactly the right object: a **finality justification** — the round's
**commit message**, i.e. a set of **precommit signatures from >2/3 of the current
validator (authority) set** on the finalized block (or a descendant). Because
GRANDPA finalizes *whole chains*, one justification settles the block **and its
entire prefix**, and the authority set is *bounded and enumerable*.

**Direction-A statement the Groth16 circuit proves** (public output = a commitment
to event `E`):
1. **Authority-set binding:** the precommit signatures are from the keys in a
   committed GRANDPA authority set `A_r` for round/era `r`.
2. **Quorum:** `> 2/3` of `A_r` validly signed the target block `B` (GRANDPA is safe
   for `≤ 1/3` Byzantine — a conflicting finalization needs `≥ 1/3` equivocation).
3. **Inclusion:** event `E` is included in `B`'s (public) state via a Merkle path.

The Cardano validator then verifies the single wrapped Groth16 proof cheaply (§2),
reconstructs `E`'s commitment itself, and flips the nullifier. **The dominant
in-circuit cost is the signature-set verification**, which is why a
**BLS-aggregatable** GRANDPA signature representation (see BEEFY below) is
strongly preferred over per-signature Ed25519.

> **Polkadot already ships this exact primitive: [BEEFY](../consensus/beefy.md)**
> ("Bridge Efficiency Enabling Finality Yielder") is a companion protocol to
> GRANDPA whose *sole purpose* is to let a **remote chain efficiently verify relay-chain
> finality proofs** — the precise job of the Midnight→Cardano on-chain verifier, and
> it is explicitly "optimized for restricted environments like Ethereum Smart
> Contracts or On-Chain State Transition Functions." **Do not re-derive Direction A —
> model it on BEEFY.**

### The concrete verifier: a BEEFY signed commitment
BEEFY reduces the whole remote-verifier input to one small object — a
**[signed commitment](../consensus/beefy-implementation.md)**:

```
Commitment      = ( block_number ‖ payload ‖ validator_set_id )
payload         = MMR root hash          (a crypto accumulator over all past headers)
Signed Commitment = Commitment + a  2/3 + 1  supermajority of validator signatures
```

Verification is then **no headers, no ancestry data**:
1. Check the `2/3 + 1` signatures come from the committed validator set
   (`keyset_commitment`).
2. Learn the finalized `block_number`/state from the signed **MMR root**; because a
   [Merkle Mountain Range](../consensus/beefy-light-client.md) accumulates every
   header, "with only the MMR root the ancestry of any header can be cheaply
   verified" — the Midnight **event `E` is proven by a cheap MMR inclusion proof
   against the already-signed root**.
3. Advance the tracked validator set only on a **mandatory block** (each session's
   first block always carries a BEEFY justification), whose commitment is signed by
   the **outgoing** set — this *is* the [§5](#5-recursion-strategy) recursion for
   authority rotation, and BEEFY sessions share GRANDPA's boundaries, so there is no
   separate set to track.

### Signature scheme decides the Cardano verifier (the key cost fork)
**Confirmed from Midnight's docs:** Midnight's **GRANDPA finality messages are signed
with [Ed25519](../consensus/midnight-signature-schemes.md)** (`2N/3+1` sigs, not
aggregatable; partner-chain consensus messages use ECDSA, AURA authorship uses
sr25519). Ed25519 is neither native to Cardano (CIP-0381 is BLS12-381) nor
aggregatable. The **temporary BEEFY relay** side-steps this by having BEEFY re-sign
GRANDPA-finalized blocks with **ECDSA/secp256k1** (standard `sp-consensus-beefy`),
which Cardano *can* verify. Three landing modes, in increasing scalability:

- **(Mode 0 — CURRENT, implemented):** the `midnight-beefy-relay` submits a
  BEEFY-**ECDSA** signed commitment + `AuthoritiesProof` + MMR proof as `PlutusData`;
  a Plutus validator verifies **each ECDSA signature natively** (Cardano has a
  `verifyEcdsaSecp256k1Signature` builtin), checks signer set-membership, and checks
  the MMR/state inclusion. Works today; **cost grows linearly with the validator
  count**, so it is fine for a modest committee but does not scale.
- **(Mode 1 — BLS "on both sides", the target):** switch BEEFY to **BLS12-381**
  aggregate signatures (Midnight's stack already has a
  [`bls12_381` in-circuit chip](../midnight/zk-stdlib-gadgets.md) + BLS12-381 curve
  support, so this is in-house). Cardano then verifies the *aggregated* quorum in a
  **single pairing check via [CIP-0381](../standards/cip-0381.md)** + an
  [apk-proof](../proof-systems/apk-proofs-committee-key.md) for the ≥2/3 threshold +
  MMR inclusion — **O(1) in validator count.** This is what "BLS on both sides"
  buys and is the recommended target (it also matches Cardano's own
  [Mithril/ATMS](../cardano/mithril-bls-certificates.md) BLS machinery on the reverse
  leg).
- **(Mode 2 — zk-wrap, "zkBEEFY", for any scheme/size):** wrap the signature checks
  in a SNARK ([zkBEEFY](../consensus/beefy-light-client.md)) so on-chain cost is
  **constant regardless of scheme or set size** (barretenberg proves secp256k1
  verification in <2 s; the `proof-zk-recovery` repo ships an Ed25519 gadget too).
  This is the fallback if a future (e.g. BABE-design) finality certificate uses a
  signature scheme Cardano can't verify natively, or the set is too large for Mode 0.

The bridge should implement against an **abstract "finality certificate" interface**
so the same Cardano validator skeleton (verify quorum → verify set-membership → verify
MMR/state inclusion → settle) serves Mode 0 today and Mode 1 after the BLS switch /
BABE pivot, with only the signature-verification primitive swapped.

### The concrete Mode-0 artifact (from `midnight-node/relay`)
The `midnight-beefy-relay` README specifies the exact object the Cardano validator
receives — a **`RelayChainProof`** serialized to `PlutusData` (a full CBOR example is
in the repo):

```
RelayChainProof {
  signed_commitment: SignedCommitment {
    commitment: { payloads:[Payload{id,data}], block_number, validator_set_id },
    votes: [ Vote { signature (ECDSA), authority_index, public_key } ]
  },
  proof: AuthoritiesProof { root (=keyset_commitment), total_leaves, proof:[[…]] }
}
```

The commitment **`Payload`** carries up to five keyed items: the **MMR root** plus the
**current** and **next** BEEFY **stakes** (`[(BeefyId, Stake)]`) and **authority sets**
(each a merkle `keyset_commitment`) — so validator-set + stake handoff travels in the
signed payload. The **`AuthoritiesProof`** is a **Merkle multiproof** (against
`keyset_commitment`) that the signing keys are members of the current authority set.

**The Cardano-side on-chain validator that consumes this** must: parse the `PlutusData`
→ verify each ECDSA `Vote` (`verifyEcdsaSecp256k1Signature`) → verify the Merkle
`AuthoritiesProof` → check the signing **stake meets the ≥2/3 threshold** → read the
**MMR root** from the payload for event/state inclusion. **That validator is not in the
`midnight-node` repo** (the repo's `redemption.ak` is an unrelated STAR-vesting
skeleton) — locating or specifying it is the top open item (§A of the project-root
`EXAMINATION-CHECKLIST.md`).

### Trust caveat
This direction's soundness depends on a **per-circuit Groth16 trusted setup**
([ceremony](../proof-systems/groth16-trusted-setup-ceremony.md)): a two-phase MPC
(reusable Powers-of-Tau phase 1 + circuit-specific phase 2), sound under a
**1-of-N honest-participant** assumption. The historical failure mode is *not*
participant count but **faithful deployment** — the Veil Cash drain came from a
deployed verifier whose VK didn't match the (honest) ceremony output. Mitigation:
a credible, diverse, independently-verified ceremony **plus an on-chain VK-equality
check** against the sealed transcript.

## 4. Direction B — Cardano → Midnight (Plonk/Halo2)

### What is proven
That a **Cardano event** (e.g. a UTxO locked at the bridge script) occurred and is
**final** on Cardano, verified by a Cardano **light client running inside a
Halo2/Plonk circuit** on the Midnight side.

### Cardano finality to attest
With [Ouroboros Peras (CIP-0140)](../cardano/ouroboros-peras-finality.md), finality
becomes a single verifiable object: a **per-round certificate** aggregating a
quorum (τ = 675 of a 900-member committee, >3n/4) of stake-weighted votes. A light
client's verification surface is: a valid Praos header chain to the block **plus** a
well-formed certificate whose votes each carry a **VRF committee-membership proof and
a KES signature**, bound to the epoch stake distribution. Caveats that shape the
circuit:
- **Optimistic, with fallback:** a ≥25% adversary can withhold votes and force a
  Praos-like cool-down (no certificate); the client must detect "no boost" and fall
  back to Praos depth-based confirmation.
- **Data availability:** most certificates live *off-chain* (diffused as votes), so
  they must be supplied to the circuit as **witness data**.

**Two certificate options for the Cardano side (both BLS-friendly):**
- **(B-i) Peras vote certificate** — the *in-protocol* finality object (§Peras).
  Its votes carry VRF+KES signatures today; verifying those in-circuit is the heavier
  path unless a BLS vote representation is available.
- **(B-ii) [Mithril / ATMS](../cardano/mithril-bls-certificates.md)** — a
  **stake-threshold multi-signature** that certifies *any deterministically computable
  function of Cardano state* (already shipping in SPO infrastructure). This is the
  natural BLS analogue of Midnight's BLS-BEEFY: Midnight verifies it as a **single
  aggregate pairing check** plus a committee-key/apk proof for the stake threshold —
  cheap because Midnight is BLS12-381-native. (Our current source names it "STM"
  without stating the curve; confirm the BLS12-381 basis from the `mithril-stm`
  spec — see [§9](#9-open-problems--next-research).) **Recommendation: prefer the
  Mithril/ATMS certificate for Direction B** — it is purpose-built to certify state
  for external verifiers and keeps both directions on identical BLS machinery.

**The inclusion anchor: a Mithril-certified SCLS root ([CIP-0165](../standards/cip-0165.md)).**
What the Cardano certificate should certify is a **canonical ledger-state root**. CIP-0165
defines the **Standard Canonical Ledger State (SCLS)**: a deterministic-CBOR snapshot with a
**two-level Merkle `root_hash` pinned to a slot**, whose UTxO namespace uses
`H(0x01 ‖ ns ‖ key ‖ value)` (Blake2b-224) leaves in canonical key order — giving both
**membership** and (via ordered neighbours) **nonmembership** proofs. Because *every honest
node recomputes the same `root_hash`*, the root is exactly what a stake-based
**Mithril/ATMS BLS certificate signs**. So the clean Direction-B pipeline is: **Midnight
verifies a Mithril BLS cert over the SCLS `root_hash`@slot (one pairing check), then verifies
a Merkle path proving the Cardano lock UTxO is in that SCLS root** — no header replay, no
trusted indexer. Caveat (§9): SCLS is not yet a *historical* root for all prior epochs, so
early deployments may anchor on recent state only.

### Proof & verification
- Midnight's stack produces **succinct proofs (~128 bytes, verified in ms)**
  ([Midnight overview](../midnight/overview.md)) with **no per-circuit trusted
  setup** ([PLONKish](../proof-systems/halo2-plonkish.md)) — so this direction is
  *structurally* the more trustless of the two.
- PLONKish **custom gates + lookup arguments** let the expensive light-client
  primitives (Ed25519/VRF/KES signature checks, hashes, range checks) be expressed
  far more compactly than a flat Groth16 R1CS would — the reason a full Cardano
  light client is tractable here.

## 5. Recursion strategy (the "recursive" in the name)

Re-verifying Cardano's entire header history on every transfer is infeasible.
Recursion/accumulation compresses it:

- **Cardano→Midnight (native):** Midnight's stack does recursion by **in-circuit KZG
  proof verification** — verifying a Plonk/KZG proof inside another circuit — made
  practical by **truncated (128-bit) Fiat–Shamir challenges** (halving in-circuit
  scalar-mul cost) and **aPLONK committed instances** (shrinking the public-input
  surface), with an `aggregator`/IVC toolkit
  ([midnight-proofs recursion](../midnight/midnight-proofs-recursion.md)) — **no curve
  cycle is involved.** So a proof that "headers 0..N are valid and block N carries a
  finality certificate" is folded into a succinct proof; each step recursively verifies
  the previous proof + a small header increment (a Mina-style succinct light client),
  and only the latest recursive proof is verified on Midnight.
- **Authority/stake-set rotation is the recursion's real job.** Neither validator
  set is static: GRANDPA rotates its **authority set** across eras and Cardano
  rotates its **stake distribution** across epochs. The recursive proof must carry
  the current set forward — each step verifies that a set transition was itself
  signed/finalized by the *outgoing* set (GRANDPA authority-set-change signatures;
  Cardano epoch stake snapshots). This is what lets the destination-chain verifier
  trust a `>2/3` quorum without ever holding the full validator history — and it is
  exactly what BEEFY's MMR accumulator does on the Polkadot side.
- **Midnight→Cardano (wrapping):** Groth16 is **not** cheaply recursive (per-circuit,
  pairing-based). The intended trick is a **proof-wrapping** step: do the heavy
  recursive/aggregate verification with Halo2 *off-chain*, then produce **one final
  Groth16 proof that attests "a valid Halo2 proof of the Midnight event+finality
  exists,"** cheap for the Cardano validator to check. Heavy verification happens
  where it is cheap (off-chain/Halo2); only the constant-cost Groth16 landing
  touches Cardano. **Feasibility/cost of the Halo2-verifier-in-Groth16 circuit is an
  open item** ([§9](#9-open-problems--next-research)).

**Design rule of thumb:** *put recursion on the Halo2 side; give Cardano a single
constant-cost Groth16 proof.*

## 6. Trust model summary

| Assumption | A: Midnight→Cardano | B: Cardano→Midnight |
|---|---|---|
| Source-chain finality | **GRANDPA justification, >2/3 quorum, ≤1/3 Byzantine** (deterministic) | Peras quorum cert, >3/4 stake (+ Praos fallback) |
| Proof soundness | Groth16 (knowledge-soundness) | Halo2/Plonk |
| Trusted setup | **Universal KZG** (both sides on BLS12-381) — Groth16 per-circuit MPC only if the Groth16 landing is chosen | **None / universal (KZG)** |
| Relayer | Untrusted (validator reconstructs public input) | Untrusted (proof self-verifies) |
| Replay | Nullifier spent-map | Nullifier / state-commitment on Midnight |

Both finality assumptions are **BFT honest-majority thresholds over a bounded
validator/stake set** — no extra trusted party is introduced by the bridge beyond
each chain's own consensus. Because both chains sit on **BLS12-381 with a universal,
updatable KZG setup** ([§1a](#1a-the-unifying-insight--one-bls12-381-substrate-on-both-sides)),
the previously-"concentrated" Groth16 per-circuit trusted-setup risk is **optional**:
it applies *only if* you choose the Groth16 landing for its smaller proof, and can be
avoided entirely by verifying Midnight's Halo2/KZG proof directly on Cardano
([Halo2-Plutus verifier](../cardano/halo2-plutus-verifier.md)). Net: the bridge's
residual trust is **BLS/pairing soundness + each chain's honest-stake majority**.

The bridge's **concentrated trust risk is the Groth16 trusted setup on Direction A**;
everything else reduces to consensus + proof soundness. Both directions treat the
relayer as fully untrusted.

## 7. On-chain footprint (Cardano side)

- Proof ~192–336 bytes; validator ~300–600 bytes serialized.
- Single settlement ~14–28% of CPU budget; batching amortizes the shared pairing to
  ~8–15 claims/tx, a "40–50% throughput haircut, not a wall."
- Re-measure the binding ceiling (memory / tx-size) on preprod with all soundness
  controls on.

## 8. Component map

```
Midnight → Cardano (A)                    Cardano → Midnight (B)
─────────────────────                     ─────────────────────
Midnight event + GRANDPA justification    Cardano lock UTxO + Peras certificate
  (>2/3 precommit sig quorum)               (>3/4 stake-weighted vote quorum)
   │ (relayer supplies as witness)           │ (relayer supplies headers+cert as witness)
   ▼                                          ▼
Halo2 recursion → wrap to Groth16         Halo2 recursive light-client prover
   │  ~336B proof, 1 public scalar           │  folds headers+finality → succinct proof
   ▼                                          ▼
Plutus V3 validator (CIP-0381/0133)       Midnight verifies Halo2 proof (native, ms)
   • reconstructs own public input           • no trusted setup
   • pinned VK, pairing checks               • updates Midnight public state
   • nullifier spent-map → release           • mints/credits bridged asset

  (both circuits verify a source-chain BFT signature-quorum certificate;
   recursion carries the authority/stake set forward across eras/epochs)
```

## 8a. The application layer: typed proof-claims on the anchor
The bridge substrate above **manufactures a trustworthy cross-chain anchor** (a finality
certificate + state root). Applications don't consume that anchor raw — they consume **typed
claims** against it. That layer is specified separately (see the `proof-claims/` pages):
- **[Claim envelope](../proof-claims/claim-envelope.md)** — every claim binds
  `predicate_id, network, anchor_type/digest, finality_rule, verifier_id,
  public_input/output_hash, context_hash, replay_scope, nullifier, expiry`; the bridge's
  finality proof *is* the `anchor` + `finality_rule` these bind to.
- **[Bridge claim requirements](../proof-claims/bridge-claim-requirements.md)** — a bridge
  message must bind a **deterministic message-identity hash** (source+destination tuples),
  keep **two replay records** (ZK nullifier vs consumed-message set), use **canonical asset
  identity** (DUST is *non-bridgeable*), and bind **authorization to the specific action**.
- **[Anchor & trust models](../proof-claims/anchor-trust-models.md)** — our finality objects
  map onto its anchor taxonomy (Mithril cert / SCLS root / settled prefix …); *the anchor
  MUST be part of the claim*.
- **[Claim interface schema](../proof-claims/claim-interface-schema.md)** — an authoritative
  verifier **registry** (no caller-chosen VKs; active/frozen/deprecated status) and a
  first-class **`bridge_message_finalized`** predicate. This is how the Cardano-side bridge
  verifier/VK should be governed and versioned.

Design rule: the bridge relayer's `RelayChainProof` PlutusData (§3) should be reconciled with
this claim envelope so the on-chain validator checks a *typed* claim, not raw bytes.

## 9. Open problems / next research

Honest gaps in the current corpus (drives the next ingestion batches, incl. the
PDF pipeline for academic papers):

1. ~~Midnight consensus & finality~~ **RESOLVED (authoritative docs):** Midnight uses
   Substrate **[AURA](../consensus/midnight-consensus-aura-grandpa.md)** (block
   production) + **[GRANDPA](../consensus/grandpa-finality.md)** (finality), validators
   delegated from Cardano SPOs; GRANDPA finality signed with **Ed25519**
   ([signature schemes](../consensus/midnight-signature-schemes.md)). Direction A
   attests a GRANDPA finality justification (§3).
2. ~~BEEFY deep-dive~~ **RESOLVED (this batch):** BEEFY signed-commitment + MMR is
   the Direction-A template (§3); authority rotation is handled by BEEFY **mandatory
   blocks**. Remaining sub-items below.
3. **Midnight's specific BEEFY signature scheme (Mode 1 vs Mode 2 — the biggest open
   decision).** BEEFY *today* is ECDSA/secp256k1; the roadmap is BLS+APK. Which does
   *Midnight* run? BLS12-381 → near-native CIP-0381 verification (cheapest); ECDSA/
   Ed25519 → zkBEEFY Groth16 wrapper. *Confirm from a Midnight/partner-chains primary
   source, and push for the BLS variant.*
4. **zkBEEFY circuit cost on Cardano** — the ecosystem shows secp256k1 zkBEEFY is
   feasible (<2 s prove); quantify the Groth16-wrapped verifier's *on-chain* Plutus
   cost and proof size for the Midnight validator set size, reusing the
   `proof-zk-recovery` Ed25519/SHA-512 gadgets.
5. ~~Midnight's exact proving system~~ **RESOLVED:** Midnight is **Plonk + KZG over
   BLS12-381** (+JubJub), a PSE-halo2 fork with a **universal** setup
   ([proving system](../midnight/proving-system-curves.md)). *Still open:* whether
   Midnight's GRANDPA/BEEFY *signatures* are configured as BLS (vs Ed25519/ECDSA) —
   the Mode-1-vs-2 lever — and the exact recursion/proof-aggregation construction
   (the `midnight-zk` README names an `aggregator` component but gives no details).
6. **Direction-A landing choice** — measure and compare the two options on Cardano:
   (a) verify Midnight's Halo2/KZG proof directly ([Halo2-Plutus verifier](../cardano/halo2-plutus-verifier.md),
   universal setup, larger proof) vs (b) wrap to Groth16 (smallest proof, per-circuit
   setup). No measured on-chain ex-units exist yet for (a).
7. **Cardano finality certificate for Direction B** — confirm the **Mithril/ATMS**
   BLS12-381 basis (`mithril-stm` spec) and whether Peras votes can be represented as
   BLS; pick B-i vs B-ii.
8. **In-circuit cost of the committee-key/apk proof** at Midnight's / Cardano's real
   validator-set sizes (recovery repo has Ed25519/SHA-512 gadgets to reuse).
9. **Precedent designs** — zkBridge, Mina/Plumo succinct light clients, IBC
   trust-minimized clients (PDF-pipeline batch).
10. **Data availability** for BEEFY/Mithril certificates (off-chain; supplied as
    circuit witness) and **EUTxO concurrency/batching** UX for Cardano-side settlement.

## 10. Provenance

Synthesized from 38 verbatim-gated sources (534 claims) in this knowledge base; see
the [source records](../sources/index.md) and the [index](../index.md). Cardano-side
cost and the working-deployment claims derive from the `proof-zk-recovery` project
(src-0011…src-0015), the strongest evidence in the corpus because it is *measured
and deployed*, not estimated; the GRANDPA finality model from the Polkadot consensus
sources (src-0016…src-0018, used as ecosystem background) and, authoritatively, from
**Midnight's own docs and `midnight-zk` repo** (src-0026…src-0029: AURA+GRANDPA
consensus, Ed25519/ECDSA/sr25519 signature roles, midnight-proofs recursion, ZkStdLib
gadgets); the Direction-A verifier blueprint (BEEFY signed commitments, MMR,
mandatory-block handoff, zkBEEFY) from the BEEFY sources (src-0019…src-0021); the
**unified BLS12-381 substrate** (Halo2-Plutus verifier, Midnight KZG/BLS12-381,
Mithril ATMS, apk-proofs) from src-0022…src-0025; and the **ledger / state model**
(CMST trusted-at-launch interface, ZKIR v3 circuit IR, transaction types & wire
format) from `midnight-ledger` + PR #617 (src-0030…src-0033).
