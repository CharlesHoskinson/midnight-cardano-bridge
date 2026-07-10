---
type: Index
title: Knowledge Base Index
timestamp: '2026-07-09T13:48:21Z'
status: researched
okf_version: '1.0'
---

# Knowledge Base Index

Knowledge base for the **Midnight ↔ Cardano recursive trustless bridge** study.
Organized by domain: `cardano/`, `midnight/`, `proof-systems/`, `standards/`,
`bridges/`. See [source records](sources/index.md).

## Program control

- [Canonical 25-section bridge design](bridges/midnight-cardano-recursive-bridge.md): current readable system design and source-linked evidence boundary.
- [Council-reviewed program design](../docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md): 11 sprints, 62 work packages, fixed proof paths, gates, and completion outcomes.
- [Predicate catalog status](proof-claims/predicate-catalog-status.md): required 42 Cardano and 52 Midnight records, recovery search, admission gates, and live-test subset rules.
- [OpenSpec workflow](../openspec/config.yaml): repository context and artifact rules; see the active [Sprint 1 proposal](../openspec/changes/sprint-01-foundation/proposal.md) and the [`openspec/specs/`](../openspec/specs/) stable capability directory populated by accepted archives.

## Standards
- [CIP-0381: Plutus support for pairings over BLS12-381](standards/cip-0381.md) — BLS12-381 pairing builtins enabling on-chain Groth16 verification.
- [CIP-0133: Plutus multi-scalar multiplication over BLS12-381](standards/cip-0133.md) — MSM builtin; dominant SNARK-verification cost, MSM>129 can't fit one tx.

## Cardano
- [plutus-groth: pure-Plutus Groth16 verifier](cardano/groth16-verifier-plutus.md) — cost baseline: ~133× over mainnet budget, Hydra-only in V2.
- [ak-381: Aiken Groth16 verifier](cardano/ak-381-aiken-groth16.md) — PlutusV3 BLS builtins, standard Circom/SnarkJs proof format.
- [Ouroboros Peras (CIP-0140): faster settlement/finality](cardano/ouroboros-peras-finality.md) — ~2-min certificate-based finality; the light-client finality witness.
- [Halo2-Plutus verifier (IOG)](cardano/halo2-plutus-verifier.md) — Cardano verifies Halo2/KZG (BLS12-381) proofs directly; the Groth16-free path for Direction A.
- [Mithril — stake-threshold BLS certificates](cardano/mithril-bls-certificates.md) — certifies any deterministic Cardano-state function; the Cardano-side BLS certificate for Direction B.
- [CIP-0165 — canonical ledger-state root (SCLS)](standards/cip-0165.md) — deterministic Merkle `root_hash`@slot for UTxO membership/nonmembership; **Mithril-certifiable** → the Direction-B inclusion anchor.

## Midnight
- [Midnight — overview & dual-state ledger](midnight/overview.md) — only public state on-chain; 128-byte zk-SNARK proofs; a native Cardano bridge already exists.
- [Midnight — zero-knowledge proof model](midnight/zero-knowledge-proofs.md) — official docs say "zk-SNARKs" but do not name Halo2 or resolve setup transparency (flagged open question).
- [Compact — circuits & witnesses](midnight/compact-circuits.md) — bounded/padded circuits; public/private transcript split = Groth16 public-input/witness split.
- [Midnight proving system — curves & commitments](midnight/proving-system-curves.md) — Plonk + KZG over BLS12-381 (+JubJub); universal setup.
- [midnight-proofs — recursion internals](midnight/midnight-proofs-recursion.md) — in-circuit KZG proof verification, truncated 128-bit challenges, aPLONK committed instances (no curve cycle).
- [Midnight ZkStdLib — in-circuit gadgets](midnight/zk-stdlib-gadgets.md) — secp256k1, bls12_381, keccak256, blake2b, sha2/3 chips → verifies foreign-chain sigs/hashes in-circuit.
- [ZKIR v3 — circuit IR (PR #617)](midnight/zkir-v3.md) — Compact→ZKIR→PLONK; ~33 instrs incl. Jubjub/secp256k1 EC ops + Poseidon/SHA256/Keccak256; Ledger 9, not yet frozen.
- [Midnight transaction types](midnight/transaction-types.md) — Standard/ClaimRewards + 9 system-transaction variants; Cardano inflow via `DistributeNight(CardanoBridge)`.
- [Midnight transaction wire format](midnight/transaction-format.md) — `midnight:<tag>:` container + Field-Aligned Binary (FAB); fail-closed version tags.

## Consensus (Midnight = Substrate **AURA** + **GRANDPA**, Cardano-SPO validators)
- [Midnight consensus — AURA + GRANDPA](consensus/midnight-consensus-aura-grandpa.md) — **authoritative**: AURA (not BABE) block production, GRANDPA finality, validators from Cardano SPO delegation.
- [Midnight published chain-spec validator-set sizing](consensus/midnight-validator-set-sizing.md) — public govnet/devnet/mainnet initial BEEFY/session authority counts: 6, 7, and 10.
- [Midnight signature schemes](consensus/midnight-signature-schemes.md) — **authoritative**: GRANDPA finality signed with **Ed25519** (ECDSA for partner-chain msgs, sr25519 for AURA); Blake2-256 hashing.
- [GRANDPA — finality gadget](consensus/grandpa-finality.md) — >2/3 precommit quorum finalizes whole chains; the "commit" justification is the Direction-A attestation object.
- [BABE — block production](consensus/babe-block-production.md) — *Polkadot background only* (Midnight uses AURA); VRF slot lottery, probabilistic tip.
- [Polkadot hybrid consensus (overview)](consensus/polkadot-hybrid-consensus.md) — provable/irreversible finality as an independent service; **BEEFY** = remote finality-proof verification (the bridge precedent).
- [BEEFY — canonical protocol](consensus/beefy.md) — signed commitment = (block# ‖ MMR root ‖ validator-set-id) + 2/3+1 sigs; the exact object the Cardano verifier checks.
- [BEEFY light client (MMR, ECDSA/BLS, zkBEEFY)](consensus/beefy-light-client.md) — verification steps; **zkBEEFY** SNARK-wraps signatures to constant cost; BLS12-381 path ≈ near-native on Cardano.
- [BEEFY implementation notes](consensus/beefy-implementation.md) — rounds, mandatory blocks (validator-set handoff), session boundaries.

## Proof systems
- [Proof-system fundamentals](proof-systems/proof-systems-fundamentals.md) — statement/witness, NIZK, knowledge-soundness, succinctness (shared vocabulary).
- [PLONKish arithmetization (Halo2)](proof-systems/halo2-plonkish.md) — custom gates + lookups; deterministic universal keygen (no per-circuit SRS).
- [Commitment Groth16 (gnark)](proof-systems/commitment-groth16.md) — Pedersen commitment + PoK collapses witness wires into one public scalar.
- [Groth16 trusted-setup ceremony](proof-systems/groth16-trusted-setup-ceremony.md) — per-circuit 2-phase MPC; 1-of-N honest; avoidable via universal KZG.
- [APK proofs / committee key scheme](proof-systems/apk-proofs-committee-key.md) — accountable ≥t-of-committed-keys BLS proof; the shared light-client core for both directions.

## Cardano — on-chain Groth16 cost
- [On-chain Groth16 verification cost (measured)](cardano/groth16-onchain-cost.md) — Plutus V3 + CIP-381: single-claim ~25% of budget; ~8 claims/tx batched.

## Bridges
- [Working Groth16 verifier live on Cardano Preview](bridges/groth16-cardano-preview-deployment.md) — real proof released 5 tADA; nullifier replay-protection; feasibility proof for the Midnight→Cardano leg.
- [ZK recovery architecture (prover → validator)](bridges/zk-recovery-architecture.md) — reusable pattern: validator reconstructs its own public input, pinned VK, spent-map.
- [Cardano→Midnight system transactions (CMST)](bridges/cardano-system-transactions.md) — the current **trusted-at-launch** observation interface the trustless bridge replaces.
- **[→ Recursive trustless bridge design](bridges/midnight-cardano-recursive-bridge.md):** the canonical 25-section living design.

## Proof-claim / predicate layer (application layer atop the bridge anchor)
- [Bridge claim requirements](proof-claims/bridge-claim-requirements.md) — finality, message identity, replay, asset identity, authorization (report §31).
- [Shared claim envelope](proof-claims/claim-envelope.md) — typed fields a cross-chain claim/bridge message binds (report §8).
- [Anchor & trust models](proof-claims/anchor-trust-models.md) — 8 anchor types; the anchor must be part of the claim (report §9).
- [Claim interface schema](proof-claims/claim-interface-schema.md) — HistoricalClaim envelope, predicate registry, `bridge_message_finalized`.
- [Predicate catalog status](proof-claims/predicate-catalog-status.md): hard 94-record gate, missing sources, row contract, and conformance boundary.
