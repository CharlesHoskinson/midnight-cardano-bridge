# Examination Checklist — Midnight ↔ Cardano Recursive Trustless Bridge

Everything we still need to examine to take the design from **draft** to **buildable spec**.
Complements `RESEARCH-PLAN.md` (source corpus) and the design doc's §9 (open problems).

**Status legend:** `[ ]` not started · `[~]` partially examined · `[x]` examined/answered.
Each item: *what to examine — where (repo/file/source) — the question it answers.*

Cloned repos live in `_external/`: `midnight-zk`, `midnight-docs`, `midnight-ledger`
(+ PR-617 branch `pr-617`), `midnight-node`, `proof-zk-recovery`.

---

## A. Direction A — Midnight → Cardano (finality proof landed on Cardano)

- [x] **BEEFY relay → Cardano PlutusData layout** — `relay/README.md` gives the full `RelayChainProof` + a concrete CBOR `PlutusData` example. Structure known (see design doc §3 "concrete Mode-0 artifact"). *(remaining: exact `ToPlutusData`/tag-121 field encodings in `cardano_encoding.rs` for a byte-exact re-impl)*
- [x] **AuthoritiesProof structure** — `relay/README.md` + `authorities.rs`: a **Merkle multiproof** (`root=keyset_commitment, total_leaves, proof[[…]]`) that the signing ECDSA keys are members of the authority set. Stake ≥2/3 checked from the payload stakes.
- [x] **BEEFY justification + stake/authority payloads** — Payload (5 keyed items): **MMR root**, current stakes `[(BeefyId,Stake)]`, current authority set (`keyset_commitment`), next stakes, next authority set. Handoff travels in the signed payload.
- [~] **Relayer flow & liveness** — `relay/README.md` covers running it (archive node, BEEFY keys, `--enable-offchain-indexing`); build/submit via `pallas`. *(remaining: cadence, retry, incentives, permissionlessness — read `relayer.rs`)*
- [~] **⭐ The Cardano-side on-chain verifier** — investigated: **NOT in `midnight-node`** (`tests/.../redemption.ak` is an unrelated STAR-vesting skeleton). Must parse the PlutusData → verify ECDSA votes → verify Merkle AuthoritiesProof → check stake ≥2/3 → read MMR root. **Still the #1 missing artifact** — search partner-chains smart-contracts repo (Plutus/Plutarch) or confirm it is unpublished/TBD. Related: `partner-chains/toolkit/smart-contracts/offchain/src/bridge/*` (off-chain side), `docs/c-to-m-bridge.md`.
- [~] **Which Midnight block/state the commitment finalizes** — the signed **MMR root** (payload) over BEEFY-finalized blocks; `block_number` + `validator_set_id` in the commitment. *(remaining: what the MMR leaves commit to — ledger state root vs block hash)*
- [ ] **Event-inclusion proof** — how a specific Midnight event is proven under the signed MMR root (MMR/Merkle path format the Cardano verifier checks).

## B. Direction B — Cardano → Midnight (replace trusted CMST with proofs)

- [x] **Current trusted model (CMST)** — `midnight-ledger/spec/cardano-system-transactions.md` (src-0030) — Header{block,index}+Body; validators rebuild for completeness but trust producer's range.
- [ ] **Trustless CMST: what a Midnight circuit must prove** — that a CMST Body is the complete+correct event set for a *Cardano-finalized* range. Design the circuit statement.
- [~] **Cardano finality certificate to verify in-circuit** — decide **Peras cert vs Mithril/ATMS** (B-i vs B-ii, design §4). **Direction chosen: Mithril/ATMS BLS cert over a CIP-0165 SCLS `root_hash`@slot** (src-0034/0037) → Midnight verifies 1 pairing + Merkle membership/nonmembership; no header replay. *(remaining: exact Mithril cert encoding + confirm mithril-stm BLS12-381; SCLS not-yet-historical caveat.)*
  - [ ] Peras "Votes & Certificates on Cardano" companion CIP (deferred in CIP-0140) — find/read.
  - [~] Mithril STM — confirm **BLS12-381** basis from `mithril-stm` crate/paper (src-0024 README didn't state the curve).
  - [x] **CIP-0165 SCLS** = the canonical inclusion anchor a Mithril cert signs (src-0034).
- [ ] **c2m-bridge pallet full logic** — `midnight-node/pallets/c2m-bridge/src/lib.rs` — `TransferHandler`, `MAX_APPROVALS_PER_BATCH`, approval/authority model (currently federated) → what trustless proof replaces the approvals.
- [ ] **Generic partner-chains bridge** — `pallet_partner_chains_bridge` (partner-chains toolkit) — the reusable framework c2m-bridge implements.
- [ ] **Cardano block-header verification in-circuit** — KES/VRF/Ed25519 header validation cost inside a Plonk/Halo2 circuit (reuse `proof-zk-recovery` Ed25519/SHA-512 gadgets + ZKIR EC ops).

## C. Consensus & finality (current + roadmap)

- [x] **Current: AURA + GRANDPA** — `midnight-docs/.../consensus.mdx` (src-0027); GRANDPA finality = **Ed25519** (src-0026).
- [x] **Current bridge finality: BEEFY = ECDSA** — `midnight-node/relay` (src via read); temporary.
- [ ] **⭐ Future BABE-design finality** — **watch for the release / spec.** What block production (BABE) *and finality/bridge-certificate* format the pivot introduces; re-pin Direction A against it. (User: BEEFY is temporary; a future release pivots to BABE.)
- [ ] **Validator-set selection & size** — `midnight-node/partner-chains/toolkit/committee-selection/*` — SPO stake-delegation selection, set size N (drives Mode-0 per-signature cost), rotation cadence (era/session length).
- [ ] **GRANDPA justification encoding** — the on-wire justification (round, commit, precommit sigs, authority-set id) a circuit/verifier parses.

## D. Proving stack, circuits & recursion

- [x] **midnight-proofs = Plonk+KZG / BLS12-381** (src-0023/0028); recursion = in-circuit proof verify + truncated challenges + aPLONK committed instances (no curve cycle).
- [x] **ZkStdLib chips** (src-0029) & **ZKIR v3** (src-0031, PR #617) — Jubjub/secp256k1 EC + Poseidon/SHA256/Keccak256.
- [ ] **Recursion/aggregation construction** — `midnight-zk/aggregation/src/{ivc,multi_circuit_aggregator}` — the actual IVC scheme, folding, and per-step cost. (README only names `aggregator`.)
- [ ] **KZG SRS / trusted setup Midnight uses** — `load_srs(SrsSource::Filecoin, …)` seen in ZkStdLib — is it the **Filecoin/Perpetual-Powers-of-Tau** SRS? Ceremony trust + updatability. Could a *shared* SRS serve both chains?
- [ ] **ZKIR v3 full instruction set + semantics** — `midnight-ledger/spec/zkir.md` (have overview) — full 33-instr table, error/UB rules; re-pin vs released `midnight-zkir-v3` (not frozen).
- [ ] **Impact VM opcodes + cost model** — `midnight-ledger/spec/impact-opcodes.md` (extracted, not yet ingested) — on-chain VM cost (compute/read/write/delete) for the public-state effects a proof guards.
- [ ] **transient-crypto crate** — `midnight-ledger/transient-crypto` — "proof-system primitives that may change" (proof/verifier-key formats, transcript). What's stable vs volatile.
- [ ] **Halo2→Groth16 / KZG-proof-on-Cardano cost** — measure the two Direction-A landing options (IOG Halo2-Plutus verifier vs Groth16 wrapper).

## E. Ledger, state & assets

- [x] **Transaction types & wire format** (src-0032/0033) — Standard/ClaimRewards + 9 SystemTransaction; container + FAB.
- [ ] **Zswap (shielded tokens + atomic swaps)** — `midnight-ledger/spec/zswap.md` — the shielded-asset model; relevant to *what* is bridged and atomic-swap bridging.
- [ ] **NIGHT + DUST** — `spec/night.md`, `spec/dust.md` — unshielded NIGHT (bridged asset), DUST generation (`CNightGeneratesDustUpdate`), fee model. cNIGHT ↔ NIGHT mapping.
- [ ] **coin-structure (address/token format)** — `midnight-ledger/coin-structure` — how a bridged token/address is represented; token-type identity across chains.
- [ ] **onchain-state / contract state format** — `midnight-ledger/onchain-state`, `spec/contracts.md` — the public contract-state a bridge contract holds.
- [ ] **Ledger state root / commitment** — what root BEEFY signs and a bridge attests inclusion against; the Merkle/MMR structure over ledger state.
- [ ] **Transaction properties/validity** — `spec/properties.md`, `spec/intents-transactions.md` — Intents model, balancing, validity invariants a cross-chain tx must satisfy.

## F. Cardano-side on-chain verifier & budget

- [x] **CIP-0381 (pairings) + CIP-0133 (MSM)** (src-0001/0004) enable BLS on-chain; measured Groth16 cost ~25% budget (src-0011).
- [ ] **Cardano signature builtins** — confirm & cost `verifyEcdsaSecp256k1Signature`, `verifyEd25519Signature`, `verifySchnorrSecp256k1Signature` (ex-units each) — Mode-0 per-signature cost basis.
- [ ] **Measure the actual Direction-A verifier** — ex-units to verify *N* ECDSA BEEFY sigs + AuthoritiesProof (Merkle) + MMR inclusion in one Plutus tx; find the N ceiling (CPU vs 16.5M mem vs 16,384-byte tx-size).
- [ ] **Plutus V3 / recent builtins** — any newer CIPs (e.g. sums-of-products, updated cost model) affecting verifier size.
- [ ] **Datum/redeemer design** — how the relay's PlutusData maps to a validator's datum/redeemer; state-thread/UTxO design for the bridge contract on Cardano.

## G. Cryptography & signature-scheme decisions

- [x] **Unified BLS12-381 substrate** (design §1a) — Midnight KZG/BLS12-381 ↔ Cardano CIP-0381.
- [x] **apk-proofs / committee key** (src-0025) — accountable ≥t-of-committed-keys BLS proof.
- [ ] **apk-proofs math + cost** — `w3f/apk-proofs` deeper + paper (eprint 2022/1611, "Aggregatable BLS w/ Chaum-Pedersen") — the committee-key SNARK cost for real N.
- [ ] **Mode decision matrix** — lock Mode 0 (ECDSA-native, current) vs Mode 1 (BLS aggregate) vs Mode 2 (zkBEEFY) per validator-set size + budget; the switch path.
- [ ] **JubJub role** — embedded curve; where it's used (in-circuit EC) vs BLS12-381 (proof/pairing).

## H. Trust model, security & setup

- [x] **Trusted-at-launch → trustless endpoint** (design §1b, src-0030).
- [ ] **End-to-end trust reduction** — enumerate every trust assumption in Mode 0/1 both directions; prove no party beyond each chain's consensus is trusted.
- [ ] **Trusted setup posture** — universal KZG (Midnight) vs optional Groth16 per-circuit (Cardano landing); ceremony provenance; VK-equality-on-deploy (Veil Cash lesson, src-0014).
- [ ] **Threat model** — reorg below finality, equivocation (≥1/3), relayer censorship/withholding, stale authority set, replay; borrow `proof-zk-recovery/docs/03-threat-model.md` structure.
- [ ] **Replay/nullifier both directions** — spent-map on Cardano (recovery pattern) + Midnight-side equivalent.

## I. Data availability, relayer & liveness

- [ ] **BEEFY justification / MMR-leaf availability** — where these live (off-chain, diffused); how a relayer/verifier obtains them; DA failure handling.
- [ ] **Relayer incentives & permissionlessness** — anyone can relay? reward? liveness guarantee if relayers stop.
- [ ] **Finality latency (end-to-end)** — GRANDPA finality time + relay cadence + Cardano settlement (Peras ~2 min) → total bridge latency each way.

## J. Economics, fees & UX

- [ ] **Fees** — DUST for Midnight-side txs; ADA for Cardano-side verification/settlement; who pays the relay cost.
- [ ] **Asset semantics** — lock-and-mint vs burn-and-unlock; NIGHT/cNIGHT/DUST + arbitrary tokens; supply conservation across the bridge.
- [ ] **Batching/throughput** — claims/tx ceiling on Cardano (src-0011 ~8/tx commitment); Midnight-side proof throughput; EUTxO concurrency.
- [ ] **Upgrade/governance** — rotating the Cardano-side verifier/VK; MIP process (`midnight-improvement-proposals`).

## K. Academic / theoretical grounding (PDF pipeline — docling warmed)

- [ ] **GRANDPA paper** — `w3f/consensus/pdf/grandpa.pdf` (linked from Midnight docs) — formal finality guarantees.
- [ ] **aPLONK** — eprint 2022/1352 (committed instances used by midnight-proofs).
- [ ] **Groth16** — eprint 2016/260 · **Plonk** — eprint 2019/953 · **Halo2** book.
- [ ] **zkBridge** — eprint 2022/435 · **Mina/Plumo** succinct light clients.
- [ ] **Kachina** — eprint 2020/543 (Midnight's private-smart-contract foundation) · **Zswap** paper.
- [ ] **EUTxO** model paper · **Ouroboros Praos/Peras** formal.
- [ ] **BEEFY/apk light-client** — w3f research `LightClientsBridges.md`, eprint 2022/1611.

## L. Specific repo artifacts still to read (quick wins)

- [ ] `midnight-node/relay/src/{cardano_encoding,authorities,justification,relayer,helper,error}.rs`
- [ ] `midnight-node/primitives/beefy/src/lib.rs`
- [ ] `midnight-node/pallets/c2m-bridge/src/lib.rs` (full)
- [ ] `midnight-node/partner-chains/**` (committee-selection, session, sidechain/domain/crypto)
- [ ] `midnight-ledger/spec/{zswap,night,dust,contracts,properties,intents-transactions,impact-opcodes}.md`
- [ ] `midnight-zk/aggregation/**`, `midnight-zk/circuits/README.md`
- [ ] `proof-zk-recovery` Ed25519/SHA-512/CKD Circom gadgets (reusable for in-circuit sig verification)

## M. Cross-cutting design decisions to LOCK

- [ ] Direction-A landing: **Mode 0 → Mode 1 (BLS)** path & trigger (validator-set size).
- [ ] Direction-B certificate: **Peras vs Mithril/ATMS**.
- [ ] Proof format on Cardano: **native BLS/ECDSA verify vs KZG-Halo2 vs Groth16 wrapper**.
- [ ] Abstract **"finality certificate" interface** so the Cardano validator survives the **BABE pivot** (design §3).
- [ ] Recursion boundary: what is folded (headers + authority-set evolution + inclusion) and where (Midnight IVC vs on-Cardano).
- [ ] Bridged-asset model & two-way conservation.

## N. Proof-claim / predicate application layer (from `C:/proofcategories/reports/cardano-midnight-proof-claim-report.md`)

The bridge substrate we design proves a **finality certificate**; this report specifies the
**typed-claim layer that rides on top of the resulting cross-chain anchor** (94 predicates:
42 Cardano + 52 Midnight). They compose — the bridge makes a foreign anchor *trustworthy*;
predicates are claims *against* that anchor. Directly relevant, especially §31 (bridges).

**⇒ Immediate next actions (committed):**
- [x] **Read the report** — done (948 lines).
- [x] **Ingested report §8/§9/§31** → `proof-claims/{claim-envelope,anchor-trust-models,bridge-claim-requirements}.md` (src-0036/0037/0035; 21+16+15 claims).
- [x] **Ingested `claim-interface-schema.md`** → `proof-claims/claim-interface-schema.md` (src-0038, 13 claims). *(still TODO: `verified-claim-catalog-42.md`, `midnight-proof-claim-catalog-52.md`, `cardano-prior-epoch-zk-proof-categories.md`.)*
- [x] **⭐ Pulled CIP-0165 (SCLS)** → `standards/cip-0165.md` (src-0034, 12 claims). **= the Direction-B inclusion anchor**: Mithril-BLS-certified SCLS `root_hash`@slot; UTxO membership/nonmembership. Folded into design §4.
- [ ] **Claim envelope (§8) as the bridge message format** — bind `predicate_id, network, anchor_type/digest, finality_rule, verifier_id, public_input/output_hash, context_hash, replay_scope, nullifier, expiry`. Reconcile with the relay's PlutusData (§A).
- [ ] **Bridge message identity (§31)** — deterministic message hash over {source net, block/slot, txid, index, event discriminator, source contract, payload hash, dest net, dest contract, recipient, amount/rights, nonce, lane, replay scope}; fan-out commitments for multi-destination.
- [ ] **Finality-rule binding (§31)** — the envelope must carry the finality rule name+params; a dest bridge rejects a proof whose finality rule it doesn't accept. Aligns with our Mode-0/1/2 + Peras/Mithril choice.
- [ ] **Asset identity (§31)** — canonical tuples: Cardano `(cardano, network, policy_id, asset_name)` + explicit ADA tag; Midnight distinguish unshielded NIGHT / shielded Zswap token type / contract tokens; **DUST = non-bridgeable** fee resource. Feeds §J asset model.
- [ ] **Replay: two distinct records** — ZK nullifier (one-time use of hidden note/credential) vs bridge consumed-message set (keyed by dest domain, bridge contract, source domain, lane, message ID). Both may co-exist.
- [ ] **Anchor/trust taxonomy (§9)** — settled-prefix, Mithril cert, ledger-state commitment (CIP-0165), block/tx root, contract-state root, Zswap root, DUST root, indexer commitment — map each to our finality options.
- [ ] **Nonmembership / absence** (§10, §34-Q3) — "not spent / not double-claimed / nullifier fresh" need an authenticated complete set (sparse Merkle / sorted map / accumulator) — relevant to bridge replay + Direction-B completeness.
- [ ] **Verifier registry governance (§25)** — statuses (active/frozen/deprecated/revoked), no caller-supplied VKs, staged upgrades — how the Cardano-side bridge verifier/VK is governed (feeds §J upgrade/governance).
- [ ] **Conformance vectors + failure codes (§26/§19)** — reuse the standard validator-check order and failure taxonomy for the bridge validator.
