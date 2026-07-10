# Public-testnet proof bridge program rebaseline

Date: 2026-07-10
Status: approved design
Target branch: `resolve-checklist-full-sweep`
Execution target: public Cardano and Midnight testnet `live-pass`

## Purpose

This document replaces the current sprint sequence as the execution plan's
design baseline. It preserves accepted protocol requirements and research from
the existing 11-sprint design, but it does not preserve sprint status that lacks
matching evidence.

The program ends only when both unmodified public testnets have accepted real,
proof-authorized destination transitions for every registered combination of
direction and proof-template family. A lab result, structural harness pass, or
project-operated source root does not satisfy that outcome.

The program id is `mcb.public-testnet-livepass.v2`. Canonical sprint ids are
`PBT-S00` through `PBT-S13`, and work packages use
`PBT-S<nn>-W<nn>`. Short names such as S0 and S13 in this document refer only to
that namespace. Existing ids such as `S02-RH-W01` keep their historical meaning.

## Decisions fixed by this design

| Subject | Decision |
| --- | --- |
| Completion | Public `live-pass` is the only successful terminal outcome. |
| Networks | Use unmodified public Cardano and Midnight testnets. |
| Predicate scope | Admit and locally conform exactly 42 Cardano and 52 Midnight predicates. |
| Public coverage | Execute every `direction x proof-template-family` combination. |
| Cardano to Midnight | Prove Cardano finality, inclusion, and predicates with the Midnight Halo2/Plonkish stack over BLS12-381. |
| Midnight to Cardano | Prove the complete Halo2/KZG decision relation and wrap it in commitment-Groth16 BSB22 over BLS12-381. |
| Setup | Use verified public setup material where compatible and a public human MPC ceremony where circuit-specific setup is required. |
| MPC implementation | Import a provenance-pinned subset of `proof-zk-recovery` and harden it in this repository. |
| MPC participation | Agents test the framework but never count as independent ceremony contributors. |
| Testnet identities | Create disposable testnet-only identities outside Git. Mainnet use is prohibited. |
| Execution | Use one program controller and a fresh bounded Grok packet for each sprint. |
| Review | Bind every closure review to a complete program snapshot rather than only a Git commit. |
| Knowledge retention | Maintain a source-backed program wiki and append-only knowledge-graph event log. |

## Current state

The committed baseline is `78bd432af06c9ef68e006ab2147da68fce29af6d`.
The branch currently has unfinished changes to `README.md`,
`docs/grok-4.5-handoff.xml`, and `runlogs/`. Sprint 0 must inventory and preserve
those changes. It may revise them through tests, but it must not treat them as
accepted merely because they already exist.

The current structural harness passes in the canonical checkout. Its closure is
reopened because the saved Codex audit is `changes-required`, council reports do
not bind the final implementation, one command record was synthesized after
execution, the telemetry regression can false-pass, detached Windows checkouts
alter evidence bytes, and review files participate in the behavioral input
hash. Sprint 1 owns those defects after Sprint 0 supplies the control plane.

Six activation blockers and eight consensus gates remain open. In particular:

- the source files needed to admit the 42 and 52 predicate catalogs are absent;
- the public Mithril signed-entity list does not currently demonstrate the
  required SCLS artifact;
- the Midnight relay does not currently supply the complete authenticated
  event-to-header-to-MMR proof relation;
- Compact, `cardano-node`, and `cardano-cli` are not qualified on this host;
- the BSB22 reference component parses proofs but does not verify them;
- no destination chain has accepted a complete bridge proof.

These are program gates, not documentation caveats.

## Program control model

### Source of truth

`ProgramPlanV1` is the machine-readable definition of sprints, packages,
dependencies, artifacts, commands, gates, and invalidation rules. Program state
is reduced from append-only events. A manifest is a derived view and may be
regenerated; it is not the history.

The event model records:

- sprint and package attempts;
- leases and lease expiry;
- command starts and terminal results;
- retries, cancellations, and resumes;
- external waits and their receipts;
- artifact publication and invalidation;
- review requests, findings, dispositions, and repeated rounds;
- deployments, submissions, confirmations, and classifier evaluations.

Allowed package states are `pending`, `ready`, `leased`, `running`,
`waiting-external`, `implementation-complete`, `under-review`, `closed`,
`blocked`, `cancelled`, and `superseded`. A sealed runlog is immutable, but
sealing does not mean success. Program completion is legal only after the public
classifier returns `live-pass` in Sprint 13.

### Attempts and recovery

Every package execution gets a unique attempt id. A new attempt references the
prior attempt and states whether it is a retry, crash recovery, superseding run,
or review remediation. A crashed process cannot rewrite the prior attempt.

A lease names its owner, acquired time, expiry, target snapshot, and allowed
paths. Recovery first reconciles running commands and repository state. It does
not assume that a missing final response means failure or success. Commands with
unknown submission status are reconciled by their canonical request or
transaction body before they may be repeated.

### Command supervisor

One supervisor executes every recorded command, including language tests, chain
tools, Grok, Codex, deployment clients, and evidence validators. It writes the
start record before launching the child, captures stdout and stderr separately,
uses a finite timeout, kills the complete process tree on expiry, waits for
termination, hashes expected outputs, and appends the terminal event.

Command records bind the attempt, executable path and hash, arguments, working
directory, allowlisted environment, source hash where applicable, expected
outputs, timestamps, timeout, exit code, stream hashes, and kill result. Raw
captures stay outside Git until the secret scanner passes.

### Repository transaction

Each mutating package uses an isolated worktree or an explicitly leased canonical
checkout. Before a push, the controller fetches the remote, compares the expected
remote SHA, checks the allowed path set, rejects unrelated changes, and uses a
normal non-force push. It verifies the remote SHA after the push. A concurrent
human or agent commit cancels the lease and forces reconciliation.

### Program snapshots

`ProgramSnapshotV1` binds:

- the implementation commit;
- the sprint packet and program-plan digest;
- stable OpenSpec inputs and active change;
- the source-receipt set;
- the program-wiki graph head and synthesis digest;
- toolchain, host, and network manifests;
- proof, setup, registry, ABI, and deployment artifacts;
- the public evidence prefix available at review time.

Proof, consensus, operator, security, and Codex readers name the same snapshot.
Any change to a field within a reader's declared scope invalidates that review.
Dispositions never alter reader-authored findings or counts.

### Specification lifecycle

Each sprint owns one OpenSpec change with requirements, design, tasks, package
ids, tests, review, and closure evidence. The program controller may generate a
packet only from a validated change and matching `ProgramPlanV1` entry. A checked
task without its declared receipt is invalid state.

After a sprint passes review, accepted requirements merge into stable OpenSpec
before a dependent sprint begins. The canonical bridge design remains exactly
25 numbered sections. Sprints update its current system state and evidence but
do not add revision narration to the canonical text. Historical decisions stay
in OpenSpec archives and the program wiki.

## Program wiki

The design record lives under `knowledge_base/program-wiki/` and follows the
three-layer pattern described in Karpathy's LLM Wiki note:

1. `raw/` contains immutable design-session records and source receipts.
2. `wiki/` contains maintained Markdown synthesis with stable page ids and
   explicit sources.
3. `AGENTS.md` defines ingest, query, lint, and graph rules.

`graph/events.jsonl` is the append-only knowledge history. It records assertions,
relationships, verification, contradiction, and supersession. `nodes.json` and
`edges.json` are deterministic materialized views. Wiki pages can change when
evidence changes, but old decisions remain recoverable through graph events, the
chronological log, raw receipts, and Git history.

Repository source hashes use canonical staged or committed Git blob bytes. They
do not hash the platform-specific working-tree representation of a text file.
Validators read the blob from the named snapshot and apply the declared hashing
profile, so Windows line-ending conversion cannot change a source identity.

The wiki stores durable decisions and evidence. It does not store private model
reasoning, raw thought streams, secrets, or transient debugging guesses.

Each sprint ingests new receipts, updates affected pages, materializes the graph,
runs lint, and appends a log entry. Lint checks schema, source hashes, broken
links, orphan pages, duplicate concepts, contradictions, stale claims,
supersession links, and materialized graph equality.

## Public roots of trust

### Cardano source facts

The minimum Cardano source knowledge for public `live-pass` is:

- exact network and genesis configuration hashes plus network magic;
- the official Mithril genesis verification key or another chain-owned,
  source-certified root accepted by the public profile;
- certificate-chain rules, AVK evolution, protocol parameters, signed-entity
  semantics, era and source-protocol fingerprints;
- the exact publicly certified SCLS descriptor and message;
- proof-authenticated source time and freshness inputs.

A project approval set cannot create the live source root. A checkpoint may
accelerate verification only when the checkpoint and all retained state are
proved from the official roots. Independent node agreement detects operational
errors but is not a consensus proof.

### Midnight source facts

The minimum Midnight source knowledge is:

- public chain-spec and genesis identity;
- the initial ordered AURA, GRANDPA, and BEEFY state required by the selected
  public profile;
- every mandatory authority transition through the accepted point;
- runtime and consensus fingerprints;
- the exact event or state fact, containing header, parent-bound MMR leaf,
  inclusion proof, and BEEFY commitment relation;
- proof-authenticated source time and freshness inputs.

Endpoint observations do not satisfy these requirements. Sprint 2 must obtain
publicly reproducible data and rejecting prototypes on the unmodified network.

### Destination and proof roots

Each deployment domain immutably binds the destination network identity,
deployed code hashes, registry activation, ABI instance, proof-suite ids,
verifier keys, KZG SRS, Groth16 transcripts, and recovery policy. Relayers and
provers are not trusted roots. Their outputs are checked against these values.

## Proof paths

### Cardano to Midnight

The Cardano finality relation verifies the selected public Mithril chain and
exact SCLS signed entity. Inclusion and predicate relations consume that anchor.
The recursive Halo2 statement binds source identity, finalized point, SCLS
state, predicate, typed result, destination context, replay value, and freshness.
The Midnight operation resolves its verifier from the registry, reconstructs
the public inputs, verifies the proof, and changes tracked source state,
application state, value state, and replay state in one Midnight transition.

Sprint 2 must first prove that an unmodified Midnight public testnet can accept
this untrusted external proof and make the complete transition. If it cannot,
the public program stops.

### Midnight to Cardano

The Midnight finality relation verifies the ordered BEEFY authority state and
commitment. The inclusion relation proves the event or state fact through its
header and MMR leaf. Predicate circuits produce the typed result. Halo2 recursion
aggregates these relations and enforces the final KZG decision.

Commitment-Groth16 BSB22 wraps the complete decision relation. The Plutus
validator reconstructs the canonical claim digest as an explicit public input,
checks the commitment-aware proof, and applies the four destination-local state
changes in one Cardano transaction. The BSB22 commitment does not replace the
public-input equality constraint.

Sprint 2 must reject an invalid final accumulator and measure the complete
Plutus boundary before circuit implementation continues.

## Reference harness on both sides

The harness exposes the same six operations for each destination: `ask`,
`resolve`, `prove`, `verify`, `submit`, and `inspect`.

The Midnight-side harness asks for a Cardano predicate. It resolves the registry
entry, gathers Cardano consensus and state witnesses, produces the registered
Halo2 proof, verifies it independently, submits it to the Midnight operation,
and inspects the confirmed Midnight state transition.

The Cardano-side harness asks for a Midnight predicate. It gathers the BEEFY,
MMR, inclusion, and predicate witnesses, produces the recursive Halo2 statement
and complete commitment-Groth16 wrapper, verifies both layers independently,
submits the BSB22 proof to the Plutus validator, and inspects the confirmed
Cardano state transition.

An `ask` request contains no authorization choice. Registry resolution selects
the source profile, statement, artifacts, verifier, destination ABI, freshness,
and replay policy. Provers, observers, and relayers remain untrusted. A harness
response is useful evidence only when the registered proof and destination
receipt validate against the same program snapshot.

## Predicate scope

Sprint 3 admits exactly 94 source-backed records. Count, uniqueness, schema, and
provenance are one gate over the same canonical bytes. No agent may invent,
rename, split, or duplicate predicates to reach the count.

Each record binds its source statement, formal relation, witness, bounded inputs,
typed output, anchor, finality and freshness policy, proof-template family,
artifacts, destination use, and required vectors. Every record passes local
round-trip, positive, negative, and cross-predicate substitution tests.

The public execution matrix is the Cartesian set of two directions and all
proof-template families authorized for that direction. A confirmed destination
state transition is required for each matrix row. A count of two transactions is
not sufficient.

## MPC lifecycle

Sprint 7 imports the minimum required code from
`CharlesHoskinson/proof-zk-recovery` branch `feat/mpc-ceremony-framework`, pinned
to reviewed Git objects with license and provenance records. Imported Preview
keys, wallets, fixed beacons, and single-operator setup artifacts are excluded.

The local framework must become circuit-generic and support real, gigabyte-scale
transcripts. It needs atomic publication, crash recovery, bounded parsing,
future-beacon commitment followed by post-contribution resolution, contributor
attestations, timeouts, object storage, and a second verifier implementation.
Agent personas exercise honest, malicious, stale, malformed, interrupted, and
replayed participant behavior. Those tests establish software behavior only.

Sprint 7 freezes the exact constraint systems, public-input order, compiler and
toolchain, proof profiles, circuit hashes, and verifier manifests. Sprint 8 then
enters `waiting-external` for independently controlled human contributions.
Human independence means separate control of entropy and operational
environments, not distinct names or agent processes.

The accepted setup binds every contribution, transcript chain, curve and
subgroup check, beacon derivation, KZG inventory, Groth16 phase, proving key, and
verifying key. Transcript-derived VK bytes must equal the harness, registry,
destination verifier, deployment payload, and conformance artifacts.

Any change to the frozen circuit, statement, compiler, setup profile, or verifier
manifest invalidates the affected setup and returns the program to Sprint 7.
Sprints 9 through 13 are mechanically unreachable until Sprint 8 closes.

## Environment and key boundary

Sprint 2 installs or qualifies the tools needed to test public feasibility.
Sprint 11 rebuilds and requalifies the final deployment environment from pinned
hashes, OCI digests, WSL identity, chain configuration, and genesis data.

Disposable testnet keys live outside the repository. Signing commands receive
opaque key handles, not secret bytes in arguments, environment variables, or
logs. The signing boundary allowlists public testnet network ids and endpoints.
Tests require rejection of every mainnet identifier. Faucet and funding packages
record public addresses, transaction ids, balances, fee reserves, and bounded
retry outcomes without recording credentials.

Public resets are observed, not induced. A reset, unknown runtime fingerprint,
or incompatible upgrade freezes the affected domain. Recovery abandons or tears
down the old off-chain deployment and creates a new deployment domain. Old-domain
proofs must reject.

## Sprint model

### Legacy mapping

The archived foundation sprint remains source history. Its catalog blocker is
owned by `PBT-S03`; the archive does not prove that blocker closed. The active
`sprint-02-reference-harness-poc` change maps to `PBT-S01`. The architecture
feasibility work originally described as Sprint 2 maps to `PBT-S02`. Later
legacy sprint descriptions supply requirements and prior analysis, but their
old numbers and completion state are not reused.

The rebaseline has 14 sprints and 100 work packages. A package is measured by
artifacts, tests, and receipts rather than elapsed time.

| Sprint | Packages | Scope | Exit gate |
| --- | ---: | --- | --- |
| PBT-S00 | 12 | Program control, runlogs, command supervision, snapshots, Git and line-ending safety, Grok/Codex lanes, program wiki, GateRosterV2 | Crash, retry, secret, drift, concurrency, and review negative suites pass in a clean smoke run. |
| PBT-S01 | 6 | Current reference-harness closure | A clean detached checkout and all fresh readers pass one program snapshot. |
| PBT-S02 | 9 | Public roots, toolchains, SCLS, BEEFY/MMR event path, execution surfaces, full-decider feasibility | Every public surface is `demonstrated`; any absent surface blocks the public program. |
| PBT-S03 | 8 | Predicate recovery and admission | Exactly 42 Cardano and 52 Midnight rows pass count, uniqueness, schema, provenance, and family mapping. |
| PBT-S04 | 6 | Query, claim, registry, artifact, replay, and failure protocols | Two codecs reproduce canonical bytes and reject mutation, substitution, and cross-domain vectors. |
| PBT-S05 | 6 | Cardano to Midnight Halo2 path | A Cardano source fact reaches the exact Midnight operation statement with complete negative vectors. |
| PBT-S06 | 7 | Midnight to Cardano Halo2 plus BSB22 Groth16 path | A Midnight fact reaches the exact Plutus statement and complete final-decider relation. |
| PBT-S07 | 8 | Production circuits, verifiers, imported MPC hardening, circuit freeze | Reproducible builds accept goldens, reject adversarial vectors, meet feasibility limits, and publish the freeze digest. |
| PBT-S08 | 6 | Human setup ceremonies, transcript verification, artifact and ABI freeze | Independent contributions verify and every deployed artifact matches the accepted transcript. |
| PBT-S09 | 7 | Reference harness, relayers, destination-local atomic settlement | Every proof-template family completes locally in both directions with restart and replay safety. |
| PBT-S10 | 7 | All-94 conformance, faults, security, and performance | All rows, families, mutations, faults, and thresholds pass against frozen artifacts. |
| PBT-S11 | 6 | Public-testnet identities, funding, environments, roots, reset and deployment readiness | Clean readiness qualification reports no capability, funding, secret, root, freshness, or deployment gap. |
| PBT-S12 | 7 | Public deployment and all-family execution | Public receipts cover every direction and family, drills pass, and the evidence snapshot is frozen. |
| PBT-S13 | 5 | Independent closure | Fresh reviews pass the frozen public snapshot and the strict classifier returns `live-pass`. |

The dependency graph is:

```text
PBT-S00 -> PBT-S01
PBT-S01 -> PBT-S02
PBT-S01 -> PBT-S03 research
PBT-S02[demonstrated] + PBT-S03 -> PBT-S04
PBT-S04 -> (PBT-S05 || PBT-S06)
PBT-S05 + PBT-S06 -> PBT-S07
PBT-S07[circuit freeze] -> PBT-S08[human ceremony]
PBT-S08 -> PBT-S09 -> PBT-S10 -> PBT-S11 -> PBT-S12 -> PBT-S13
```

PBT-S03 research may continue while PBT-S02 runs, but PBT-S04 cannot start
unless PBT-S02 is fully demonstrated. PBT-S05 and PBT-S06 may run in isolated
worktrees after PBT-S04. Their shared
interfaces and integration commit remain serialized.

## Package contract

Every work package declares:

- a stable package id and owner role;
- exact dependencies and input snapshot;
- allowed repository paths and external endpoints;
- required source receipts;
- RED tests and the failure they must observe;
- implementation artifacts;
- GREEN, regression, mutation, and clean-checkout commands;
- large-artifact and secret handling;
- output hashes and receipts;
- stop, retry, external-wait, and invalidation rules;
- required reader scopes.

A package cannot close because its implementation exists. It closes when the
controller validates its outputs and the required review snapshot passes.

## Failure and re-entry

An external capability failure records `blocked` or `waiting-external` with its
reproducer, owner, affected packages, and resume condition. It does not create a
weaker success label.

A PBT-S13 finding returns to the earliest package that owns the defect. The
controller invalidates every descendant whose snapshot includes changed input.
Circuit or setup changes repeat the affected ceremony. Deployed byte or semantic
changes repeat readiness and public execution. Review-only corrections repeat
only reviews whose declared scope changed.

## Review council

Each sprint has proof, consensus, operator, security, and Codex scopes selected
from its risk. Readers work from committed snapshots and write immutable round
artifacts. Closure requires zero Blocking, Major, and Minor findings. A finding
may be rejected only with a technical disposition that the original reader
accepts in a fresh round.

The final council also checks that:

- all public roots and setup assumptions are explicit;
- all 94 predicates and every direction-family matrix row are covered;
- destination receipts confirm state changes rather than submissions alone;
- runlogs, wiki events, source receipts, and evidence inventories are complete;
- no lab, endpoint-observation, agent-simulated ceremony, or mainnet claim enters
  the public classifier.

## Non-claims

This design is not a bridge deployment. It does not establish that public SCLS,
the Midnight event relation, either destination verifier surface, the missing
predicate catalogs, or the human ceremony is available. It defines the tests
that must establish those facts and the exact places where the program stops if
they fail.

Even after public `live-pass`, the result is a proof of concept. Production work
still requires production ceremonies, external security audits, stable upstream
formats, production operations, and governance approval.
