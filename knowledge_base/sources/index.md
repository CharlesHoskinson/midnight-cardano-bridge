---
type: Index
title: Source Records
timestamp: '2026-07-09T13:48:21Z'
status: researched
okf_version: '1.0'
---

# Sources

Each ingest run should add one row here per raw source consulted.

| id | resource | fetched | notes |
|----|----------|---------|-------|
| src-0001 | https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0381/README.md | 2026-07-09 | CIP-0381: BLS12-381 pairing builtins for Plutus (Groth16-on-Cardano enabler) |
| src-0002 | https://raw.githubusercontent.com/Modulo-P/plutus-groth/main/README.md | 2026-07-09 | Modulo-P plutus-groth: pure-Plutus V2 Groth16 verifier; ~133× over mainnet budget (Hydra-only) |
| src-0003 | https://raw.githubusercontent.com/Modulo-P/ak-381/main/README.md | 2026-07-09 | Modulo-P ak-381: Aiken Groth16 verifier (PlutusV3 BLS builtins), Circom/SnarkJs proof format |
| src-0004 | https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0133/README.md | 2026-07-09 | CIP-0133: BLS12-381 multi-scalar multiplication builtin; MSM>129 can't fit one tx |
| src-0005 | https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0140/README.md | 2026-07-09 | CIP-0140 Ouroboros Peras: ~2-min certificate-based finality; light-client witness = quorum cert |
| src-0006 | https://docs.midnight.network/what-is-midnight | 2026-07-09 | Midnight overview: dual public/private state; only public state on-chain; 128-byte zk-SNARK proofs; native Cardano bridge exists |
| src-0007 | https://docs.midnight.network/concepts/zero-knowledge-proofs | 2026-07-09 | Midnight ZKP concept page: zk-SNARKs, setup/prove/verify; does NOT name Halo2 or resolve setup transparency |
| src-0008 | https://docs.midnight.network/blog/compact-2 | 2026-07-09 | Compact circuits & witnesses: bounded/padded circuits, public/private transcript split, ledger value encoding |
| src-0009 | https://zcash.github.io/halo2/concepts/arithmetization.html | 2026-07-09 | PLONKish arithmetization: fixed/advice/instance columns, custom gates, lookups, deterministic (universal) keygen |
| src-0010 | https://zcash.github.io/halo2/concepts/proofs.html | 2026-07-09 | Proof-system fundamentals: statement/witness, NIZK, completeness/soundness/knowledge-soundness, ZK, succinctness |
| src-0011 | proof-zk-recovery: proto/onchain/COMMITMENT-VERIFIER-COST.md | 2026-07-09 | MEASURED on-chain Groth16 cost (Plutus V3 + CIP-381): vanilla ~1.4-1.6e9, commitment single-claim ~2.5e9 (~25%), batch ~8/tx |
| src-0012 | proof-zk-recovery: proto/onchain/redemption/SP2-PREVIEW.md | 2026-07-09 | LIVE Cardano Preview: real Groth16 proof released 5 tADA, custody branch 5.5e9 CPU, double-claim rejected via Blake2b nullifier |
| src-0013 | proof-zk-recovery: docs/commitment-groth16-protocol.md | 2026-07-09 | Commitment Groth16 (gnark): Pedersen commitment D + PoK collapses all witness wires -> ONE public scalar; 336-byte proof; 2 pairing checks |
| src-0014 | proof-zk-recovery: docs/trusted-setup-ceremony.md | 2026-07-09 | Groth16 per-circuit 2-phase MPC setup; 1-of-N honest; Veil Cash deploy-VK failure; setup asymmetry vs Halo2 universal |
| src-0015 | proof-zk-recovery: docs/ARCHITECTURE.md | 2026-07-09 | Prover->validator pattern: off-chain prover, 192-byte proof, validator reconstructs public input (never prover-supplied), pinned VK, nullifier spent-map |
| src-0016 | https://medium.com/polkadot-network/polkadot-consensus-part-3-babe-dcc2e0dd8878 | 2026-07-09 | BABE block production (Polkadot ecosystem background — **Midnight actually uses AURA**, see src-0027): VRF slot lottery; probabilistic finality; must build on GRANDPA-finalized chain |
| src-0017 | https://medium.com/polkadot-network/polkadot-consensus-part-2-grandpa-fb1963ef6c70 | 2026-07-09 | GRANDPA finality: prevote/precommit rounds, >2/3 quorum, ≤1/3 Byzantine, finalizes chains; commit msg = signature-quorum justification (the bridge attestation object) |
| src-0018 | https://wiki.polkadot.com/learn/learn-consensus/ | 2026-07-09 | Polkadot hybrid consensus (authoritative): BABE+GRANDPA split, provable/irreversible finality; BEEFY = remote finality-proof verification (direct bridge analogue) |
| src-0019 | https://raw.githubusercontent.com/paritytech/grandpa-bridge-gadget/master/docs/beefy.md | 2026-07-09 | BEEFY canonical spec: signed commitment = (block# ‖ MMR-root payload ‖ validator-set-id) + 2/3+1 sigs; purpose-built for restricted on-chain verifiers |
| src-0020 | https://docs.hyperbridge.network/protocol/consensus/beefy | 2026-07-09 | BEEFY light client: verification steps, MMR proofs, ECDSA→BLS+APK roadmap; **zkBEEFY** (SNARK-wrap ECDSA to constant cost, secp256k1 in <2s) |
| src-0021 | https://raw.githubusercontent.com/paritytech/polkadot-sdk/master/substrate/client/consensus/beefy/README.md | 2026-07-09 | BEEFY sdk impl: rounds, mandatory blocks (validator-set handoff), signed-commitment structure, sessions share GRANDPA boundaries |
| src-0022 | https://www.iog.io/news/unlocking-zero-knowledge-proofs-for-cardano-the-halo2-plutus-verifier | 2026-07-09 | IOG Halo2-Plutus verifier: auto-gen Plutus verifier for Halo2 proofs; optimal pairing (BN256→BLS12-381) enables recursive-proof verify on Cardano; ATMS in one script; universal setup |
| src-0023 | https://raw.githubusercontent.com/midnightntwrk/midnight-zk/main/README.md | 2026-07-09 | Midnight proving = Plonk + KZG over BLS12-381 (+JubJub), PSE-halo2 fork; SAME curve as Cardano CIP-0381; universal KZG setup (aggregator present; recursion construction not detailed) |
| src-0024 | https://raw.githubusercontent.com/input-output-hk/mithril/main/README.md | 2026-07-09 | Mithril STM: stake-threshold multi-signature certifying any deterministic Cardano-state fn; certificate chain (README says STM, not BLS explicitly) |
| src-0025 | https://raw.githubusercontent.com/w3f/apk-proofs/master/README.md | 2026-07-09 | apk-proofs / committee-key: SNARK proving apk = aggregate of ≥t committed BLS keys from a bitmask; the accountable-light-client core for PoS bridges (~26ms verifier) |
| src-0026 | https://github.com/midnightntwrk/midnight-docs/blob/main/docs/concepts/network-architecture/cryptography.mdx | 2026-07-09 | **AUTHORITATIVE** Midnight crypto: **GRANDPA finality = Ed25519**; ECDSA = partner-chain consensus msgs; sr25519 = AURA authorship; hash = Blake2-256 |
| src-0027 | https://github.com/midnightntwrk/midnight-docs/blob/main/docs/concepts/network-architecture/consensus.mdx | 2026-07-09 | **AUTHORITATIVE** Midnight consensus: **AURA (not BABE)** block production + GRANDPA finality; validator set from Cardano SPO stake delegation (+optional permissioned) |
| src-0028 | https://github.com/midnightntwrk/midnight-zk/blob/main/proofs/README.md | 2026-07-09 | **AUTHORITATIVE** midnight-proofs: Plonk+KZG (PSE-halo2 fork); recursion via in-circuit proof verification + truncated 128-bit challenges + aPLONK committed instances (NO curve cycle) |
| src-0029 | https://github.com/midnightntwrk/midnight-zk/blob/main/zk_stdlib/README.md | 2026-07-09 | **AUTHORITATIVE** ZkStdLib chips: secp256k1, bls12_381, keccak_256, blake2b, sha2/3, jubjub, poseidon — Midnight verifies foreign-chain sigs/hashes in-circuit |
| src-0030 | https://github.com/midnightntwrk/midnight-ledger/blob/ledger-8/spec/cardano-system-transactions.md | 2026-07-09 | **AUTHORITATIVE** CMST: at launch Midnight relies on Cardano as a **trusted layer**; Header{block,index}+Body payloads; validators verify by rebuilding (completeness) but trust producer's Cardano range |
| src-0031 | https://github.com/midnightntwrk/midnight-ledger/blob/tna/feature-documentation-zkir_v3/spec/zkir.md | 2026-07-09 | **AUTHORITATIVE (PR #617, ledger-9, ZKIR 3.0 not frozen)** Compact→ZKIR→PLONK; register-machine SSA IR; ~33 instrs incl. Jubjub+emulated secp256k1 EC ops + Poseidon/SHA256/Keccak256 |
| src-0032 | https://github.com/midnightntwrk/midnight-ledger/blob/tna/feature-documentation-zkir_v3/spec/transaction-types.md | 2026-07-09 | **AUTHORITATIVE (PR #617)** user txs (Standard=ZK+sigs+DUST, ClaimRewards) + 9 SystemTransaction variants (node-applied, consensus authority); Cardano inflow = DistributeNight(CardanoBridge) |
| src-0033 | https://github.com/midnightntwrk/midnight-ledger/blob/tna/feature-documentation-zkir_v3/spec/transaction-format.md | 2026-07-09 | **AUTHORITATIVE (PR #617)** wire format: `midnight:<tag>:` container + Field-Aligned Binary (FAB field modulus = base curve scalar field); fail-closed version tags |
| src-0034 | https://raw.githubusercontent.com/cardano-foundation/CIPs/master/CIP-0165/README.md | 2026-07-09 | CIP-0165 **SCLS** (Standard Canonical Ledger State): deterministic-CBOR, 2-level Merkle `root_hash`@slot; UTxO namespace membership/nonmembership; nodes recompute → Mithril-BLS-certifiable |
| src-0035 | C:/proofcategories/reports/cardano-midnight-proof-claim-report.md §31 | 2026-07-09 | Proof-claim report §31 bridges: inclusion≠finality, deterministic message identity, two-record replay, canonical asset id (DUST non-bridgeable), action-bound authorization |
| src-0036 | C:/proofcategories/reports/cardano-midnight-proof-claim-report.md §8 | 2026-07-09 | Proof-claim report §8 claim envelope: typed field table, 3 field classes, canonical-CBOR strict parsing; maps to relay PlutusData |
| src-0037 | C:/proofcategories/reports/cardano-midnight-proof-claim-report.md §9 | 2026-07-09 | Proof-claim report §9 anchors: anchor MUST be in the claim; 8 anchor types; Mithril = stake-threshold attestation (not full replay); CIP-0165 not-yet-historical |
| src-0038 | C:/proofcategories/reports/claim-interface-schema.md | 2026-07-09 | Claim interface schema: HistoricalClaim envelope, authoritative PredicateRegistryEntry (no caller-chosen VK), 11-step validation order, `bridge_message_finalized` predicate |
