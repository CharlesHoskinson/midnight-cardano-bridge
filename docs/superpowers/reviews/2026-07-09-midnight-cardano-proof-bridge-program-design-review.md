# Proof bridge program design review

**Date:** 2026-07-09

**Document:** docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md

**Baseline commit:** caf5039

## Method

Three independent readers reviewed the baseline:

- a proof-systems reader
- a consensus and root-of-trust reader
- an implementer and testnet-operator reader

They returned questions only and did not edit the document. The revised document
was then reread from its current state for remaining blocking or major questions.

The Deep Research Toolkit retrieval-planner also queried the compiled bridge
knowledge base. The index held 42 pages, 25 claims, 37 entities, and 35 relations.
The composed bridge dossier included all 25 selected claims and rejected none at
the verbatim gate.

The contradiction search returned three candidates:

- Midnight SRS supports both Filecoin and Midnight sources.
- TokenType has unshielded, shielded, and DUST variants.
- RelayChainProof contains a signed commitment and an authorities proof.

These are multi-valued relations, not contradictions.

## Questions and dispositions

| Area | Question | Disposition in the current design |
| --- | --- | --- |
| PoC landing | Which Midnight-to-Cardano proof path is normative? | The PoC uses BSB22 commitment-Groth16 over BLS12-381. Alternatives require separate production decision records. |
| Full wrapper | Does the Groth16 wrapper enforce the final KZG decider? | Sprint 2 requires a rejecting full-decider prototype. A preparation-only wrapper fails the gate. |
| Claim binding | What binds the Plutus claim to the BSB22 proof? | Plutus reconstructs claim_digest as an explicit public input. Commitment D has a separate committed-wire role. |
| Proof composition | Can valid proofs for different anchors be mixed? | Finality, inclusion, predicate, and envelope relations share proof-enforced domain, root, height, and schema equalities. |
| Nested keys | How are dynamic inner VKs and SRS material authorized? | The policy root contains an artifact-binding graph covering every suite, architecture, key, SRS, and transcript. |
| Template reuse | Can a registry selector replace circuit constraints? | No. Every family requires a constrained selector or authorized outer aggregation relation and substitution tests. |
| Recursive base | What prevents an alternate checkpoint base case? | The base public state binds the complete bootstrap-manifest digest and deployment domain. |
| Setup trust | Which setup artifacts are trusted? | KZG and Groth16 use explicit, independent inventories with hashes, degrees, transcripts, and assumptions. |
| Source upgrades | How is the active runtime or era authenticated? | Each consensus state binds a source-protocol fingerprint. Unknown, downgraded, or mismatched fingerprints halt the domain. |
| BEEFY rotation | Does validator_set_id authenticate keys? | No. The state tracks current and next authority roots, and the outgoing set authenticates mandatory-block handoffs. |
| Midnight event path | How does a ledger fact reach the signed MMR root? | Sprint 2 is an early feasibility gate and Sprint 5 implements the selected authenticated path. |
| Mithril state | Which certificate-chain fields recurse? | The tracked state includes previous certificate hash, current/next AVK, protocol parameters, era, and signature type. |
| Cardano claim | Does Mithril certification equal Cardano consensus finality? | No. Public and project-operated signer profiles are distinct. A lab profile cannot produce live-pass. |
| SCLS proofs | Does CIP-0165 define bridge proof encoding? | No. The bridge owns tree, padding, completeness, neighbor, path, and vector rules. |
| Checkpoint authority | Why is a reproduced checkpoint canonical? | It is an explicit weak-subjectivity decision under a fixed approval and freshness profile, not canonical by repetition. |
| Root mutation | Can governance replace roots in place? | PoC roots are immutable within a deployment domain. Production transitions require a specified consensus state machine. |
| Recovery | Is emergency governance a trust root? | Recovery credentials, threshold, delay, and domain effects are part of the policy root. |
| Testnet resets | Can old proofs survive a reused network name? | No. Genesis, chain-spec, certification, registry, verifier, and nullifier domains are rebound and tested. |
| Concurrent claims | Must every claim advance light-client state? | No. The state machine separates advance-and-consume from consume-current-anchor. |
| Implementation gap | How does the program move from specification to deployment? | Dedicated proof implementation, harness, settlement, and predeployment conformance sprints precede deployment. |
| Work ordering | Are proof and settlement ABIs fixed before contracts? | Sprint 6 freezes proof composition and settlement ABI before Sprint 7 implements destination contracts. |
| OpenSpec | What executable OpenSpec baseline is used? | The design pins @fission-ai/openspec 1.5.0, a custom review schema, stable domains, and strict validation. |
| Predicate completeness | Can dependent work begin with missing catalogs? | No. Sprint 1 requires exactly 42 Cardano and 52 Midnight source-backed records. |
| PoC outcomes | Can an upstream blocker count as success? | No. Results are live-pass, degraded-lab, or blocked. Only live-pass satisfies the PoC goal. |
| Blocked branch | Does a failed feasibility gate force fake deployment work? | No. A blocked path jumps to a reduced closure gate with reproducers, owners, skipped packages, and resume conditions. |
| Per-family execution | Does one example per direction cover every family? | No. Sprint 8 runs a complete local query-to-settlement flow for every proof-template family. |
| Per-predicate coverage | Are family tests enough for all 94 predicates? | No. Every predicate receives registry, positive, negative, and cross-predicate substitution coverage. |
| Failures | Can a retry consume a nullifier or duplicate settlement? | No. The persistent failure state machine classifies retries and keeps settlement atomic and idempotent. |
| Operations | What evidence makes a deployment reproducible? | Deployment manifests pin network, artifacts, roots, configuration, transactions, and runbook commands. |
| Performance | Is measurement enough without a threshold? | No. Gates name hardware, parameters, samples, percentiles, authority bounds, and pass/fallback limits. |

## Program result

The current design has eleven dependency-bounded sprints and 62 work packages.
Early feasibility gates can stop an unsound path before implementation. The
deployment sprint cannot start until proof, fault, predicate, and operating
conformance gates close.

No council question is dismissed as an implementation detail without a named work
package and exit condition. The technical results of those packages remain
execution risks, especially the full Halo2/KZG decider wrapper, authenticated
Midnight event path, and public Mithril SCLS certification profile.

This review predates the OpenSpec bootstrap. Sprint reviews will live in their
respective OpenSpec change directories.
