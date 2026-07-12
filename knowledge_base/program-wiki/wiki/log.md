---
id: program-wiki.log
type: log
title: Program wiki log
status: active
updated_at: 2026-07-12T02:20:00Z
sources:
  - source.design-session.2026-07-10-program-rebaseline
  - source.design-session.2026-07-10-implementation-planning
  - source.external.gnark-bsb22-mpc.2026-07-10
  - source.design-session.2026-07-11-executable-trust-boundaries
  - source.design-session.2026-07-11-acyclic-authority-evidence
  - source.design-session.2026-07-12-fable-audit-remediation
  - source.external.gnark-bsb22-mpc.2026-07-12
  - source.external.proof-zk-recovery-mpc.2026-07-12
  - docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md
  - docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md
  - docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md
  - knowledge_base/bridges/midnight-cardano-recursive-bridge.md
---

# Program wiki log

## [2026-07-10] ingest | Public-testnet program rebaseline

Recorded the initial public-only outcome, 14-sprint and 100-package execution
model, all-94 predicate scope, public direction-family coverage, agent control
model, imported MPC boundary, later human ceremony, council corrections, and
known public-chain gates. Added the Karpathy LLM Wiki source receipt and initial
maintained pages. The 2026-07-12 entry supersedes the package count.

## [2026-07-10] plan | Executable program and Sprint 0

Published the initial 100-package master register with dependencies, artifacts, and stop
evidence. Added the code-level 12-package Sprint 0 plan for the controller,
runlogs, command supervision, snapshots, repository transactions, agent lanes,
wiki validation, and `GateRosterV2`. The 2026-07-12 split replaces those counts
with 106 packages and 18 Sprint 0 packages. Later code-level sprint plans require
their closed predecessor snapshot and admitted interfaces.

The executable plan uses full package dependency ids and states, atomic event
objects under one fenced controller, renewable leases, separately supervised
readers, and a closure envelope. It also fixes final KZG-decider ownership, SRS
binding, final-head acknowledgement for human contributions, and the blocked
status of the missing predicate catalogs.

## [2026-07-10] review | Control and ceremony boundary

Bound the controller behind a dedicated OS identity and ACL-protected broker,
with package processes running under restricted tokens. Split discovery packets
from resolved implementation packets, made remote confirmation a schema-backed
state transition, and typed the closure delta below the path level.

Pinned the commitment-aware setup semantics to exact gnark source objects.
Phase 1 contributes `tau/alpha/beta`; each circuit's Phase 2 contributes `delta`
and every commitment `sigma`, while `gamma` is the fixed G2 generator. Every new
or update KZG ceremony, Phase 1, and per-circuit Phase 2 transcript has a distinct
future beacon and sealed head keyed by setup kind, stable transcript id,
SRS-profile id, phase, and circuit id or no-circuit sentinel. Historical KZG
bytes require their original ceremony chronology and beacon evidence.

## [2026-07-11] plan | Executable trust boundaries

Separated source-row recovery from public-profile admission for the 42 Cardano
and 52 Midnight predicates. Defined immutable artifact slots whose concrete
circuit, VK, SRS, and transcript values enter later authorization records.

Made KZG qualification algebraic: two independent implementations replay every
contribution, verify the selected contribution proof and all declared G1/G2
powers, and reject inconsistent or substituted transcript elements. Split the
predeployment activation-gate subset from the complete classifier gate set so
deployment does not depend on receipts it must produce.

Defined a one-shot authenticated canonical Git seed, bounded pack quarantine,
qualified Git credential handles, atomic remote-confirmation bundles with exact
streams, and cumulative predecessor imports. OpenSpec closure now uses a
relocation-only archive candidate so no receipt hashes a tree containing itself.

## [2026-07-11] review | Acyclic authority and evidence records

Separated immutable credential handles from review, pre-fetch, and pre-sign
probe receipts. The elevated service installer now authenticates the complete
qualification file from an operator-carried hash before trusting any embedded
pin. Closure publication uses a fixed envelope path outside its own object
inventory. Its finalization action verifies source/integration tree equality and
returns a context that publishes only the canonical integration commit.

Split historical KZG qualification from new or update ceremonies. Sprint 8 now
produces `RegistryActivationV1` before artifact authorization and leaves concrete
ABI instances to deployment observations. Destination state no longer contains
the digest of the receipt that authenticates it. Execution receipts bind the run
intent, later evidence heads index those receipts, and the classifier binds the
terminal head.

## [2026-07-12] remediate | Fable audit corrections

Split the three oversized Sprint 0 packages into six additional packages while
preserving every published id. The active register now contains 14 sprints, 106
packages, and 18 Sprint 0 packages. The master, Sprint 0, and rebaseline
documents share one re-entry table.

Reader reports are advisory rather than closure authority. Sprint closure now
rests on deterministic suites, signed operator records, external source and
chain receipts, and remote confirmation. W01 also requires an external planning
baseline precommitment.

Unified public bootstrap on official genesis, official rules, and official
finality roots. A checkpoint qualifies only as an official-root-derived
acceleration artifact. Defined a falsifiable contributor-independence policy and
recorded fresh gnark and local proof-zk-recovery source observations. Added the
missing raw records for both 2026-07-11 log entries.
