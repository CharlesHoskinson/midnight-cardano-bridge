# Examination Checklist — Midnight ↔ Cardano Recursive Trustless Bridge

Everything we still need to examine to take the design from **draft** to **buildable spec**.
Complements `RESEARCH-PLAN.md` (source corpus) and the design doc's §9 (open problems).

**Status legend:** `[ ]` not started · `[~]` partially examined · `[x]` examined/answered · `[!]` blocked by unpublished upstream artifact or measurement-only work.
Each item: *what to examine — where (repo/file/source) — the question it answers.*

Cloned repos live in ignored `_external/`: `midnight-zk`, `midnight-docs`, `midnight-ledger`,
`midnight-node`, `mithril`, `partner-chains`, `CIPs`, `plutus`, `cardano-ledger`,
`apk-proofs`, and `deep-research-toolkit`. The current source sweep is also
captured as a deep-research-toolkit run under `research-runs/`.

---

## A. Direction A — Midnight → Cardano (finality proof landed on Cardano)

- [x] **BEEFY relay → Cardano PlutusData layout** — resolved byte-exactly from `midnight-node/relay/src/cardano_encoding.rs` (src-0039): Plutus constructor tag `121`; `RelayChainProof = [SignedCommitment, AuthoritiesProof]`; `SignedCommitment = [Commitment, votes]`; `Commitment = [payloads, block_number, validator_set_id]`; `Payload = [id, data]`; `Vote = [signature, authority_index, public_key]`. The relay trims the extra Substrate ECDSA recovery byte before serializing signatures.
- [x] **AuthoritiesProof structure** — `relay/src/authorities.rs` (src-0039): Keccak Merkle multiproof with `root`, `total_leaves`, and recursive `proof`; leaves are `keccak256(public_key || stake_le)`.
- [x] **BEEFY justification + stake/authority payloads** — `node/src/payload.rs`, `relay/src/justification.rs`, and `primitives/beefy/src/lib.rs` (src-0040): the node signs an MMR root plus current/next stakes and authority-set commitments under payload IDs `cs/cb/ns/nb`, but `cardano_encoding.rs` serializes only `MMR_ROOT_ID` entries into `SignedCommitment`. Stake/authority payloads are used by the relay to build `AuthoritiesProof`; they are not carried as full stake data in the Cardano-facing object.
- [x] **Relayer flow mechanics** — `relay/src/relayer.rs` (src-0039): subscribes to `beefy_subscribeJustifications`, decodes `VersionedFinalityProof::V1`, fetches the runtime BEEFY validator set, generates `RelayChainProof`, and prints `PlutusData` hex.
- [!] **Relayer liveness/incentives** — no public artifact found for cadence, retries, permissionless submission, rewards, or DA failure handling. Treat as protocol/ops design work, not resolved by the current relay.
- [!] **⭐ The Cardano-side on-chain BEEFY verifier** — searched `midnight-node`, the archived `partner-chains` repo, and public partner-chain smart contracts. No public Plutus/Aiken/Plutarch validator verifies this `RelayChainProof`. Public partner-chain contracts cover ICS/reserve/federated/governance scripts, not a BEEFY light client. This remains the #1 missing artifact.
- [x] **Current BEEFY quorum semantics** — `runtime/src/beefy.rs` (src-0040) computes BEEFY "stakes" as `1` per validator, including fallback when no committee match is found. The current Mode-0 verifier should be modeled as equal-weight/count-threshold unless the relay format is extended to expose enough stake leaf preimages for arbitrary weighted threshold checks.
- [~] **Which Midnight block/state the commitment finalizes** — resolved for the current root: BEEFY signs the Substrate MMR root whose leaf data is `pallet_beefy_mmr::Pallet<Runtime>` (`runtime/src/lib.rs`, src-0040). Still open: the exact public ledger event/state-root proof carried from Midnight ledger state into that MMR leaf.
- [!] **Event-inclusion proof** — `relay/src/relayer.rs` has `get_mmr_proof()` using `mmr_generateProof`, but the current `handle_justification_stream_data` path does not call it and `RelayChainProof` does not serialize an event/MMR leaf inclusion proof. Must be specified or implemented before Cardano settlement can prove a specific Midnight event.

## B. Direction B — Cardano → Midnight (replace trusted CMST with proofs)

- [x] **Current trusted model (CMST)** — `midnight-ledger/spec/cardano-system-transactions.md` (src-0030) — Header{block,index}+Body; validators rebuild for completeness but trust producer's range.
- [x] **Trustless CMST: what a Midnight circuit must prove** — statement now pinned: verify a Mithril/ATMS certificate chain for a Cardano-state commitment, bind it to a CIP-0165 SCLS `root_hash`@slot, verify UTxO membership/nonmembership for the bridge event(s), derive the canonical CMST body deterministically, and emit a replay/nullifier key for each consumed bridge message. Implementation remains future work.
- [~] **Cardano finality certificate to verify in-circuit** — Direction remains **Mithril/ATMS BLS cert over a CIP-0165 SCLS `root_hash`@slot** (src-0034/0037/0042). Confirmed Mithril BLS implementation and certificate-chain mechanics; still open whether an SCLS certification module is deployed by signers/aggregators/clients.
  - [!] Peras "Votes & Certificates on Cardano" companion CIP — not found in the current CIPs checkout; CIP-0140 remains proposed and does not provide the concrete companion object.
  - [x] Mithril STM — `mithril-stm` confirms BLS via `blst`, `BlsSigningKey`, `BlsSignature`, aggregate verification keys, and `midnight_curves::Bls12` SNARK/IVC work (src-0042).
  - [x] **CIP-0165 SCLS** = the canonical inclusion anchor a Mithril cert signs (src-0034).
- [x] **c2m-bridge pallet full logic** — `midnight-node/pallets/c2m-bridge/src/lib.rs` (src-0041): implements `TransferHandler`; `MAX_APPROVALS_PER_BATCH = 32`; user credits require single-use governance-approved Cardano tx hashes; unapproved user transfers are routed to Treasury; reserve/invalid paths construct ledger system transactions. A trustless proof replaces `ApprovedMcTxHashes`.
- [x] **Generic partner-chains bridge** — `partner-chains/toolkit/bridge/pallet/src/lib.rs` (src-0041): node observability classifies Cardano UTxOs into transfer types and supplies them as mandatory inherent data; chain builders implement `TransferHandler`; governance configures watched Cardano scripts/checkpoints. This is not itself a finality-proof verifier.
- [!] **Cardano block-header verification in-circuit** — no public Midnight implementation or benchmark found. The chosen Mithril+SCLS path intentionally avoids full Praos/KES/VRF header replay for Direction B.

## C. Consensus & finality (current + roadmap)

- [x] **Current: AURA + GRANDPA** — `midnight-docs/.../consensus.mdx` (src-0027); GRANDPA finality = **Ed25519** (src-0026).
- [x] **Current bridge finality: BEEFY = ECDSA** — `midnight-node/relay` (src via read); temporary.
- [!] **⭐ Future BABE-design finality** — blocked on future Midnight release/spec. Current public `midnight-node` still exposes AURA/GRANDPA plus BEEFY support; Direction A must stay certificate-interface based.
- [x] **Validator-set selection & size** — runtime uses Partner Chain committee selection with `DParameter { num_permissioned_candidates, num_registered_candidates }`, `MaxAuthorities = 10_000`, and session rotation via `pallet_session_validator_management` (src-0046). Public resource chain specs now pin initial BEEFY/session/committee counts: govnet N=6, devnet N=7, mainnet N=10, all with registered candidates = 0 (src-0049). Mode-0 budgeting should use the target deployment's live authority set, but the published mainnet genesis workload is N=10 rather than the type ceiling.
- [~] **GRANDPA justification encoding** — background encoding known from Substrate/GRANDPA sources, but current bridge path uses BEEFY-ECDSA rather than parsing GRANDPA justifications on Cardano. Keep as only relevant for Mode-2/future certificate wrapping.

## D. Proving stack, circuits & recursion

- [x] **midnight-proofs = Plonk+KZG / BLS12-381** (src-0023/0028); recursion = in-circuit proof verify + truncated challenges + aPLONK committed instances (no curve cycle).
- [x] **ZkStdLib chips** (src-0029) & **ZKIR v3** (src-0031, PR #617) — Jubjub/secp256k1 EC + Poseidon/SHA256/Keccak256.
- [x] **Recursion/aggregation construction** — `midnight-zk/aggregation` (src-0043) provides IVC, single-circuit aggregation, and multi-circuit aggregation. Multi-circuit aggregation folds `(vk, statement)` claims, requires shared architecture/SRS and one public input per inner circuit, and verifies a final aggregation proof plus claims digest.
- [~] **KZG SRS / trusted setup Midnight uses** — `zk_stdlib::utils::plonk_api` supports `SrsSource::Filecoin` and `SrsSource::Midnight`; `base-crypto` defaults to `https://srs.midnight.network/` with expected SHA-256 hashes and says fetched data is not trusted because it is verified (src-0043/0044). Ceremony/updatability provenance should cite `midnight-trusted-setup` before locking governance language.
- [~] **ZKIR v3 full instruction set + semantics** — previous PR-617 ZKIR page ingested (src-0031), but the current ledger checkout does not contain `spec/zkir.md`. Re-pin against the released crate/spec before circuit implementation.
- [x] **Impact/on-chain runtime opcodes + cost model** — current paths are `spec/onchain-runtime.md` and `spec/cost-model.md` (src-0044), not `impact-opcodes.md`. Runtime has stack-machine opcodes including `root`, `idx`, `ins`, `popeq`; cost model tracks read time, compute time, block usage, bytes written, and churn separately.
- [x] **transient-crypto crate** — `midnight-ledger/transient-crypto/src/{lib,proofs,hash,merkle_tree}.rs` (src-0044): KZG proof/verifier-key API, `proof[v5]`, `verifier-key[v6]`, `prover-key[v7]`, Blake2b transcript hash, static verifier params up to degree 14, transient hash/commitment, Merkle tree formats. Treat tagged versions as implementation-specific but now located.
- [!] **Halo2→Groth16 / KZG-proof-on-Cardano cost** — still measurement-only; no public benchmark found for a Midnight bridge verifier wrapper or Halo2-Plutus bridge verifier.

## E. Ledger, state & assets

- [x] **Transaction types & wire format** (src-0032/0033) — Standard/ClaimRewards + 9 SystemTransaction; container + FAB.
- [x] **Zswap (shielded tokens + atomic swaps)** — `spec/zswap.md` (src-0044): Zerocash-like token model with shielded/unshielded token types, commitment set, nullifier set, commitment Merkle tree, and root history.
- [x] **NIGHT + DUST** — `spec/dust.md`, `spec/night.md`, `spec/cardano-system-transactions.md`, and `c2m-bridge` (src-0041/0044): NIGHT is an unshielded token; DUST is the non-transfer fee resource, generated from NIGHT with `night_dust_ratio = 5_000_000_000` (5 DUST per NIGHT); cNIGHT/Cardano bridge inflows execute `DistributeNight(CardanoBridge)`.
- [x] **coin-structure (address/token format)** — `coin-structure/src/coin.rs` (src-0044): token identity distinguishes `Unshielded(UnshieldedTokenType)`, `Shielded(ShieldedTokenType)`, and `Dust`; `NIGHT` is the all-zero unshielded token type; DUST has a single-byte tag.
- [x] **onchain-state / contract state format** — `spec/contracts.md` and `onchain-state/src/state.rs` (src-0044): contract state contains state value, verifier-key map, maintenance authority, and token balances; `StateValue` includes `Null`, `Cell`, `Map`, fixed arrays, and bounded Merkle trees.
- [~] **Ledger state root / commitment** — ledger asset/contract roots are now understood, but the BEEFY MMR leaf currently signs Substrate `pallet_beefy_mmr` data, not a documented Midnight ledger global state root. The bridge still needs a specified event/state inclusion path from ledger state into the signed MMR root.
- [x] **Transaction properties/validity** — `spec/intents-transactions.md` and `spec/properties.md` (src-0044): transactions contain intents, guaranteed/fallible Zswap offers, segment ordering, replay protection via intent history, and per-segment balancing with DUST-denominated fees.

## F. Cardano-side on-chain verifier & budget

- [x] **CIP-0381 (pairings) + CIP-0133 (MSM)** (src-0001/0004) enable BLS on-chain; measured Groth16 cost ~25% budget (src-0011).
- [x] **Cardano signature builtins** — CIP-0049 and Plutus sources confirm `verifyEcdsaSecp256k1Signature`, `verifyEd25519Signature`, and `verifySchnorrSecp256k1Signature` (src-0045). Local Alonzo cost entries include ECDSA CPU `35892428`, memory `10`; Ed25519 and Schnorr are linear-in-message-size models.
- [!] **Measure the actual Direction-A verifier** — still measurement-only; no public verifier exists to benchmark for *N* ECDSA votes + AuthoritiesProof + MMR inclusion.
- [~] **Plutus V3 / recent builtins** — BLS/pairing/MSM sources already ingested via CIP-0381/0133; signature builtins confirmed via CIP-0049. Current protocol-parameter costs must be pulled from target network before implementation.
- [!] **Datum/redeemer design** — blocked on the unpublished Cardano BEEFY verifier and bridge state-machine design.

## G. Cryptography & signature-scheme decisions

- [x] **Unified BLS12-381 substrate** (design §1a) — Midnight KZG/BLS12-381 ↔ Cardano CIP-0381.
- [x] **apk-proofs / committee key** (src-0025) — accountable ≥t-of-committed-keys BLS proof.
- [~] **apk-proofs math + cost** — repo and bridge relevance ingested (src-0025); real-N bridge cost remains measurement work.
- [x] **Mode decision matrix** — provisional lock: Mode 0 only for small/equal-weight current BEEFY committees; Mode 1 target if Midnight exposes BLS aggregate finality; Mode 2 zk-wrap fallback for large or non-native signature sets. Trigger is actual validator N and Cardano budget measurement.
- [x] **JubJub role** — Midnight uses BLS12-381/KZG for proof commitments and pairings; Jubjub/embedded curve is in-circuit value-commitment/EC machinery, not the external finality signature substrate.

## H. Trust model, security & setup

- [x] **Trusted-at-launch → trustless endpoint** (design §1b, src-0030).
- [~] **End-to-end trust reduction** — Mode 0 currently depends on unpublished Cardano verifier and equal-weight BEEFY assumptions; Direction B depends on Mithril SCLS module deployment. Trust-reduction skeleton is known, final proof awaits artifacts.
- [~] **Trusted setup posture** — Midnight/Filecoin SRS paths and hash verification are now pinned (src-0043/0044); per-circuit Groth16 risks/VK-equality controls remain from src-0014. Need ceremony provenance from `midnight-trusted-setup` before final governance language.
- [~] **Threat model** — risks enumerated: reorg below finality, ≥1/3 BEEFY/GRANDPA equivocation, relayer withholding, stale authority set, missing event-inclusion proof, governance-approved c2m hashes, replay. Full threat-model doc still to write.
- [x] **Replay/nullifier both directions** — application layer requires two records: ZK nullifier and bridge consumed-message set; Midnight ledger also has intent replay history and Zswap/DUST nullifier sets (src-0035/0036/0044).

## I. Data availability, relayer & liveness

- [~] **BEEFY justification / MMR-leaf availability** — relayer obtains justifications via RPC subscription and can call `mmr_generateProof`; no public DA/failure-handling policy found.
- [!] **Relayer incentives & permissionlessness** — no public mechanism found.
- [!] **Finality latency (end-to-end)** — blocked on relay cadence/incentives, target Cardano finality rule, and future BABE/BEEFY replacement details.

## J. Economics, fees & UX

- [~] **Fees** — DUST model and ADA verifier cost basis known; relay payment/settlement fee assignment remains design work.
- [~] **Asset semantics** — DUST is non-bridgeable; NIGHT/cNIGHT path and token-type identity are pinned; arbitrary-token bridge semantics and supply-conservation accounting remain to specify.
- [!] **Batching/throughput** — Cardano Groth16 benchmarks exist, but no Direction-A BEEFY verifier benchmark or Midnight proof-throughput measurement exists.
- [!] **Upgrade/governance** — verifier/VK governance remains design work; use proof-claim registry pattern but no concrete bridge governance artifact found.

## K. Academic / theoretical grounding (PDF pipeline — docling warmed)

- [~] **GRANDPA paper** — operational GRANDPA guarantees are covered by Polkadot/Midnight sources; formal PDF still useful for proof appendix, not a current bridge artifact blocker.
- [~] **aPLONK** — role in Midnight committed instances is identified via `midnight-proofs`; paper-level proof details remain PDF-pipeline background.
- [~] **Groth16 / Plonk / Halo2** — implementation and measured Cardano costs are already source-backed; papers/book remain background citations for a final spec.
- [~] **zkBridge / Mina/Plumo** — precedent designs not required to correct current Midnight/Cardano artifacts; keep for comparative architecture section.
- [~] **Kachina / Zswap paper** — Midnight ledger Zswap spec now covers bridge-relevant asset roots; formal papers remain background.
- [~] **EUTxO / Ouroboros Praos/Peras formal** — CIPs and current design docs cover the implementation decision; formal sources remain final-spec references.
- [~] **BEEFY/apk light-client** — BEEFY/apk implementation relevance is source-backed; eprint-level math remains for cost/security appendix.

## L. Specific repo artifacts still to read (quick wins)

- [x] `midnight-node/relay/src/{cardano_encoding,authorities,justification,relayer,error}.rs`
- [x] `midnight-node/primitives/beefy/src/lib.rs`
- [x] `midnight-node/pallets/c2m-bridge/src/lib.rs` (full)
- [~] `midnight-node/partner-chains/**` — bridge pallet, smart contracts, and committee-selection paths read enough for this sweep; deeper sidechain/domain crypto remains implementation follow-up.
- [x] `midnight-ledger/spec/{zswap,night,dust,contracts,properties,intents-transactions,onchain-runtime,cost-model}.md`
- [x] `midnight-zk/aggregation/**`
- [~] `proof-zk-recovery` Ed25519/SHA-512/CKD Circom gadgets — still relevant for Mode-2 but not re-read in this sweep because Direction B now prefers Mithril/SCLS and Direction A lacks a public verifier.

## M. Cross-cutting design decisions to LOCK

- [~] Direction-A landing: **Mode 0 now only for small/equal-weight current BEEFY; Mode 1/2 trigger = actual N + verifier benchmark.**
- [x] Direction-B certificate: **Mithril/ATMS over SCLS** is the preferred path; Peras stays future/research.
- [~] Proof format on Cardano: **native ECDSA for current BEEFY if verifier is published; BLS if finality certificate changes; Groth16/KZG wrapper only after benchmark.**
- [x] Abstract **"finality certificate" interface** so the Cardano validator survives the **BABE pivot** (design §3).
- [x] Recursion boundary: use Midnight IVC/aggregation for Cardano-side certificates/claims; give Cardano a native verifier or one wrapped proof, not per-step header replay.
- [~] Bridged-asset model & two-way conservation — DUST/NIGHT/token identity pinned; arbitrary-token conservation rules remain a spec item.

## N. Proof-claim / predicate application layer (from `C:/proofcategories/reports/cardano-midnight-proof-claim-report.md`)

The bridge substrate we design proves a **finality certificate**; this report specifies the
**typed-claim layer that rides on top of the resulting cross-chain anchor** (94 predicates:
42 Cardano + 52 Midnight). They compose — the bridge makes a foreign anchor *trustworthy*;
predicates are claims *against* that anchor. Directly relevant, especially §31 (bridges).

**⇒ Immediate next actions (committed):**
- [x] **Read the report** — done (948 lines).
- [x] **Ingested report §8/§9/§31** → `proof-claims/{claim-envelope,anchor-trust-models,bridge-claim-requirements}.md` (src-0036/0037/0035; 21+16+15 claims).
- [x] **Ingested `claim-interface-schema.md`** → `proof-claims/claim-interface-schema.md` (src-0038, 13 claims). *(remaining catalogs: `verified-claim-catalog-42.md`, `midnight-proof-claim-catalog-52.md`, `cardano-prior-epoch-zk-proof-categories.md`.)*
- [x] **⭐ Pulled CIP-0165 (SCLS)** → `standards/cip-0165.md` (src-0034, 12 claims). **= the Direction-B inclusion anchor**: Mithril-BLS-certified SCLS `root_hash`@slot; UTxO membership/nonmembership. Folded into design §4.
- [x] **Claim envelope (§8) as the bridge message format** — locked as the outer typed message. Current `RelayChainProof` is a raw finality artifact and must be wrapped/bound by envelope fields before production settlement.
- [x] **Bridge message identity (§31)** — deterministic message hash locked as required replay key input.
- [x] **Finality-rule binding (§31)** — locked: envelope must name the accepted rule and params (`midnight-beefy-ecdsa-equal-weight`, future BLS/BABE rule, `mithril-scls`, etc.).
- [x] **Asset identity (§31)** — locked: Cardano asset tuple + Midnight unshielded/shielded token identity; **DUST = non-bridgeable** fee resource.
- [x] **Replay: two distinct records** — locked: ZK nullifier and consumed bridge-message set are separate.
- [x] **Anchor/trust taxonomy (§9)** — mapped to current options: BEEFY signed MMR root, Mithril cert, SCLS root, Zswap/DUST/contract roots, and indexer commitments as untrusted unless certified.
- [x] **Nonmembership / absence** — SCLS ordered-neighbor nonmembership and ledger nullifier/intent sets are the relevant complete-set mechanisms.
- [~] **Verifier registry governance (§25)** — registry pattern locked; concrete Cardano verifier/VK governance blocked on unpublished verifier.
- [!] **Conformance vectors + failure codes (§26/§19)** — blocked until validator/redeemer format exists.
- [!] **Remaining sibling proof-claim catalogs** — the recorded local corpus path `C:/proofcategories/reports` is not present in this workspace, and targeted filename searches did not find `verified-claim-catalog-42.md`, `midnight-proof-claim-catalog-52.md`, or `cardano-prior-epoch-zk-proof-categories.md`. Ingestion needs the private/local corpus location.
