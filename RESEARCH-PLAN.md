# Research Plan — Midnight ↔ Cardano Recursive Trustless Bridge

Working document (not part of the OKF knowledge base). Tracks the source corpus,
per-source pipeline status, and the synthesis deliverable. Update the STATUS column
as each source moves through: `fetch → run → extract → gate → page`.

## Goal

Build a comprehensive, verbatim-gated knowledge base on Midnight and Cardano design,
then synthesize a **recursive trustless bridge** architecture:
- **Midnight → Cardano** direction verified with **Groth16** proofs (cheap pairing
  verification on Cardano via CIP-381 BLS12-381 builtins).
- **Cardano → Midnight** direction verified with **Plonk / Halo2** proofs.

Key design tension to resolve through research: what each side can *cheaply verify*
on-chain, what each source chain's *finality/consensus* requires a light client to
prove, and how *recursion* compresses chain history into a single succinct proof.

## Pipeline per source (full verbatim-gated rigor)

1. `python skills/research-knowledge-graph/scripts/fetch.py <url> --out research-runs/_raw/<slug>.md`
2. `python skills/research-knowledge-graph/scripts/start_research_run.py <url> --content-file <raw>`
3. Extract `claims.jsonl` / `entities.jsonl` / `relations.jsonl` (verbatim quotes vs source.md)
4. `python skills/research-knowledge-graph/scripts/check_claims.py <run_dir>` → must exit 0
5. Write/merge OKF page(s) via `scaffold_page.py`; log `src-XXXX` in `sources/index.md`
6. After a batch: `lint_graph.py`, then `knowledge-compiler/scripts/compile.py`

## Source corpus (target ~30)

### A. Midnight
| # | Source | URL (candidate) | Type | Status |
|---|--------|-----------------|------|--------|
| A1 | Midnight architecture overview | docs.midnight.network | web | todo |
| A2 | Compact smart-contract language | docs.midnight.network/develop | web | todo |
| A3 | Kachina — Foundations of Private Smart Contracts | eprint.iacr.org/2020/543 | pdf | todo |
| A4 | Midnight proving stack (Halo2/Plonk, zk-SNARK) | docs.midnight.network | web | todo |
| A5 | Zswap — shielded/atomic-swap token protocol | eprint.iacr.org (Zswap) | pdf | todo |
| A6 | Midnight consensus / partner-chain / Ouroboros BFT | docs / partner-chains | web | todo |

### B. Cardano
| # | Source | URL (candidate) | Type | Status |
|---|--------|-----------------|------|--------|
| B1 | Extended UTXO (EUTxO) model | iohk.io research / eprint | pdf | todo |
| B2 | Plutus Core builtins (crypto) | plutus docs / cardano-ledger | web | todo |
| B3 | CIP-381 — BLS12-381 Plutus primitives | raw.githubusercontent.com/.../CIP-0381/README.md | web | **DONE (src-0001, 6 claims gated, page written)** |
| B4 | Groth16 verifier on Cardano (Plutus) | community impl / plutus-crypto | web | todo |
| B5 | Ouroboros Praos + settlement/finality | iohk research | pdf | todo |
| B6 | CIP-Peras (fast finality) | CIPs repo | web | todo |
| B7 | Plutus script budget / execution units / cost model | cardano docs | web | todo |
| B9 | plutus-groth (pure-Plutus Groth16 verifier, cost baseline) | raw.githubusercontent.com/Modulo-P/plutus-groth | web | **DONE (src-0002, 15 claims)** |
| B10 | ak-381 (Aiken Groth16 verifier, Circom/SnarkJs format) | raw.githubusercontent.com/Modulo-P/ak-381 | web | **DONE (src-0003, 14 claims)** |
| B11 | CIP-0133 (BLS12-381 MSM builtin) | raw.githubusercontent.com/.../CIP-0133 | web | **DONE (src-0004, 12 claims)** |
| B12 | CIP-0140 Ouroboros Peras (finality) | raw.githubusercontent.com/.../CIP-0140 | web | **DONE (src-0005, 20 claims)** |
| B8 | Cardano block header / KES / VRF signatures | cardano-ledger spec | web | todo |

### C. Proof systems
| # | Source | URL (candidate) | Type | Status |
|---|--------|-----------------|------|--------|
| C1 | Groth16 — pairing-based NIZK | eprint.iacr.org/2016/260 | pdf | todo |
| C2 | Plonk | eprint.iacr.org/2019/953 | pdf | todo |
| C3 | Halo2 / Halo (recursive, no trusted setup) | zcash halo2 book / Halo paper | web/pdf | todo |
| C4 | Recursive proof composition / accumulation (Nova, PCD) | eprint | pdf | todo |
| C5 | BLS12-381 curve + pairing-friendly / curve cycles | ietf/zcash spec | web | todo |
| C6 | KZG polynomial commitments / trusted setup | eprint | pdf | todo |

### D. Bridges / light clients / state proofs
| # | Source | URL (candidate) | Type | Status |
|---|--------|-----------------|------|--------|
| D1 | zkBridge — trustless cross-chain via SNARKs | eprint.iacr.org/2022/435 | pdf | todo |
| D2 | Succinct blockchain / recursive light client (Mina) | Mina / Coda paper | pdf | todo |
| D3 | Trust-minimized light client (IBC / Tendermint) | cosmos docs | web | todo |
| D4 | Plumo / Celo succinct light client | eprint | pdf | todo |
| D5 | Proof-of-consensus / committee-signature verification | survey/paper | pdf | todo |

### E. Bridge-specific synthesis inputs
| # | Source | URL (candidate) | Type | Status |
|---|--------|-----------------|------|--------|
| E1 | Verifying Ed25519/VRF/KES in a SNARK (cost) | research | pdf | todo |
| E2 | Cardano stake distribution / ledger state proofs | cardano-ledger | web | todo |
| E3 | Official Midnight↔Cardano bridging (NIGHT/DUST) if any | docs | web | todo |

## Deliverable

`knowledge_base/bridges/midnight-cardano-recursive-bridge.md` — the synthesized design
doc: protocol flows both directions, proof formats, on-chain verifier cost budget,
recursion strategy, finality/trust model, data availability, and open problems — every
load-bearing claim cross-linked to a gated KB page.

## Progress log

- 2026-07-09: toolkit installed (`[full]`), `drt init` done, corpus planned. Validated
  the pipeline end-to-end on one source before parallel fan-out.
- 2026-07-09: patched `fetch.py` bytes/str bug (+ content-type-aware HTML→markdown).
- 2026-07-09: **Batches 1-4 complete — 15 sources, 206 verbatim-gated claims, 18 pages,
  220 entities.** Cardano side (Groth16 feasibility/cost, MSM limits, Peras finality),
  Midnight side (dual-state, Compact circuits, ZKP model), proof systems (Halo2/PLONKish,
  commitment-Groth16, trusted setup), and the `proof-zk-recovery` working Preview
  deployment (src-0011..0015). Index compiled (DuckDB+LanceDB).
- 2026-07-09: **Design doc drafted** → `knowledge_base/bridges/midnight-cardano-recursive-bridge.md`.
- 2026-07-09: **Consensus batch (src-0016..0018, 45 claims):** Polkadot BABE + GRANDPA +
  hybrid-consensus wiki (ecosystem background).
  **CORRECTION (src-0026/0027, authoritative Midnight docs):** Midnight uses **AURA**
  (NOT BABE) for block production + GRANDPA finality; **GRANDPA sigs = Ed25519**;
  validators from Cardano SPO delegation. Also src-0028/0029: real recursion = in-circuit
  proof verification + truncated challenges + aPLONK (no Pluto-Eris); ZkStdLib has
  secp256k1/bls12_381/keccak/blake2b in-circuit chips. Scrubbed BABE mis-attributions.
  **Resolved open problem #1.** Revised design doc: Direction A finality = a GRANDPA
  justification (>2/3 precommit sig quorum); symmetric with Peras cert; recommended
  modeling on Polkadot's **BEEFY** (remote finality-proof verification). 18 sources /
  251 claims / 21 pages, index compiled.
- 2026-07-09: **BEEFY batch (src-0019..0021, 46 claims):** canonical BEEFY spec,
  light-client/zkBEEFY, sdk impl. **21 sources / 297 claims / 24 pages.** Design doc
  §3 rewritten with the concrete BEEFY signed-commitment verifier (MMR, mandatory-block
  handoff) + the signature-scheme decision tree: Mode 1 (BLS12-381 BEEFY → near-native
  CIP-0381) vs Mode 2 (ECDSA/Ed25519 → zkBEEFY Groth16 wrapper, constant cost).
  Handled one mid-stream agent failure by re-dispatching extraction-only on the
  existing run dir.
- 2026-07-09: **BLS-both-sides batch (src-0022..0025, 46 claims):** IOG Halo2-Plutus
  verifier, Midnight proving curves, Cardano Mithril, w3f apk-proofs. **25 sources /
  343 claims / 28 pages.** Design doc gained §1a **unified BLS12-381 substrate**
  pillar: Midnight = Plonk/KZG over BLS12-381 (universal setup); Cardano verifies
  Halo2/KZG directly (IOG) + CIP-0381; both finality certs are BLS aggregates
  (BLS-BEEFY / Mithril-ATMS); apk-proofs = shared ≥2/3 accountable-light-client core.
  Groth16 now OPTIONAL (universal KZG replaces per-circuit ceremony). `bls12-381`
  entity spans 10 sources.
- 2026-07-09: **Real-repo batch (src-0026..0033, 114 claims):** cloned midnight-zk/docs/
  ledger/node. CORRECTED consensus (**AURA not BABE**; GRANDPA=**Ed25519**) + recursion
  (in-circuit proof verify + truncated challenges + aPLONK, **no Pluto-Eris**). Found the
  REAL bridge impl: `midnight-node/relay` (midnight-beefy-relay, **BEEFY=ECDSA** → Cardano
  **PlutusData** via `pallas`) + `pallets/c2m-bridge` (cNIGHT). Ledger: **trusted-at-launch**
  (CMST), tx model (Standard/ClaimRewards + 9 SystemTransaction; DistributeNight(CardanoBridge)),
  FAB wire format. Added **PR #617 = ZKIR v3** (Compact→ZKIR→PLONK; Jubjub/secp256k1 EC +
  Poseidon/SHA256/Keccak256 in-circuit). User guidance: **BEEFY is temporary; future pivots to
  BABE** — design kept mechanism-agnostic (Mode 0 ECDSA-native / Mode 1 BLS / Mode 2 zk-wrap).
  **33 sources / 457 claims / 36 pages.**
- 2026-07-09: **Made `EXAMINATION-CHECKLIST.md`** (14 sections A–N). Examined §A relay:
  Direction-A artifact = `RelayChainProof` PlutusData (ECDSA votes + Merkle AuthoritiesProof
  vs keyset_commitment + stake≥2/3 + MMR root); **Cardano-side on-chain verifier NOT in
  midnight-node (redemption.ak = vesting skeleton) — #1 gap.**
- 2026-07-09: **Proof-claim layer batch (src-0034..0038, 77 claims):** ingested proof-claim
  report §8/§9/§31 + claim-interface-schema + **CIP-0165 SCLS**. **38 sources / 534 claims /
  41 pages.** Design doc gained §8a (typed-claim application layer) + Direction-B **inclusion
  anchor = Mithril-cert over CIP-0165 SCLS root** (membership/nonmembership, no header replay).
- 2026-07-09: **Validator-set sizing follow-up (src-0049, 5 claims):** DRT-gated public
  chain-spec extraction pins initial BEEFY/session/committee counts at govnet N=6, devnet N=7,
  and mainnet N=10, all with `num_registered_candidates = 0`. Mode-0 budgeting can use
  mainnet genesis N=10 as the published baseline while still tracking live authority rotation.
- NEXT: find the Cardano-side BEEFY verifier (partner-chains smart-contracts repo); Zswap +
  NIGHT/DUST specs; remaining sibling catalogs (42/52); the BABE-design finality format when it
  lands; academic PDFs (Groth16/Plonk/zkBridge/Mina/GRANDPA/aPLONK) + EUTxO. Docling warmed.
