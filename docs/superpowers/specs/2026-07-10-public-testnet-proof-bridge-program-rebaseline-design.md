# Public-testnet proof bridge program rebaseline

Date: 2026-07-10
Status: approved only as the exact candidate blob named by the later blob-bound review
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
| Review | Bind every advisory review to a complete program snapshot rather than only a Git commit. |
| Knowledge retention | Maintain a source-backed program wiki and append-only knowledge-graph event log. |

## Current state

The historical harness closure target is
`78bd432af06c9ef68e006ab2147da68fce29af6d`. Commit
`3db35fa9a7e7257359f5def4bb216c60356643b8` contains the initial design-session
baseline, not these revised bytes. The operative revision is the exact Git blob
and candidate commit named by
`docs/superpowers/reviews/2026-07-12-public-testnet-proof-bridge-remediation-review.md`,
which is committed after the reviewed candidate. Neither historical value is
the Sprint 0 execution base. Before W01, an operator records the intended
planning baseline in an external `ProgramBaselinePrecommitmentV1`; W01 verifies
that record instead of self-designating the current HEAD.

At design approval, the canonical worktree carried unfinished changes to
`README.md`, `docs/grok-4.5-handoff.xml`, and `runlogs/`. Sprint 0 inventories
every then-current porcelain entry, preserves its exact bytes, and assigns its
reconciliation owner before adoption. Existing bytes are not accepted merely
because they predate the controller.

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

One fenced controller broker owns global event order outside package clones.
It runs under a dedicated service SID and owns ACL-protected journal and
canonical Git roots. Package and model children run under stripped restricted
tokens that can modify only their assigned full clone and scratch roots. They
cannot write, delete, rename, take ownership of, or change the DACL on controller
or canonical Git storage. A private capability channel is their only
package-to-controller path. The broker writes
each event as a complete immutable object, flushes it, atomically publishes it
with durable rename semantics, and verifies the final bytes. Accepted
per-attempt segments enter Git through a serialized control transaction.
Parallel clones never append the same file or assign a global sequence.

The broker runs as a native SCM-compatible service, not as `pwsh.exe` registered
directly with the service manager. `ControllerIdentityV1` binds its
service-account-protected non-exportable ECDSA P-256 key and public trust anchor.
Each worker receives a private inherited channel and a single-attempt capability
bound to package, lease, fence, snapshot, methods, expiry, and monotonic nonces.
Service restart preserves the identity and durable head but invalidates worker
channels.

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

Sprint 0 publishes a `GateRosterV2` with `roster_stage=base`. It contains no
invented proof-family rows and is permanently ineligible for public execution,
activation, or classification. PBT-S04-W06 publishes a separate
`roster_stage=family-complete` roster whose first `base_entry_count` entries are
the ordered, byte-identical base entries. It preserves the base digest, binds the
admitted direction-family matrix root, and appends only admitted family rows.
PBT-S12-W01 binds both artifacts in `DeploymentIntentV1` before deployment.
PBT-S12-W02 produces observations, ABI instances, root contexts, activation and
deployment receipts under that intent, then freezes `RunIntentV1` before
execution preflight. The PBT-S13 classifier verifies the
base prefix and evaluates every base and family gate. Roster entries carry only
`initial_state=unresolved`. Append-only `GateEvaluationV1` records carry current
state, evidence, expiry, supersession, and invalidation. Base-prefix entries use
one logical identity under the base roster origin and have one effective current
evaluation; their history may contain superseded or invalidated evaluations.
Only appended family entries use the family-complete roster origin. Each definition fixes
`activation_required` and its earliest activation stage. `ActivationDecisionV1`
consumes only the canonical predeployment subset; it cannot require deployment,
execution, public-receipt, or classifier evidence before those
events occur. PBT-S12-W07 produces nonterminal
classifier-readiness evidence. The terminal classifier receipt is not an input
gate.

### Attempts and recovery

Every package execution gets a unique attempt id. A new attempt references the
prior attempt and states whether it is a retry, crash recovery, superseding run,
or review remediation. A crashed process cannot rewrite the prior attempt.

A lease names its owner, acquired time, expiry, target snapshot, and allowed
paths. Recovery first reconciles running commands and repository state. It does
not assume that a missing final response means failure or success. Commands with
unknown submission status are reconciled by their canonical request or
transaction body before they may be repeated.

Every lease carries a monotonic fencing epoch. Long work renews its lease. The
controller checks the current epoch at command start and result, artifact
publication, signing, external submission, repository integration, and push.
Expiry or renewal loss stops the complete host, WSL-distro, or container
execution boundary and blocks a stale writer.

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

Each mutating package uses an independent full clone under the restricted worker
boundary. Before a push, the controller records a supervised fetch, compares the
expected remote SHA, checks the allowed path set, rejects unrelated changes, and
uses a normal non-force push. It records another fetch after the push and verifies
the remote SHA. A concurrent human or agent commit cancels the lease and forces
reconciliation.

The empty broker repository is seeded once after W16 from an operator-created
bundle that contains the committed planning baseline through the W16 entrypoint
commit. The authenticated administrative channel streams bytes and a complete
object manifest; the service never opens the user's repository. The broker
verifies lineage, refs, remote, object inventory, and a signed initialization
receipt before generating a worker bundle. Every later worker pack enters a
bounded no-execute quarantine with strict object, delta, path, platform-name,
allowlist, and resource checks before atomic import.

In implementation, mutating workers use full per-attempt clones with independent
Git directories and object databases. Only the broker can import a verified tree
into canonical Git. HTTPS publication uses a qualified noninteractive credential
provider under the service identity. Git receives an opaque allowlisted handle,
never a credential in argv, environment, streams, records, or receipts.

### Program snapshots

`ProgramSnapshotV1` binds:

- the implementation commit;
- the sprint packet and program-plan digest;
- stable OpenSpec inputs and active change;
- the source-receipt set;
- the program-wiki graph head and synthesis digest;
- toolchain, host, and network manifests;
- controller identity and, for publication, the qualified public credential-handle receipt;
- proof, setup, registry, ABI, and deployment artifacts;
- the public evidence prefix available at review time.

Proof, consensus, operator, security, and Codex readers name the same snapshot.
Any change to a field within a reader's declared scope invalidates that review.
Dispositions never alter reader-authored findings or counts.

Reader outputs are advisory quality evidence and never a closure input. Closure rests on deterministic contract suites, signed operator records, externally reproducible source and chain receipts, and the remote-confirmation bundle. A model count cannot change package state.

### Specification lifecycle

Each sprint owns one OpenSpec change with requirements, design, tasks, package
ids, tests, review, and closure evidence. The program controller may generate a
bounded discovery packet from immutable external-input requirements before those
inputs resolve. It may generate a resolved implementation packet only after the
discovery outputs bind qualified tools, networks, sources, and receipts. Both
packet types require a validated change and matching `ProgramPlanV1` entry. A
checked task without its declared receipt is invalid state.

Accepted requirements merge into stable OpenSpec and pass strict validation in
the committed review candidate. The canonical bridge design remains exactly 25
numbered sections. Sprints update its current system state and evidence but do
not add revision narration to the canonical text. Historical decisions stay in
OpenSpec archives and the program wiki.

A frozen implementation snapshot cannot contain its own reader outputs.
`ClosureEnvelopeV1` binds that immutable snapshot to optional later advisory review,
disposition, archive, final-event, deterministic raw wiki closure receipt,
source-node and graph materialization updates, wiki-log, inventory, redaction receipts,
seal receipts, and, only in PBT-S13, classifier receipts. Its typed delta enumerates allowed object digests, event and
state transitions, source digests, wiki predicates, and inventory additions. It
excludes its own fixed path and blob. The validator checks that file separately
and requires the full tree delta to equal the inventory plus exactly
`program/closures/<sprint-id>/closure-envelope-v1.json`. The envelope contains no
own-blob, final-tree, or final-commit digest. After review, OpenSpec
relocation into the archive is byte-identical. A relocation-only archive
candidate is committed and validated before the archive receipt exists; the
controller's `FinalizeClosure` action then materializes the typed attestations,
validates the complete non-self-referential delta, commits and integrates the
final closure tree, and returns distinct closure-source and canonical-integration
commits, their byte-identical tree, external envelope digest, and integration
receipt. `Publish` accepts only the returned context and targets the integration
commit.
No receipt binds a tree that contains itself. Any code, stable requirement,
design, registry, proof artifact, ABI, or deployment change creates a new
snapshot and repeats the affected deterministic checks. Advisory readers may be
rerun for quality review, but their findings and counts do not authorize successor
readiness. Successor sprints require a valid closure
envelope, OpenSpec archive receipt, and a separately schema-checked immutable
`RemoteConfirmationBundleV1`. Its signed receipt binds the envelope, remote,
branch, fence, immutable public credential-handle receipt, review-probe receipt,
new pre-fetch and pre-sign probe receipts, expected SHA, pushed SHA, observed
SHA, pre-push fetch, ordered one or two push attempts, post-push fetch command
records, every raw stream, and the snapshot-bound
`ControllerIdentityV1`. The bundle contains those exact records and stream
bytes, their manifests, all three probe receipts, the immutable public
credential-handle receipt, identity, and a
noncircular payload manifest. It is completed and verified in a same-volume
temporary directory, published by one non-replacing durable rename, then
verified again before the event. A lost push response is reconciled by a
read-only fetch and never causes a blind retry. Before each package lease, the
controller imports every missing bundle in that package's cumulative transitive
`[closed]` predecessor set and rejects missing or unapproved imports. The
in-tree envelope does not attempt to contain its own blob, final tree, or commit
id.

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
- the initial ordered authority state required by one selected public finality
  profile;
- every mandatory authority transition through the accepted point;
- runtime and consensus fingerprints;
- the exact event or state fact, containing header, parent-bound MMR leaf,
  inclusion proof, and BEEFY commitment relation;
- proof-authenticated source time and freshness inputs.

Endpoint observations do not satisfy these requirements. Sprint 2 must obtain
publicly reproducible data and rejecting prototypes on the unmodified network.
The selected profile states whether BEEFY certifies GRANDPA-finalized state and
whether AURA or GRANDPA facts are proved relations or official profile
assumptions. AURA authorship, GRANDPA finality, and BEEFY commitments are not
interchangeable roots.

### Destination and proof roots

Each deployment domain derives from the domain-neutral root set. Domain-bound
registry-activation, artifact-authorization, ABI-instance, and deployment records
then immutably bind destination network identity, deployed code hashes,
proof-suite ids, verifier keys, KZG SRS, Groth16 transcripts, and recovery policy.
Relayers and provers are not trusted roots. Their outputs are checked against
these values.

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

The Midnight finality relation verifies the selected public profile, ordered
BEEFY authority state, and commitment. The inclusion relation proves the event
or state fact through its runtime, header, parent-bound MMR leaf, MMR root, and
commitment. Predicate circuits produce the typed result. Halo2 recursion
aggregates these relations and produces the canonical transcript and
accumulator plus a native reference decision.

Commitment-Groth16 BSB22 recomputes the complete KZG decision relation in R1CS.
It does not wrap an externally supplied accept bit. The Plutus
validator reconstructs the canonical claim digest as an explicit public input,
checks the commitment-aware proof, and applies the four destination-local state
changes in one Cardano transaction. The BSB22 commitment does not replace the
public-input equality constraint.

The frozen KZG binding profile states whether verifier material is circuit
constant or authenticated input and fixes its degree, encoding, transcript,
input slots, and equality constraints. Constant material must be qualified
before circuit freeze. Later material changes invalidate the circuit and setup.

Sprint 2 must reject an invalid final accumulator and measure the complete
Plutus boundary before circuit implementation continues.

For both destinations, every rejection stage records `NO_CHANGE` for tracked
source state, application state, value state, and replay state. Parsing,
registry, policy, freshness, replay, proof, and settlement failures cannot alter
one owner while preserving the others. An absent value is represented as the
typed state `ValueStateV1=Absent(reason)`.

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

Sprint 3 recovers exactly 94 source-backed records. W01 through W05 apply count,
uniqueness, source-row schema, and provenance as one gate over the same canonical
bytes. Each immutable recovered row contains its source statement, formal
relation, witness, bounded inputs, typed output, source-semantic anchor, raw
vectors, and provenance. No agent may invent, rename, split, or duplicate
predicates to reach the count.

W06 through W08 create separate admission records keyed to the recovered catalog
digest and the demonstrated PBT-S02 public profiles. The joined admitted view,
not the recovered catalog bytes, binds finality and freshness policy,
proof-template family, artifact slots, destination use, and conformance vectors.
Every admitted record passes local round-trip, positive, negative, and
cross-predicate substitution tests. Admission never rewrites source recovery.

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
contributor attestations, timeouts, object storage, and a second verifier
implementation. New or update ceremonies also need transcript-specific future
beacon commitments followed by post-contribution resolution.
`CeremonyBeaconScheduleV1` is keyed by setup kind, stable transcript id,
SRS-profile id, phase, and circuit id or an explicit no-circuit sentinel. Each
unique tuple for a new KZG transcript, Groth16 Phase 1, or per-circuit Phase 2 has
its own precommitment, close point, domain, future resolution, sealed head,
counted contributor set, acknowledgements, and public anchor.

For `new-or-update` mode, the frozen policy selects a beacon from a public,
independently operated allowlist. A qualifying source publishes authenticated,
timestamped outputs, remains unpredictable until a resolution point after the
contribution close, has a stable public archive, and has an independently
implemented verification rule. The schedule binds the source class, instance,
resolution height or time, output verification key, domain separator, and
minimum close-to-resolution delay. If no allowed source meets those properties,
the ceremony remains `waiting-external`. Historical qualification never adds a
new beacon to old bytes.

A sealed historical KZG SRS follows a separate `historical-qualified` path.
`HistoricalCeremonyQualificationV1` verifies the ceremony's original
precommitment, contribution chronology, post-contribution beacon, public anchors,
transcript algebra, sealed head, and exact final bytes. The bridge never attaches
a new beacon to historical bytes. If the original evidence is unavailable and a
destination requires those constant-bound bytes, the program blocks or
rebaselines. Agent personas exercise both modes, including honest, malicious,
stale, malformed, interrupted, cross-beacon, cross-circuit,
same-transcript/different-SRS, duplicate-tuple, replayed, and retroactive-beacon
behavior. Those tests establish software behavior only.

KZG qualification is algebraic, not metadata-only. Two independent
implementations replay every contribution under the selected ceremony protocol,
verify its PoK or equivalent contribution proof, check the update relation over
all declared G1 and G2 powers, preserve degree and prefix, prove cross-group
consistency, and match the final bytes to the sealed head. Altered, omitted,
duplicated, reordered, inconsistent, truncated, or cross-transcript powers
reject.

Sprint 7 freezes the exact constraint systems, public-input order, compiler and
toolchain, proof profiles, circuit hashes, and verifier manifests. Sprint 8 then
enters `waiting-external` for independently controlled human contributions.
Human independence means separate control of entropy and operational
environments, not distinct names or agent processes.

`ContributorIndependencePolicyV1` is the gated deliverable of `PBT-S08-W01`,
before enrollment or contribution keys exist. It freezes the minimum human and
independent-organization counts, allowed identity-anchor classes, adjudicators,
appeal path, privacy-preserving public commitments, and these failure
conditions:

- each counted human has a unique public identity or organizational attestation and signs enrollment with a unique contribution key;
- no counted pair shares a recovery authority, administrator, coordinator-controlled credential, entropy seed, or declared operational environment;
- environment receipts expose enough committed attributes to detect the same host, virtual-machine image, hardware attestation, network administration domain, or credential custodian without publishing secrets;
- organizational and control-domain diversity meet the frozen numeric thresholds, not merely the participant-name count;
- every contributor independently confirms the final transcript head and the inclusion of that contributor's accepted update;
- agents, scripted personas, coordinator keys, unverifiable identities, duplicate anchors, contradictory declarations, missing evidence, or an unresolved conflict of control fail the policy and cannot be waived by the coordinator.

Two named adjudicators from different control domains evaluate the evidence. A
disagreement or unresolved Sybil indicator records `waiting-external`; it never
reduces the minimum count. Agent sessions may exercise every acceptance and
failure condition, but their receipts are marked `simulation` and cannot enter
the counted contributor set. Any policy or threshold change after enrollment
invalidates enrollment and restarts `PBT-S08-W01`.

The accepted setup binds every contribution, transcript chain, curve and
subgroup check, beacon derivation, KZG inventory, Groth16 phase, proving key, and
verifying key. In the pinned commitment-aware gnark suite, Phase 1 verifies
`tau`, `alpha`, and `beta` updates. Each circuit's Phase 2 verifies `delta` and
one `sigma` update and PoK per commitment, derives every `GSigmaNeg`, and fixes
`gamma` to the standard BLS12-381 G2 generator. Every counted human publishes a
signed contribution receipt and acknowledges inclusion in each final sealed
transcript head they joined. Every accepted head has its own predeclared public
timestamp or anchor. A coordinator-produced valid tail that omits a counted
contribution fails the participation policy.

Transcript-derived VK bytes must bind to and satisfy the immutable registry slot
constraints and equal the harness, destination verifier, deployment payload, and
conformance copies.
Sprint 8 publishes `RegistryActivationV1`, domain-bound artifact authorization,
deployment roots and domain, ABI templates, and deployment recipes. Concrete ABI
instances remain absent until S12 deployment observations. Sprint 8 does not
mutate semantic registry bytes or template roots.

Any change to the frozen circuit, statement, compiler, setup profile, or verifier
manifest invalidates the affected setup and returns the program to Sprint 7.
Sprints 9 through 13 are mechanically unreachable until Sprint 8 closes.

PBT-S09 replaces the current stable conformance wording that requires a receipt
to bind the run-evidence manifest that later indexes it. Destination receipts
bind the immutable run intent. An immutable evidence-head record is created only
after its indexed receipts and binds its predecessor head plus those receipt
digests. The terminal classifier binds the final head. The PBT-S09 OpenSpec delta
must update both receipt and evidence-index requirements together and add cycle
and self-digest rejection vectors before the stable specification changes.

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
semantic runtime change, finality change, official-root change, or incompatible
upgrade returns to PBT-S02 and invalidates dependent circuits, setup, deployment,
and public receipts. Only endpoint drift or a fingerprint transition already
authorized by the frozen runtime policy may re-enter at deployment or execution.
Recovery abandons or tears down the old off-chain deployment and creates a new
deployment domain. Old-domain proofs must reject.

## Sprint model

### Legacy mapping

The archived foundation sprint remains source history. Its catalog blocker is
owned by `PBT-S03`; the archive does not prove that blocker closed. The active
`sprint-02-reference-harness-poc` change maps to `PBT-S01`. The architecture
feasibility work originally described as Sprint 2 maps to `PBT-S02`. Later
legacy sprint descriptions supply requirements and prior analysis, but their
old numbers and completion state are not reused.

The rebaseline has 14 sprints and 106 work packages. A package is measured by
artifacts, tests, and receipts rather than elapsed time.

| Sprint | Packages | Scope | Exit gate |
| --- | ---: | --- | --- |
| PBT-S00 | 18 | Program control, runlogs, command supervision, snapshots, Git and line-ending safety, Grok/Codex lanes, program wiki, GateRosterV2 | Crash, retry, secret, drift, concurrency, and review negative suites pass in a clean smoke run. |
| PBT-S01 | 6 | Current reference-harness closure | A clean detached checkout reproduces the committed evidence and passes every deterministic closure contract for one program snapshot. |
| PBT-S02 | 9 | Public roots, toolchains, SCLS, BEEFY/MMR event path, execution surfaces, full-decider feasibility | Every public surface is `demonstrated`; any absent surface blocks the public program. |
| PBT-S03 | 8 | Predicate recovery and admission | Exactly 42 Cardano and 52 Midnight rows pass count, uniqueness, schema, provenance, and family mapping. |
| PBT-S04 | 6 | Query, claim, registry, artifact, replay, and failure protocols | Two codecs reproduce canonical bytes and reject mutation, substitution, and cross-domain vectors. |
| PBT-S05 | 6 | Cardano to Midnight Halo2 path | A Cardano source fact reaches the exact Midnight operation statement with complete negative vectors. |
| PBT-S06 | 7 | Midnight to Cardano Halo2 plus BSB22 Groth16 path | A Midnight fact reaches the exact Plutus statement and complete final-decider relation. |
| PBT-S07 | 8 | Production circuits, verifiers, imported MPC hardening, circuit freeze | Reproducible builds accept goldens, reject adversarial vectors, meet feasibility limits, and publish the freeze digest. |
| PBT-S08 | 6 | Human setup ceremonies, transcript verification, registry activation, and artifact/deployment-input freeze | Independent contributions verify and every authorized artifact matches the accepted transcript. |
| PBT-S09 | 7 | Reference harness, relayers, destination-local atomic settlement | Every authorized direction-family row completes locally with restart and replay safety. |
| PBT-S10 | 7 | All-94 conformance, faults, security, and performance | All rows, families, mutations, faults, and thresholds pass against frozen artifacts. |
| PBT-S11 | 6 | Public-testnet identities, funding, environments, roots, reset and deployment readiness | Clean readiness qualification reports no capability, funding, secret, root, freshness, or deployment gap. |
| PBT-S12 | 7 | Public deployment and all-family execution | Public receipts cover every direction and family, drills pass, and the evidence snapshot is frozen. |
| PBT-S13 | 5 | Independent closure | Deterministic closure checks and public receipts pass on the frozen snapshot; advisory reviews do not feed the classifier. |

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
full clones after PBT-S04. Their shared
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

A package cannot close because its implementation exists. It closes only when
the controller validates its deterministic outputs and all required external
receipts against the frozen snapshot. Advisory review artifacts may identify
work but cannot authorize the state transition.

## Failure and re-entry

<!-- re-entry-contract:v2:start -->
| Drift class | Required re-entry |
| --- | --- |
| network identity, official-root, finality, or runtime-semantic drift | `PBT-S02`; invalidate dependent circuits, setup, deployment, and public receipts |
| catalog or proof-template-family drift | `PBT-S03` |
| claim, encoding, registry, or validation-semantics drift | `PBT-S04` |
| circuit, verifier, setup-interface, or ceremony-verifier drift | `PBT-S07` |
| human policy, contribution, beacon, or transcript drift under an unchanged frozen interface | `PBT-S08` |
| endpoint-only drift under unchanged authenticated network and runtime identities | `PBT-S11` |
| fingerprint transition already authorized by the frozen runtime policy | the affected `PBT-S12` package |
| deployed-copy or ABI-observation drift under unchanged authorized bytes | `PBT-S11`, then repeat affected public execution in `PBT-S12` |
<!-- re-entry-contract:v2:end -->

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
artifacts. Their reports are advisory and their counts are not closure fields.
Accepted technical findings become failing deterministic contracts before a
fix. Rejected findings receive a technical disposition without requiring the
model that authored the finding to approve it.

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
