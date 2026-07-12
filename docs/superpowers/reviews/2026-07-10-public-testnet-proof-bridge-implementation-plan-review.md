# Public testnet proof bridge implementation plan review

**Date:** 2026-07-10

Classification: pre-control-plane bootstrap review

**Historical design-session baseline:** `3db35fa9a7e7257359f5def4bb216c60356643b8`

**Landing snapshot:** `9f5445659d1927510c6c29f0285a405ecda30767`

**Program:** `mcb.public-testnet-livepass.v2`

The historical baseline does not contain the plans described below. The review
and reviewed content arrived together in the landing snapshot, so this record
does not bind a prior candidate tree and does not authorize Sprint 0. It is an
advisory bootstrap review. The later blob-bound remediation review replaces it
as provenance for the revised plan.

## Scope

The council reviewed the master 14-sprint program, the detailed Sprint 0 plan,
the program rebaseline, the 25-section canonical bridge design, and the program
wiki. The review covered package dependencies, controller authority, closure and
publication, Cardano and Midnight roots, Halo2/KZG and BSB22/Groth16 setup,
deployment sequencing, receipt graphs, and the public-testnet outcome rules.

The readers were read-only and used separate roles:

- operations and repository-control reader
- proof-systems and MPC reader
- governance, consensus, and hash-DAG reader

Agent review does not count as human ceremony participation or independent human
entropy.

## Dispositions

| Area | Contract in the reviewed plan |
| --- | --- |
| Controller installation | Two unprivileged reproducible builds precede installation. The operator carries the complete qualification-file hash into the elevated session, which verifies it before trusting any embedded source, binary, receipt, or provisioner pin. |
| Credential evidence | `GitCredentialHandleV1` is immutable. Review, pre-fetch, and pre-sign probes are separate signed receipts, and all three are present in the remote-confirmation bundle. |
| Repository lineage | Every package imports the exact cumulative transitive set of closed predecessor bundles. Fixtures cover staged S03 admission, join sprints, missing transitive predecessors, and unapproved extras. |
| Closure | The envelope excludes its own fixed path and blob from its object inventory. `FinalizeClosure` materializes, validates, commits, and integrates the closure tree, proves source/integration tree equality, and returns the canonical integration commit as the only publication target. |
| KZG history | Sealed historical SRS bytes use `HistoricalCeremonyQualificationV1` and their original chronology and beacon. New or update ceremonies use fresh precommitted future beacons. Missing historical evidence blocks or forces a rebaseline. |
| Setup ordering | Sprint 8 derives the root and domain, produces `RegistryActivationV1`, then produces domain-bound artifact authorizations. Concrete ABI instances begin with Sprint 12 deployment observations. |
| Intent ordering | `DeploymentIntentV1` precedes deployment and excludes controller leases and fences. Deployment observations, ABI instances, root contexts, activation, and receipts precede `RunIntentV1`. |
| Receipt ordering | Destination state does not contain the digest of the receipt that authenticates it. Execution receipts bind the run intent; later immutable evidence heads index receipt digests; the classifier binds the terminal head. |
| Gate ordering | Activation uses only the roster-defined predeployment subset. Classifier readiness covers every other evaluation before its own gate evaluation is appended. This review's proposal to make final Sprint 13 reviews direct classifier inputs is superseded; current plans treat those artifacts as advisory. |
| Proof authority | The Groth16 R1CS recomputes the full KZG decision. VK, commitment-key, registry, authorization, ABI, and deployed-verifier checks compare like-typed bytes or hashes. |

## Advisory council result

| Reader | Blocking | Major | Minor | Verdict |
| --- | ---: | ---: | ---: | --- |
| Operations and repository control | 0 | 0 | 0 | pass |
| Proof systems and MPC | 0 | 0 | 0 | pass |
| Governance, consensus, and hash DAG | 0 | 0 | 0 | pass |

Recorded model counts: **0 blocking, 0 major, 0 minor**. These counts are
historical quality signals, not closure evidence.

## Historical mechanical evidence

The following values describe the landing snapshot before the Fable remediation:

- 14 sprints, 100 unique packages, 206 dependency edges, and a 100-node
  topological ordering
- package distribution `12/6/9/8/6/6/7/8/6/7/7/6/7/5`
- exactly 25 numbered canonical design sections
- 273 ordered graph events, 134 materialized nodes, 136 materialized edges, and
  zero source-hash or materialization errors
- immutable V1 graph prefix: 12,144 bytes and SHA-256
  `401d2fc42de6d52fc0b52633364c9a428ec364a2fa8daf8d3c4b6226b1e51e50`
- strict OpenSpec: 13 passed, 0 failed
- full reference harness: exit 0, `structural-pass`, deployment `blocked`, and
  `activation_eligible=false`

## Remaining boundary

This review does not approve the implementation plan or a deployed bridge. The six
`S01-BLOCK-*` gates, eight `CONS-*` gates, exact source-backed 42/52 predicate
catalogs, public chain receipts, destination verifier surfaces, and human setup
evidence remain execution work. Mainnet is outside the program. Only a Cardano
Preview and Midnight Preview or Preprod run that reaches the strict `live-pass`
classifier satisfies the proof-of-concept goal.
