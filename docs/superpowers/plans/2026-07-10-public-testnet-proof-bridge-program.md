# Public Testnet Proof Bridge Program Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a proof of concept in which unmodified public Cardano and Midnight testnets accept proof-authorized destination state transitions for every registered direction and proof-template family.

**Architecture:** A native service broker owns an ACL-protected fenced journal and canonical Git integration root, and reduces immutable event segments against a canonical 106-package plan with 231 explicit dependency edges. Restricted workers run in full per-attempt clones with independent Git metadata and private lease-bound capabilities. The broker validates and imports accepted clone trees. Each sprint has a validated OpenSpec change and a snapshot-bound execution packet. Cardano facts reach Midnight through a recursive Halo2/Plonkish proof over BLS12-381. Midnight facts reach Cardano through the complete Halo2/KZG decision relation wrapped in commitment-Groth16 BSB22 over BLS12-381. Public roots, setup artifacts, registries, ABIs, deployments, reviews, runlogs, and wiki state are bound into immutable program snapshots.

**Tech Stack:** PowerShell 7, OpenSpec 1.5.0, Git and GitHub Actions, Rust and Halo2, Go, Python with Scrapling, Midnight Compact and proof-server tooling, Cardano node and CLI tooling, Plutus/Aiken where qualified, Mithril, Substrate BEEFY/MMR primitives, Groth16 BSB22, JSON Schema draft-07, deterministic CBOR, Windows 11 with WSL2 and Docker.

## Global Constraints

- The program id is `mcb.public-testnet-livepass.v2`; package ids are `PBT-S<nn>-W<nn>`.
- Only a public-testnet `live-pass` returned by `PBT-S13` is successful completion. Structural, simulated, local, and degraded results remain non-terminal.
- Use unmodified public Cardano and Midnight testnets. A project-operated signer set, checkpoint, endpoint quorum, or relay cannot replace either chain's official source root.
- Admit exactly 42 Cardano and 52 Midnight predicates from source-backed catalogs. Never invent, rename, split, or duplicate rows to reach the count.
- Public execution covers every authorized `direction x proof-template-family` row, not one transaction per direction.
- Cardano to Midnight uses the full registered Halo2 statement. Midnight to Cardano proves the final Halo2/KZG decision and wraps it in commitment-Groth16 BSB22; the commitment does not replace public-input equality.
- Destination authorization changes tracked source state, application state, value state, and replay state atomically in one local destination transition.
- Every rejected destination path emits authenticated `NO_CHANGE` evidence for all four predecessor states. An absent value uses the typed state `ValueStateV1=Absent(reason)` rather than an omitted field.
- Relayers, provers, observers, agents, and project approval sets are not roots of trust.
- Agents may harden and attack the ceremony framework, but only independently controlled humans count as ceremony contributors.
- Testnet signing keys remain outside Git. Mainnet identifiers, keys, endpoints, and submissions are rejected.
- Public web collection uses Scrapling and stores source receipts. Load-bearing claims use official primary sources or exact upstream Git objects.
- Each work package follows red-green-refactor, declares allowed paths, uses the universal command supervisor, and emits immutable attempt and evidence records.
- Each sprint owns one OpenSpec change. A package id appears in `tasks.md`, and its normative behavior appears in at least one requirement scenario.
- Every advisory review binds one `ProgramSnapshotV1`. A scoped input change invalidates the affected review artifact and any test or disposition derived from it.
- Re-entry follows the one contract below. A drift class cannot be reinterpreted as a cheaper class merely because authorized artifact bytes are unchanged.

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
- The canonical bridge design remains exactly 25 numbered sections. Current state belongs there; revision history belongs in OpenSpec, runlogs, Git, and the program wiki.
- Do not begin a package until each dependency reaches its declared required state. A same-sprint implementation dependency may require `implementation-complete`; every cross-sprint dependency requires reviewed state `closed`. Record an unavailable external surface as `waiting-external` or `blocked`; do not weaken the target.

---

## Execution Contract

The package register below is the complete scope baseline. It does not guess implementation APIs that depend on unresolved public-chain feasibility. Before a sprint starts, the controller generates a code-level sprint plan from:

1. the package rows in this register;
2. the validated sprint OpenSpec change;
3. the closed predecessor snapshot;
4. admitted source receipts and exact upstream object ids;
5. qualified toolchain and public-network manifests.

The controller uses two packet stages. A bounded discovery or prequalification
packet may be generated from the register, closed predecessor, immutable
external-input requirements, authority and endpoint allowlists, verification
commands, stop rules, and unavailable-input policy. It contains no resolved
binding and may run only packages explicitly marked for discovery. A resolved
implementation packet also binds the receipts, toolchain, and network
manifests produced by those discovery packages. It must name exact files,
interfaces, RED tests, GREEN commands, evidence paths, timeouts, allowed
endpoints, secret rules, stop conditions, and commit boundaries.

`PBT-S00` is specified now in the companion plan because it has no unresolved
chain interface. `PBT-S02-W01` runs alone in its prequalification packet; its
schema-valid `implementation-complete` output permits the resolved
`PBT-S02-W02` through `PBT-S02-W09` packet.
The `PBT-S03` recovery packet is a discovery packet whose W01 source receipts
are outputs, not prerequisites. Any later packet that guesses a resolved tool,
network, source, or artifact binding before its producing package reaches the
declared required state is invalid.

`PBT-S03` has two bounded packets under one OpenSpec change. The recovery packet
covers W01-W05 after `PBT-S01` closes and may only recover source rows, schemas,
and provenance. The admission packet covers W06-W08 after `PBT-S02-W09` closes
and binds the recovered rows to demonstrated public profiles. The recovery
packet cannot make authoritative proof-family, destination-surface, or
feasibility claims. Source documents may carry those labels only as
non-authoritative annotations in a separate recovery namespace. W06 and W07
must rederive and admit them under the demonstrated public profiles before they
enter any canonical catalog or matrix.

`ProgramPlanV1` stores every dependency as a full package id plus required state.
External inputs use two separate collections. Immutable requirements state the
authority class, expected object or discovery query when known, endpoint
allowlist, timeout, verification command id, and unavailable-input policy.
Per-attempt resolved bindings state the observed snapshot and source receipt and
must be empty before discovery. A resolved packet cannot consume a requirement
without its verified binding. A register-to-plan contract reads this Markdown
table and requires exact agreement with the machine plan; the implementer cannot
add or weaken an edge.

Every package writes its immutable evidence beneath `program/evidence/<package-id>/<attempt-id>/`. Large proof, setup, node, or transcript bytes may live in declared external object storage; Git stores a content-addressed manifest, retrieval receipt, and independent verification result.

The controller journal is not stored in a package clone. Each event is first
written as a complete immutable object under the fenced external controller
root, flushed, and atomically renamed on the same volume. The controller assigns
the global sequence and fencing epoch. After it accepts a package result, it
serializes that attempt's immutable segment and derived state into a dedicated
control transaction. Parallel package clones never append the same file or
choose a global sequence. A losing or stale package result remains an immutable
attempt but cannot enter canonical state.

Before a successor sprint becomes ready, the current sprint must sync accepted
delta requirements into stable OpenSpec, validate stable and active OpenSpec
strictly in the reviewed candidate, relocate the reviewed active change
byte-for-byte into the archive, validate that relocation with the archive
validator, validate stable OpenSpec again, and publish an archive-digest receipt.
The frozen implementation snapshot and any later advisory review artifacts are joined by
`ClosureEnvelopeV1`. The envelope permits only optional review requests and results,
technical dispositions, deterministic OpenSpec archive relocation, final event
segments and derived state, a deterministic raw wiki closure receipt, its source
node and graph materialization updates, wiki log events, inventories, redaction receipts, seal receipts, and,
only for `PBT-S13-W05`, the deterministic `live-pass` classifier receipt.
It rejects any behavioral code, stable requirement, design, registry, artifact,
or deployment change. Any rejected diff creates a new snapshot and repeats the
affected deterministic checks. Advisory readers may be rerun for quality review,
but their findings and counts cannot authorize closure. The envelope's typed delta manifest enumerates every permitted
closure path and object digest except its own fixed path,
`program/closures/<sprint-id>/closure-envelope-v1.json`. The validator checks
that file separately against its schema and semantic rules, then requires the
complete tree delta to equal the manifest entries plus that one fixed path. The
envelope contains no digest of its own blob and no final closure tree or commit
id. The controller writes a separate immutable remote-confirmation receipt after
push. Successor readiness depends on the verified envelope, archive receipt, and
external remote-confirmation receipt, not the unreviewed branch head.

`RemoteConfirmationBundleV1` is published with `CreateNew` and the controller's
durable atomic-write protocol at
`<controller-root>/remote-confirmations/<program-id>/<sprint-id>/<envelope-sha256>/<receipt-id>/`.
It contains command directories for `pre-fetch`, ordered `push-0001` and
optional recovery `push-0002`, and `post-fetch`. Each directory contains
`record.json`, exact `stdout.bin`, exact `stderr.bin`, and
`stream-manifest.json`. It also contains `receipt.json`, the public
`controller-identity.json`, immutable public `credential-handle.json`,
`credential-probes/review.json`, `credential-probes/pre-fetch.json`,
`credential-probes/pre-sign.json`, and
`bundle-manifest.json`. The manifest inventories and hashes every payload member
except itself and the receipt. The signed receipt binds schema version, receipt
id, creation time, the program and sprint ids, closure-envelope digest, remote name and normalized
URL, branch, fencing epoch, credential-handle receipt digest, snapshot-bound
review-probe digest, ordered review, pre-fetch, and pre-sign probe digests, expected pre-push
SHA, pushed closure SHA, observed post-fetch SHA, all three command-record ids
and digests in the normal case or all four when recovery retries once, every
stream digest and byte count,
controller-identity digest, bundle-manifest digest, signature algorithm,
signature, and receipt digest. The broker signs canonical deterministic JSON
with `signature` and `receipt_sha256` omitted, using ECDSA P-256 with SHA-256 and
fixed-width P1363 encoding. Signature input omits `signature` and
`receipt_sha256`; the receipt digest is computed after inserting the fixed-width
signature and omits only `receipt_sha256`. The snapshot binds the trusted
controller public-key, immutable public credential-handle receipt, reduced
credential-lifecycle head, and review-probe receipt digests.

The broker completes the bundle in a unique sibling directory on the same
volume, flushes and reopens every file, secret-scans the command records and raw
streams, signs the receipt, verifies the complete schema and manifest, flushes
the directory, and publishes it with one non-replacing write-through rename.
It reopens the published directory and verifies its exact membership before
emitting `remote-confirmed`. A crash leaves either no final directory or one
complete final directory. Push response loss enters `unknown-submission`; a
read-only fetch decides whether to finish from the immutable captures, perform
one policy-authorized recorded retry while the remote remains at the expected
old SHA, or cancel on any other SHA. A retry adds its command record and streams
after the first record's `unknown-submission` state. Recovery never blindly
repeats a push.

`verify-remote-confirmation.ps1` verifies every bundle object, the pre-fetch,
ordered one or two push attempts, post-fetch, all raw streams and manifests,
signed bytes, identity and snapshot trust anchors, the immutable public
credential-handle receipt, all three purpose-bound probes, their review-snapshot
binding, remote observations, fence, envelope, and manifest digest. The broker
then emits `remote-confirmed`. Before each package lease, the controller derives
the cumulative transitive set of cross-sprint dependencies required at
`[closed]` by that package's current packet. It copies every required but not yet imported exact bundle into
`program/remote-confirmations/<predecessor-sprint>/<receipt-id>/`, then emits one
`remote-confirmation-imported` event per predecessor. Imports are monotonic. The
reducer requires byte equality and set equality with the package's cumulative
required predecessor set, with no missing or unapproved bundle. This
allows staged discovery such as PBT-S03-W01 through W05 to run after S01 while
requiring the S02 bundle before later S03 admission work. It also makes join
sprints import both direct branches before their first dependent lease.

The dependency column uses full package ids. `[implementation-complete]` permits
same-sprint implementation to continue before the sprint review. `[closed]`
requires a reviewed package and is mandatory across sprint boundaries.

## Dependency Graph

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

`PBT-S03` research may overlap `PBT-S02`, but admission cannot close until the public source profile is demonstrated. `PBT-S05` and `PBT-S06` may run in isolated full clones after `PBT-S04`; shared protocol changes and integration remain serialized.

## Package Register

### PBT-S00: Program Control Plane

OpenSpec change: `openspec/changes/pbt-s00-program-control-plane/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S00-W01` | Preserve baseline and assign reconciliation ownership | None; external input: committed planning baseline | `.gitattributes`; `program/baselines/pbt-s00-start.json`; ownership entries for `README.md`, `docs/grok-4.5-handoff.xml`, and `runlogs/` | A clean isolated worktree reproduces byte-hashed inputs; every pre-existing porcelain entry is inventoried before adoption; cached paths equal the package allowlist before commit. |
| `PBT-S00-W02` | Define `ProgramPlanV1` and publish the canonical plan | `PBT-S00-W01` `[implementation-complete]` | `program/schemas/program-plan-v1.schema.json`; `program/plans/public-testnet-livepass-v2.json` | Schema, id, count, dependency-state, cycle, and artifact-path tests prove 14 sprints and 106 unique packages. |
| `PBT-S00-W03` | Define Append-Only Events and Deterministic State Reduction | `PBT-S00-W02` `[implementation-complete]` | event, segment, and state schemas; durable event module; reducer and journal export | Event-transition, canonical-byte, durable-publication, replay, head-mismatch, and reducer-equivalence tests pass without privileged repository or installer behavior. |
| `PBT-S00-W13` | Implement Privileged Repository and Credential Methods | `PBT-S00-W03` `[implementation-complete]` | request, identity, and capability schemas; native service protocol, repository, credential, and publication source; method schemas and tests | Restricted callers cannot escape method allowlists, roots, fences, credential handles, or publication policies; service code contains no mutable plugin boundary. |
| `PBT-S00-W14` | Reproduce, Qualify, and Provision the Controller Build | `PBT-S00-W13` `[implementation-complete]` | locked native build; two build receipts; qualification file; installer and service receipt | Two unelevated clean-clone builds reproduce; an operator-carried qualification hash authenticates exact installer inputs; elevation never compiles or loads mutable build code. |
| `PBT-S00-W04` | Implement leases, attempts, retry, crash recovery, and resume | `PBT-S00-W03` `[implementation-complete]`; `PBT-S00-W14` `[implementation-complete]` | attempt, renewal, release, and fencing functions; recovery fixtures | Expiry during a command, renewal loss, clock jump, late writer, interrupted command, unknown submission, retry, remediation, and resume suites pass. |
| `PBT-S00-W05` | Implement the Universal Command Supervisor | `PBT-S00-W04` `[implementation-complete]`; `PBT-S00-W14` `[implementation-complete]` | command module; process-boundary adapters; `CommandRecordV2` | Start-before-launch, byte-preserving streams, finite timeout, complete process-tree cleanup, required-output, executable-hash, and environment-allowlist tests pass. |
| `PBT-S00-W15` | Implement Transaction and Pack Quarantine | `PBT-S00-W05` `[implementation-complete]`; `PBT-S00-W13` `[implementation-complete]` | independent-clone transaction module; pack validator; quarantine receipt | Traversal, NTFS reserved-name, ADS, case-fold, symlink, object, path-allowlist, stale-fence, and incomplete-transaction fixtures reject before canonical import. |
| `PBT-S00-W16` | Close Bootstrap and Publish the Package Entrypoint | `PBT-S00-W01` `[implementation-complete]`; `PBT-S00-W02` `[implementation-complete]`; `PBT-S00-W03` `[implementation-complete]`; `PBT-S00-W04` `[implementation-complete]`; `PBT-S00-W05` `[implementation-complete]`; `PBT-S00-W13` `[implementation-complete]`; `PBT-S00-W14` `[implementation-complete]`; `PBT-S00-W15` `[implementation-complete]` | authenticated canonical seed; initialization receipt; nine bootstrap receipts; package entrypoint and manifests | The broker verifies the committed bootstrap lineage before one-time seeding; detached replay reproduces each package receipt; bootstrap import closes permanently; direct later child execution rejects. |
| `PBT-S00-W06` | Validate runlogs, inventories, and redaction receipts | `PBT-S00-W16` `[implementation-complete]` | runlog validator; scanner and ruleset; repaired runlog schemas | Cross-file negative fixtures reject traversal, omissions, hash drift, duplicate roles, false threads, forbidden fields, secrets, and incomplete terminal state. |
| `PBT-S00-W07` | Define `ProgramSnapshotV1` and invalidation | `PBT-S00-W02` `[implementation-complete]`; `PBT-S00-W03` `[implementation-complete]`; `PBT-S00-W06` `[implementation-complete]` | snapshot schema, builder, scope diff, invalidation reducer | Stable snapshots reproduce; every root, semantic, artifact, setup, deployment, wiki, host, and public-evidence drift returns to its exact owning package. |
| `PBT-S00-W08` | Harden repository integration and remote publication | `PBT-S00-W04` `[implementation-complete]`; `PBT-S00-W07` `[implementation-complete]`; `PBT-S00-W13` `[implementation-complete]`; `PBT-S00-W15` `[implementation-complete]` | concurrency, remote lease, qualified opaque Git credential handle, signed `RemoteConfirmationBundleV1`, and atomic publication module | Tests reject dirty, out-of-scope, stale-fence, stale-remote, force-push, concurrent, prompted, revoked-credential, partial-bundle, blind-repush, incomplete-predecessor, and secret-leak cases. Signed command records and exact streams, full-bundle import, and remote SHA reproduction pass. |
| `PBT-S00-W09` | Compile bounded Grok sprint packets and environment receipts | `PBT-S00-W02` `[implementation-complete]`; `PBT-S00-W05` `[implementation-complete]`; `PBT-S00-W07` `[implementation-complete]`; `PBT-S00-W16` `[implementation-complete]` | XML packet template, compiler, environment probe | Packet schema, prompt hash, permission, model, exact snapshot, allowed paths, package-entrypoint routing, and no-secret environment tests pass. |
| `PBT-S00-W10` | Run advisory isolated Codex audits and persona councils | `PBT-S00-W05` `[implementation-complete]`; `PBT-S00-W07` `[implementation-complete]`; `PBT-S00-W09` `[implementation-complete]`; `PBT-S00-W16` `[implementation-complete]` | supervised audit and reader runners; review schemas | Full-clone runner tests prove actor provenance, separate scratch, stream capture, thread extraction, timeout cleanup, immutable rounds, and one-target equality. Reader outputs are advisory quality evidence and never a closure input. Accepted findings create tests and scoped invalidation; counts cannot close a package. |
| `PBT-S00-W11` | Materialize and lint the program wiki graph | `PBT-S00-W02` `[implementation-complete]`; `PBT-S00-W03` `[implementation-complete]`; `PBT-S00-W07` `[implementation-complete]` | wiki module, validator, reports | Metadata, source blob hashes, event order, links, orphans, contradictions, supersession, and materialized-view equality pass on the committed wiki. |
| `PBT-S00-W12` | Publish and Reproduce the Base GateRosterV2 | `PBT-S00-W01` `[implementation-complete]`; `PBT-S00-W02` `[implementation-complete]`; `PBT-S00-W03` `[implementation-complete]`; `PBT-S00-W07` `[implementation-complete]`; `PBT-S00-W11` `[implementation-complete]` | roster/evaluation schemas; `program/schemas/classifier-readiness-v1.schema.json`; base JSON/CBOR roster; Rust/Go reproduction | The immutable base roster starts unresolved, is execution/classification-ineligible, binds every accepted evidence schema, and reproduces byte-identically in two implementations. |
| `PBT-S00-W17` | Integrate CI and Run the Control-Plane Smoke Test | `PBT-S00-W08` `[implementation-complete]`; `PBT-S00-W09` `[implementation-complete]`; `PBT-S00-W10` `[implementation-complete]`; `PBT-S00-W11` `[implementation-complete]`; `PBT-S00-W12` `[implementation-complete]`; `PBT-S00-W16` `[implementation-complete]` | CI workflow; control verifier; smoke runlog; README reconciliation | Portable and privileged suites pass one immutable candidate; the smoke program covers initialize through remote publication and leaves public activation false. |
| `PBT-S00-W18` | Close Sprint 0 and Confirm Remote Publication | `PBT-S00-W06` `[implementation-complete]`; `PBT-S00-W07` `[implementation-complete]`; `PBT-S00-W08` `[implementation-complete]`; `PBT-S00-W09` `[implementation-complete]`; `PBT-S00-W10` `[implementation-complete]`; `PBT-S00-W11` `[implementation-complete]`; `PBT-S00-W12` `[implementation-complete]`; `PBT-S00-W17` `[implementation-complete]` | OpenSpec archive; closure envelope; redaction and seal receipts; remote confirmation bundle | Deterministic contract suites and externally reproducible receipts close the sprint. Advisory reader artifacts may be attached but cannot satisfy closure. A separate post-push receipt confirms the remote SHA before successor readiness. |

### PBT-S01: Reference Harness Closure

OpenSpec change: `openspec/changes/pbt-s01-reference-harness-closure/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S01-W01` | Import predecessor confirmation and freeze deterministic inputs | `PBT-S00-W18` `[closed]` | byte-identical PBT-S00 `RemoteConfirmationBundleV1`; `.gitattributes`; `reference/manifests/conformance-inputs-v2.json` | The first control event imports and verifies the signed bundle, immutable credential handle, review/pre-fetch/pre-sign probe receipts, pre-fetch, push, and post-fetch records and streams, and controller identity before the package lease. Detached Windows and WSL checkouts then reproduce all committed evidence hashes with no undeclared residue. |
| `PBT-S01-W02` | Repair telemetry-order regression | `PBT-S01-W01` `[implementation-complete]` | `scripts/tests/openspec-telemetry.contract.ps1`; verifier environment setup | Removing, delaying, or partially restoring either opt-out fails; the intact verifier passes in isolated config and data roots. |
| `PBT-S01-W03` | Make independent CBOR execution provenance complete | `PBT-S01-W01` `[implementation-complete]` | tracked CBOR checker; command provenance assertions | Every evidence command record is emitted by its execution wrapper and binds the invoked source bytes, executable, argv, cwd, environment, and result. |
| `PBT-S01-W04` | Integrate supervisor, verifier, and isolated audit execution | `PBT-S01-W02` `[implementation-complete]`; `PBT-S01-W03` `[implementation-complete]` | supervised verifier path; full-clone audit adapter | Late failure, timeout, missing output, and read-only TEMP fixtures fail without changing evidence; full isolated verification passes. |
| `PBT-S01-W05` | Run a fresh snapshot-bound reader round | `PBT-S01-W04` `[implementation-complete]` | immutable proof, consensus, operator, security, and Codex artifacts | Every reader names one `ProgramSnapshotV1`. Reader outputs are advisory quality evidence and never a closure input. Accepted findings create tests, a new target, and repeated affected scopes. |
| `PBT-S01-W06` | Refresh evidence and close legacy and PBT-S01 specification lifecycles | `PBT-S01-W05` `[implementation-complete]` | refreshed generation; separate legacy disposition; stable-spec sync; archived legacy and PBT-S01 changes; archive receipts | Update and default verification are byte-identical. The legacy `sprint-02-reference-harness-poc` is archived without being renamed into PBT-S01; accepted PBT-S01 deltas sync separately; strict OpenSpec and the closure envelope pass; public activation remains false. |

### PBT-S02: Public Feasibility

OpenSpec change: `openspec/changes/pbt-s02-public-feasibility/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S02-W01` | Qualify host, chain tools, and exact public networks | `PBT-S01-W06` `[closed]` | `environments/public-feasibility.lock.json`; host and network receipts | Pinned tools execute against named network identities. Missing Compact, proof server, Cardano node/CLI, or incompatible runtime records `blocked`. |
| `PBT-S02-W02` | Prove Cardano identity, Mithril root, and AVK chain | `PBT-S02-W01` `[implementation-complete]` | `feasibility/cardano/mithril-root/`; rejecting prototype | Official genesis and Mithril roots reproduce a valid certificate chain; wrong network, AVK transition, signer set, or signature rejects. |
| `PBT-S02-W03` | Establish public SCLS signed-entity availability | `PBT-S02-W02` `[implementation-complete]` | `feasibility/cardano/scls-profile.json`; source receipts | An exact public SCLS descriptor and certified message are retrieved and verified. Absence or a project-created substitute stops the program. |
| `PBT-S02-W04` | Select and prove the Midnight finality profile | `PBT-S02-W01` `[implementation-complete]` | `feasibility/midnight/midnight-finality-profile-v1.json`; chain-spec and transition receipts | The profile states whether BEEFY certifies GRANDPA-finalized state and whether AURA/GRANDPA are proved relations or official assumptions. Genesis, authority ordering, mandatory handoffs, set transitions, block numbers, commitment encoding, and runtime fingerprints reproduce. |
| `PBT-S02-W05` | Prove the Midnight event-to-BEEFY relation | `PBT-S02-W04` `[implementation-complete]` | `feasibility/midnight/event-path/`; positive and rejection vectors | A real fact binds event or state, runtime fingerprint, header, parent rule, MMR payload and root, inclusion proof, BEEFY authority membership/quorum, set transition, and commitment. Endpoint observation alone fails. |
| `PBT-S02-W06` | Prove complete Halo2/KZG decider wrapping and SRS-interface feasibility | `PBT-S02-W01` `[implementation-complete]` | `feasibility/proofs/halo2-kzg-bsb22/`; `KzgBindingProfileV1`; benchmark | A pinned native verifier and circuit agree after transcript exhaustion with authenticated VK/SRS inputs. The R1CS reaches and rejects a false final-pairing witness and altered claim digest within target bounds. Constant-bound SRS bytes must already be qualified; otherwise the public topology blocks or requires rebaseline. |
| `PBT-S02-W07` | Measure Cardano BSB22 and local atomic transition | `PBT-S02-W01` `[implementation-complete]`; `PBT-S02-W06` `[implementation-complete]` | `feasibility/cardano/destination/`; Preview receipts | The exact Plutus boundary fits measured limits. Success changes four owner states; every parse, policy, freshness, replay, and proof rejection emits four-state `NO_CHANGE` evidence. |
| `PBT-S02-W08` | Demonstrate Midnight external Halo2 verification and atomic transition | `PBT-S02-W01` `[implementation-complete]`; `PBT-S02-W06` `[implementation-complete]` | `feasibility/midnight/destination/`; public receipts | An unmodified public Midnight testnet accepts the exact `KzgBindingProfileV1`, verifies an untrusted external proof, and changes four states atomically. Every rejection preserves all four states. Missing operation or SRS support stops the program. |
| `PBT-S02-W09` | Decide finality, freshness, performance, and program feasibility | `PBT-S02-W02` `[implementation-complete]`; `PBT-S02-W03` `[implementation-complete]`; `PBT-S02-W04` `[implementation-complete]`; `PBT-S02-W05` `[implementation-complete]`; `PBT-S02-W06` `[implementation-complete]`; `PBT-S02-W07` `[implementation-complete]`; `PBT-S02-W08` `[implementation-complete]` | `program/decisions/feasibility-decision-v1.json`; OpenSpec review | Every required surface is `demonstrated` with rejection and cost evidence. Any `assumed`, `unknown`, or `unavailable` surface makes the decision `blocked`. |

### PBT-S03: Predicate Recovery and Admission

OpenSpec change: `openspec/changes/pbt-s03-predicate-admission/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S03-W01` | Recover authoritative catalog sources and receipts | `PBT-S01-W06` `[closed]` | `predicate-catalogs/sources/`; Scrapling and Git receipts | Each candidate row traces to an official document or exact upstream object. Missing catalogs remain blocked without reconstructed filler. |
| `PBT-S03-W02` | Define source-row reconstruction | `PBT-S03-W01` `[implementation-complete]` | `predicate-catalogs/predicate-record-v1.schema.json`; recovery spec | Tests reject missing provenance, ambiguous source semantics, unbounded witness descriptions, or untyped outputs. Public-profile compatibility is outside the recovery packet and belongs to W06-W08. |
| `PBT-S03-W03` | Publish the canonical 42-row Cardano catalog | `PBT-S03-W02` `[implementation-complete]` | `predicate-catalogs/cardano-v1.json`; separate source-annotation record | Exactly 42 unique source-backed ids validate with complete relation, witness, source-semantic anchor or ledger-object, provenance, and raw-vector fields. Recovered family or destination labels remain non-authoritative annotations outside the canonical catalog. |
| `PBT-S03-W04` | Publish the canonical 52-row Midnight catalog | `PBT-S03-W02` `[implementation-complete]` | `predicate-catalogs/midnight-v1.json`; separate source-annotation record | Exactly 52 unique source-backed ids validate under the same recovery contract; no recovered family or destination label is treated as admitted. |
| `PBT-S03-W05` | Validate the recovered all-94 corpus | `PBT-S03-W03` `[implementation-complete]`; `PBT-S03-W04` `[implementation-complete]` | independent catalog validator; count and provenance receipt | Two implementations agree on canonical bytes, counts, ids, source hashes, and schema; any duplicate or unverifiable row fails the whole corpus. |
| `PBT-S03-W06` | Admit relations into proof-template families | `PBT-S03-W05` `[implementation-complete]`; `PBT-S02-W09` `[closed]` | `predicate-catalogs/proof-template-families-v1.json` | Every row has one justified family binding and bounded formal inputs under the demonstrated public profiles. Only a source reconstruction or provenance defect established without profile facts returns to W02; a correctly recovered relation unsupported by the public profiles remains byte-identical and blocks admission. |
| `PBT-S03-W07` | Build destination-use and vector matrices | `PBT-S03-W06` `[implementation-complete]` | `predicate-catalogs/destination-use-v1.json`; vector manifest | Every row maps to a concrete destination use plus positive, negative, round-trip, and substitution vector ids. |
| `PBT-S03-W08` | Run independent catalog council and activate the corpus | `PBT-S03-W05` `[implementation-complete]`; `PBT-S03-W06` `[implementation-complete]`; `PBT-S03-W07` `[implementation-complete]`; `PBT-S02-W09` `[closed]` | `predicate-catalogs/admission-receipt-v1.json`; reader artifacts | Deterministic admission contracts close the corpus. Readers inspect the same corpus digest and demonstrated public profiles; accepted findings invalidate affected evidence, but counts do not activate the corpus. |

### PBT-S04: Shared Protocols and Registry

OpenSpec change: `openspec/changes/pbt-s04-shared-protocol/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S04-W01` | Specify query, resolution, claim envelope, and result schemas | `PBT-S02-W09` `[closed]`; `PBT-S03-W08` `[closed]` | `protocol/query-v1.*`; `protocol/claim-envelope-v1.*` | Schema and state-machine tests reject authorization choices in `ask`, unresolved profiles, missing typed results, and domain ambiguity. |
| `PBT-S04-W02` | Specify relation composition and field binding | `PBT-S04-W01` `[implementation-complete]` | `protocol/relation-binding-v1.md`; machine matrix | Every source, finality, inclusion, predicate, freshness, replay, destination, and result field has one producer and all equality constraints are explicit. |
| `PBT-S04-W03` | Define domain, root, artifact, registry, and ABI DAG | `PBT-S04-W01` `[implementation-complete]`; `PBT-S04-W02` `[implementation-complete]` | immutable semantic and artifact templates with logical authorization slots; registry schemas | Cycles, mutable semantic or template roots, mismatched suite/SRS/VK/ABI, and old-domain artifacts reject. Later setup may fill only typed authorization, ABI-instance, and deployment-root slots. |
| `PBT-S04-W04` | Define validation order, errors, freshness, and replay | `PBT-S04-W01` `[implementation-complete]`; `PBT-S04-W02` `[implementation-complete]`; `PBT-S04-W03` `[implementation-complete]` | `protocol/validation-profile-v1.json`; error registry | Deterministic tests prove fail-closed order, authenticated source time, expiration, duplicate handling, concurrency, and reset behavior. |
| `PBT-S04-W05` | Implement two codecs and canonical golden vectors | `PBT-S04-W01` `[implementation-complete]`; `PBT-S04-W02` `[implementation-complete]`; `PBT-S04-W03` `[implementation-complete]`; `PBT-S04-W04` `[implementation-complete]` | Rust and Go codecs; `protocol/vectors/shared-v1/` | Byte equality passes; field, ordering, type, domain, artifact, and cross-predicate mutations reject independently. |
| `PBT-S04-W06` | Populate the registry and family-complete `GateRosterV2` | `PBT-S04-W03` `[implementation-complete]`; `PBT-S04-W04` `[implementation-complete]`; `PBT-S04-W05` `[implementation-complete]` | `protocol/registry-v1.json`; `protocol/gate-roster-v2-family-complete.json`; gate review | All 94 predicates and every authorized direction-family row resolve to exact immutable template and slot ids plus future producer and evidence-schema bindings. Concrete circuit, VK, SRS, transcript, ABI-instance, and deployment bytes resolve only through later `ArtifactAuthorizationV1` and deployment records. The roster has `roster_stage=family-complete`, preserves `base_roster_sha256` and `base_entry_count`, contains every ordered base entry as a byte-identical prefix, binds the admitted matrix root, and appends only admitted family rows. Omitted, altered, reordered, or invented rows reject; the advisory council can create findings but cannot activate a row. |

### PBT-S05: Cardano to Midnight Proof Path

OpenSpec change: `openspec/changes/pbt-s05-cardano-to-midnight/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S05-W01` | Implement Mithril base and certificate-step circuits | `PBT-S04-W06` `[closed]` | `circuits/cardano-to-midnight/mithril/` | Valid official-chain vectors pass; wrong genesis, AVK, signer registration, quorum, message, or signature rejects. |
| `PBT-S05-W02` | Implement SCLS membership and non-membership | `PBT-S05-W01` `[implementation-complete]` | `circuits/cardano-to-midnight/scls/` | Exact public descriptor vectors pass; altered keys, branches, roots, signed entity, and absence semantics reject. |
| `PBT-S05-W03` | Build recursive Cardano Halo2 state | `PBT-S05-W01` `[implementation-complete]`; `PBT-S05-W02` `[implementation-complete]` | `circuits/cardano-to-midnight/recursion/` | Recursion preserves network, certificate continuity, finalized point, authenticated time, and deployment-domain bindings across base and step proofs. |
| `PBT-S05-W04` | Implement Cardano predicate-family circuits | `PBT-S05-W03` `[implementation-complete]` | `circuits/cardano-to-midnight/predicates/` | Every admitted Cardano family passes its complete vector set and rejects cross-predicate and cross-family substitution. |
| `PBT-S05-W05` | Implement Midnight verifier operation and tracked state | `PBT-S05-W03` `[implementation-complete]`; `PBT-S05-W04` `[implementation-complete]` | `contracts/midnight/cardano-proof-verifier/` | Fixtures reconstruct inputs, resolve artifacts, verify proofs, and atomically update four states. Every parser, registry, policy, freshness, replay, and proof rejection emits four-state `NO_CHANGE`. |
| `PBT-S05-W06` | Publish vectors, benchmarks, and path review | `PBT-S05-W01` `[implementation-complete]`; `PBT-S05-W02` `[implementation-complete]`; `PBT-S05-W03` `[implementation-complete]`; `PBT-S05-W04` `[implementation-complete]`; `PBT-S05-W05` `[implementation-complete]` | `program/evidence/PBT-S05-W06/<attempt-id>/summary.json`; review round | Two independent verifiers agree, target constraints and latency pass, and all negative vectors reject without state change. Advisory readers may create remediation findings. A sprint-level view, if emitted, is derived from package evidence. |

### PBT-S06: Midnight to Cardano Proof Path

OpenSpec change: `openspec/changes/pbt-s06-midnight-to-cardano/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S06-W01` | Implement the selected BEEFY and finality authority state | `PBT-S04-W06` `[closed]` | `circuits/midnight-to-cardano/beefy/` | Selected S02 profile vectors pass for exact authority order, membership, quorum, set id, mandatory handoff, block number, commitment encoding, and any proved GRANDPA relation; skipped or conflated transitions reject. |
| `PBT-S06-W02` | Implement Midnight event and MMR inclusion | `PBT-S06-W01` `[implementation-complete]` | `circuits/midnight-to-cardano/event-mmr/` | Real event-runtime-header-parent-leaf-root-commitment vectors pass; any broken payload, fingerprint, parent rule, branch, MMR root, or finalized commitment rejects. |
| `PBT-S06-W03` | Implement Midnight predicate-family circuits | `PBT-S06-W02` `[implementation-complete]` | `circuits/midnight-to-cardano/predicates/` | Every admitted Midnight family passes its vector set and rejects cross-predicate and cross-family substitution. |
| `PBT-S06-W04` | Aggregate Halo2 relations and produce the canonical accumulator | `PBT-S06-W01` `[implementation-complete]`; `PBT-S06-W02` `[implementation-complete]`; `PBT-S06-W03` `[implementation-complete]` | `circuits/midnight-to-cardano/recursion/` | Recursion binds every source relation, canonical transcript, accumulator, claim digest, and native reference decision. It does not expose an unconstrained final accept bit. |
| `PBT-S06-W05` | Recompute the complete KZG decision in commitment-Groth16 BSB22 | `PBT-S06-W04` `[implementation-complete]` | `circuits/midnight-to-cardano/bsb22-wrapper/` | Real R1CS performs transcript preparation, accumulation, and final KZG equation, constrains acceptance to one, binds committed-wire indices and blinding ownership, uses `PublicAndCommitmentCommitted`, and enforces `pub == claim_digest`. Every false pairing or altered input rejects. |
| `PBT-S06-W06` | Implement Plutus verifier and four-owner state transition | `PBT-S06-W05` `[implementation-complete]` | `validators/cardano/midnight-proof-verifier/` | Local transaction validates exact proof bytes and atomically updates tracked source, application, value, and replay owners within measured budgets. Every rejection stage proves all four predecessor states unchanged. |
| `PBT-S06-W07` | Publish vectors, benchmarks, and path review | `PBT-S06-W01` `[implementation-complete]`; `PBT-S06-W02` `[implementation-complete]`; `PBT-S06-W03` `[implementation-complete]`; `PBT-S06-W04` `[implementation-complete]`; `PBT-S06-W05` `[implementation-complete]`; `PBT-S06-W06` `[implementation-complete]` | `program/evidence/PBT-S06-W07/<attempt-id>/summary.json`; review round | Independent native, R1CS, off-chain, and destination checks agree, target limits pass, and mutations reject without state change. Advisory readers may create remediation findings. A sprint-level view, if emitted, is derived from package evidence. |

### PBT-S07: Production Circuits, Verifiers, and Ceremony Hardening

OpenSpec change: `openspec/changes/pbt-s07-circuit-freeze/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S07-W01` | Import the reviewed MPC subset with provenance and license | `PBT-S05-W06` `[closed]`; `PBT-S06-W07` `[closed]` | `ceremony/vendor/proof-zk-recovery/`; import manifest | Every imported byte maps to a pinned upstream object and compatible license; keys, wallets, fixed beacons, and single-operator artifacts are absent. |
| `PBT-S07-W02` | Replace demo inputs with circuit-generic real R1CS | `PBT-S07-W01` `[implementation-complete]`; `PBT-S06-W07` `[closed]` | `ceremony/src/r1cs/`; circuit adapters | Adapters consume the exact production constraint systems and public-input order; demo or mock setup cannot enter an authorized manifest. |
| `PBT-S07-W03` | Add transcript streaming and atomic persistence | `PBT-S07-W01` `[implementation-complete]` | `ceremony/src/transcript/`; object-store adapter | Gigabyte-scale, truncation, crash, retry, bounded-parse, atomic-publish, and recovery tests pass without whole-file memory assumptions. |
| `PBT-S07-W04` | Implement ceremony schedules and historical transcript qualification | `PBT-S07-W01` `[implementation-complete]`; `PBT-S07-W03` `[implementation-complete]` | `ceremony/src/beacon/`; `CeremonyBeaconScheduleV1`; `HistoricalCeremonyQualificationV1`; protocol spec | `new-or-update` mode uses a schedule keyed by `(setup_kind, transcript_id, srs_profile_id, phase, circuit_id_or_no_circuit)` and gives every new KZG transcript, Groth16 Phase 1, and per-circuit Phase 2 its own precommitment, future resolution point, domain separation, close point, sealed head, and public anchor. `historical-qualified` mode never invents a new schedule for sealed bytes. It verifies the original precommitment, contribution chronology, post-contribution beacon, transcript algebra, sealed final bytes, and public anchors. Missing original evidence rejects. Duplicate tuples, collisions, cross-phase or cross-circuit reuse, early revelation, timeout, replay, and equivocation reject. |
| `PBT-S07-W05` | Implement coordinator, contributor, identity, and attestation flows | `PBT-S07-W03` `[implementation-complete]`; `PBT-S07-W04` `[implementation-complete]` | `ceremony/src/protocol/`; participant CLI | Authenticated contributions bind setup kind, stable transcript id, SRS-profile id, phase, circuit id or sentinel, predecessor, entropy control, environment attestation, transcript hash, public receipt, and that transcript's final-head acknowledgement without exposing entropy. |
| `PBT-S07-W06` | Add independent verifier and adversarial agent simulations | `PBT-S07-W02` `[implementation-complete]`; `PBT-S07-W03` `[implementation-complete]`; `PBT-S07-W04` `[implementation-complete]`; `PBT-S07-W05` `[implementation-complete]` | `ceremony/verifier-independent/`; simulation corpus | Honest, malicious, stale, malformed, interrupted, omitted, reordered, replayed, cross-beacon, cross-circuit, and same-transcript/different-SRS agents produce expected results. Independent KZG verification replays every contribution under the selected ceremony protocol, checks its PoK or equivalent contribution proof, all declared G1/G2 powers and cross-group consistency, degree and prefix preservation, and the final sealed SRS head. It rejects one altered, omitted, duplicated, reordered, identity, off-curve, non-subgroup, inconsistent-power, or cross-transcript element. Independent Groth16 verification checks Phase 1 `tau/alpha/beta` proofs and Phase 2 `delta` plus every commitment `sigma` proof and derived `GSigmaNeg`; agents are never counted as human contributors. |
| `PBT-S07-W07` | Build production circuits and verifiers reproducibly | `PBT-S05-W06` `[closed]`; `PBT-S06-W07` `[closed]`; `PBT-S07-W02` `[implementation-complete]` | build locks; circuit, KZG-binding, and verifier manifests | Two clean builders reproduce constraints, bytecode, VK template, ABI, vectors, and the S02 `KzgBindingProfileV1`. Constant-bound SRS bytes must already match the qualified S02 material; authenticated-input profiles fix slots and equality constraints. |
| `PBT-S07-W08` | Freeze circuits and run security review | `PBT-S07-W06` `[implementation-complete]`; `PBT-S07-W07` `[implementation-complete]` | `ceremony/freeze/circuit-freeze-v1.json`; review round | Exact constraints, public-input order, committed-wire indices, blinding ownership, compiler, tools, KZG binding, profiles, artifacts, and invalidation rules freeze at one digest. Advisory readers may create remediation findings but cannot freeze the digest. |

### PBT-S08: Human Setup Ceremonies

OpenSpec change: `openspec/changes/pbt-s08-human-setup/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S08-W01` | Validate frozen inputs, ceremony modes, schedules, and human enrollment | `PBT-S07-W08` `[closed]` | `ceremony/runs/policy-v1.json`; `ContributorIndependencePolicyV1`; `CeremonyBeaconScheduleV1`; historical-qualification references; enrollment receipts | Before enrollment, freeze numeric human and organization thresholds, allowed identity anchors, distinct recovery and administration domains, environment-diversity checks, two cross-domain adjudicators, and explicit failure conditions. Duplicate anchors, shared control, missing evidence, agent contributors, or an unresolved Sybil indicator record `waiting-external` and cannot be waived. Every setup tuple selects exactly one ceremony mode; historical qualification creates no retroactive beacon. |
| `PBT-S08-W02` | Qualify KZG SRS or run compatible public ceremonies | `PBT-S08-W01` `[implementation-complete]` | `ceremony/artifacts/kzg/`; `HistoricalCeremonyQualificationV1` or new transcript receipts; verification reports | Each required SRS uses exactly one frozen mode. A historical qualification verifies the original precommitment and chronology, original beacon and anchors, all contributions and algebraic updates, sealed head, and exact final bytes without changing the SRS. A new or update ceremony uses its scheduled future beacon. In both modes, two independent implementations verify contribution proofs, every declared G1/G2 power, cross-group and prefix consistency, curve, degree, encoding, license, and final byte equality. Altered powers and transcript substitution reject. A constant-bound profile accepts only the exact S02/S07 bytes; if their historical evidence is unavailable, the program blocks or rebaselines instead of updating those bytes. Agents never substitute for required humans. |
| `PBT-S08-W03` | Run Groth16 Phase 1 with human contributors | `PBT-S08-W01` `[implementation-complete]` | Phase 1 transcript; signed receipts and independently published attestations | The Phase 1-specific contribution chain, `tau/alpha/beta` PoKs, subgroup checks, entropy attestations, future beacon, sealed head, and independent replay pass. Interruption resumes without rewriting history; each counted contributor retains a signed receipt. |
| `PBT-S08-W04` | Run Groth16 Phase 2 for every distinct circuit | `PBT-S08-W02` `[implementation-complete]`; `PBT-S08-W03` `[implementation-complete]` | per-circuit Phase 2 transcripts, receipts, and manifests | Every frozen circuit uses its own scheduled future beacon and sealed head. Replay verifies `delta` and every commitment-specific `sigma` update and PoK, the derived `GSigmaNeg`, and the fixed-generator `gamma` rule; circuit, predecessor, contributor-policy, beacon, or transcript-head mismatch rejects. |
| `PBT-S08-W05` | Replay transcripts, acknowledge every final head, and derive keys | `PBT-S08-W02` `[implementation-complete]`; `PBT-S08-W03` `[implementation-complete]`; `PBT-S08-W04` `[implementation-complete]` | two verifier reports per transcript; final-head acknowledgements and public anchors; key manifests | Full replay includes every KZG update and contribution proof, every Groth16 Phase 1 and Phase 2 update and PoK, curve and subgroup checks, beacon and key derivation, final inclusion acknowledgement from every counted human for each transcript they joined, independently timestamped sealed heads, and byte equality. A valid tail that omits a counted contribution, changes a power, or substitutes another transcript's head rejects. |
| `PBT-S08-W06` | Activate the registry, authorize setup artifacts, and freeze deployment inputs | `PBT-S08-W05` `[implementation-complete]` | `DeploymentRootSetV1`; deployment domain; `RegistryActivationV1`; domain-bound `ArtifactAuthorizationV1` records for every required slot; ABI templates and deployment recipes | After deriving the root-set digest and domain, the package freezes `RegistryActivationV1` from the exact semantic template and activated entry set, then uses its digest in every artifact authorization. Each required circuit, architecture, VK, proving-key hash, KZG SRS, Groth16 setup, transcript, contribution, beacon, sealed-head, anchor, and independent-verification slot has one authorization that satisfies the immutable S04 constraints. Authorized bytes equal the reproducible harness, conformance, and deployment-payload copies. Concrete deployment observations, destination instance ids, ABI instances, root contexts, activation decisions, and deployment receipts do not exist until S12-W02. Semantic registry bytes and template roots remain unchanged; advisory review cannot authorize artifacts. |

### PBT-S09: Reference Harness, Relayers, and Atomic Settlement

OpenSpec change: `openspec/changes/pbt-s09-reference-bridge/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S09-W01` | Implement symmetric `ask` and `resolve` CLI/API | `PBT-S08-W06` `[closed]` | `harness/cli/`; `harness/api/` | Both destinations expose the same six-operation contract and resolve exact registry entries without caller-selected authorization. |
| `PBT-S09-W02` | Implement offline and live chain adapters | `PBT-S09-W01` `[implementation-complete]` | `harness/adapters/`; fixture corpus | Offline fixtures and live reads normalize to the same typed witness model; live transport remains untrusted and uses Scrapling where web retrieval applies. |
| `PBT-S09-W03` | Orchestrate proofs and registry dispatch | `PBT-S09-W01` `[implementation-complete]`; `PBT-S09-W02` `[implementation-complete]` | `harness/orchestrator/` | Each query dispatches to the authorized direction-family artifacts, independently verifies output, and rejects stale or substituted registry material. |
| `PBT-S09-W04` | Implement idempotent Cardano and Midnight clients | `PBT-S09-W01` `[implementation-complete]` | `harness/clients/cardano/`; `harness/clients/midnight/`; receipt and evidence-head schemas | Canonical request identities reconcile unknown submissions, resume confirmations, avoid duplicate state changes, and expose destination receipts. The PBT-S09 OpenSpec delta explicitly replaces the older stable rule that made each receipt bind its run-evidence manifest. Receipts bind `RunIntentV1`; each later immutable `RunEvidenceManifestV1` head binds its predecessor head and newly indexed receipt digests; the classifier binds the terminal head. Cycle and self-digest vectors reject. |
| `PBT-S09-W05` | Implement destination-local four-owner settlement | `PBT-S09-W03` `[implementation-complete]`; `PBT-S09-W04` `[implementation-complete]` | settlement modules and state-machine tests | Both sides atomically update source, application, value, and replay state; every rejection preserves typed predecessor states; partial authorization and cross-chain atomicity claims reject. |
| `PBT-S09-W06` | Implement relayer persistence, health, and data availability | `PBT-S09-W02` `[implementation-complete]`; `PBT-S09-W03` `[implementation-complete]`; `PBT-S09-W04` `[implementation-complete]`; `PBT-S09-W05` `[implementation-complete]` | `relayer/`; recovery and availability tests | Restart, reorg, stale root, reset, missing witness, corrupt store, and duplicate work tests pass without trusting the relayer. |
| `PBT-S09-W07` | Execute every direction-family row locally | `PBT-S09-W03` `[implementation-complete]`; `PBT-S09-W04` `[implementation-complete]`; `PBT-S09-W05` `[implementation-complete]`; `PBT-S09-W06` `[implementation-complete]` | `program/evidence/PBT-S09-W07/<attempt-id>/local-matrix.json`; review | Every authorized matrix row reaches a confirmed local destination state change with positive and four-state `NO_CHANGE` negative receipts. Advisory readers may create remediation findings. A sprint-level matrix, if emitted, is a derived index. |

### PBT-S10: Conformance, Security, and Performance

OpenSpec change: `openspec/changes/pbt-s10-conformance-security/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S10-W01` | Run positive and negative coverage for all 94 predicates | `PBT-S09-W07` `[closed]` | `conformance/all-94/coverage.json` | Every row passes round-trip and positive tests and its declared negative vectors; no unexecuted or waived row remains. |
| `PBT-S10-W02` | Run substitution, encoding, domain, and artifact mutations | `PBT-S10-W01` `[implementation-complete]` | mutation corpus and results | Cross-predicate, cross-family, cross-domain, wrong-root, wrong-VK, wrong-SRS, ABI, order, width, and type mutations all reject with four-state `NO_CHANGE`. |
| `PBT-S10-W03` | Run system fault injection | `PBT-S09-W07` `[closed]` | `conformance/faults/` | Crash, timeout, dropped response, unknown submission, stale endpoint, node reset, runtime upgrade, corrupt store, network partition, and process-tree tests fail closed and recover as specified. |
| `PBT-S10-W04` | Measure proof and destination performance | `PBT-S10-W01` `[implementation-complete]`; `PBT-S10-W02` `[implementation-complete]`; `PBT-S10-W03` `[implementation-complete]` | `benchmarks/public-poc-v1.json` | Proof time, memory, proof bytes, fees, execution units, confirmation time, catch-up, and storage stay within S02 and frozen deployment thresholds. |
| `PBT-S10-W05` | Complete threat model and security review | `PBT-S10-W01` `[implementation-complete]`; `PBT-S10-W02` `[implementation-complete]`; `PBT-S10-W03` `[implementation-complete]`; `PBT-S10-W04` `[implementation-complete]` | updated canonical design sections 5 and 22; review artifacts | Trust roots, soundness, replay, freshness, liveness, data availability, setup, key, relayer, upgrade, and economic threats have verified controls or block deployment. |
| `PBT-S10-W06` | Freeze deployment manifests, runbooks, and recovery | `PBT-S10-W03` `[implementation-complete]`; `PBT-S10-W04` `[implementation-complete]`; `PBT-S10-W05` `[implementation-complete]` | `deploy/manifests/`; `deploy/runbooks/` | Rehearsed deploy, inspect, stop, recover, reset, teardown, and new-domain procedures reproduce without secret or mainnet leakage. |
| `PBT-S10-W07` | Run predeployment council and artifact freeze | `PBT-S10-W01` `[implementation-complete]`; `PBT-S10-W02` `[implementation-complete]`; `PBT-S10-W03` `[implementation-complete]`; `PBT-S10-W04` `[implementation-complete]`; `PBT-S10-W05` `[implementation-complete]`; `PBT-S10-W06` `[implementation-complete]` | `program/snapshots/pbt-s10-predeployment/` | Deterministic freeze contracts bind one complete snapshot. Proof, consensus, operator, security, and Codex readers are advisory; accepted findings invalidate the affected freeze inputs. |

### PBT-S11: Public Testnet Readiness

OpenSpec change: `openspec/changes/pbt-s11-public-readiness/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S11-W01` | Rebuild reproducible Windows and WSL environment | `PBT-S10-W07` `[closed]` | `environments/public-deployment.lock.json`; OCI and host receipts | Clean host setup reproduces every executable, image, compiler, cache policy, and artifact hash needed for deployment. |
| `PBT-S11-W02` | Reconfirm chain identities, endpoints, roots, and finality | `PBT-S11-W01` `[implementation-complete]` | fresh Cardano and Midnight public-profile receipts | Network/genesis, runtime, official roots, authority history, source time, freshness, and endpoint health match the frozen deployment domain. |
| `PBT-S11-W03` | Establish disposable testnet key and signing lifecycle | `PBT-S11-W01` `[implementation-complete]`; `PBT-S11-W02` `[implementation-complete]` | public key-handle manifest; signing-boundary tests | Keys remain outside Git and logs; only current-fence allowlisted testnet ids and endpoints sign; every mainnet identifier rejects. |
| `PBT-S11-W04` | Fund testnet identities and establish fee reserves | `PBT-S11-W03` `[implementation-complete]` | public addresses, faucet transactions, balances, and retry receipts | Both sides hold measured deployment and execution reserves; credentials are absent and bounded retry behavior is recorded. |
| `PBT-S11-W05` | Rehearse deployment, teardown, reset, and new domain | `PBT-S11-W01` `[implementation-complete]`; `PBT-S11-W02` `[implementation-complete]`; `PBT-S11-W03` `[implementation-complete]`; `PBT-S11-W04` `[implementation-complete]` | rehearsal runlog and receipts | Full rehearsal deploys, inspects, tears down, detects a simulated reset, creates a new domain, and rejects old-domain proofs. |
| `PBT-S11-W06` | Qualify clean public readiness | `PBT-S11-W01` `[implementation-complete]`; `PBT-S11-W02` `[implementation-complete]`; `PBT-S11-W03` `[implementation-complete]`; `PBT-S11-W04` `[implementation-complete]`; `PBT-S11-W05` `[implementation-complete]` | `program/decisions/public-readiness-v1.json`; review | No capability, funding, secret, root, freshness, artifact, ABI, fee, reset, or deployment gap remains; otherwise state is `blocked` or `waiting-external`. |

### PBT-S12: Public Deployment and Execution

OpenSpec change: `openspec/changes/pbt-s12-public-execution/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S12-W01` | Freeze public deployment intent and deployment preflight | `PBT-S11-W06` `[closed]` | `deploy/runs/<run-id>/deployment-intent.json`; deployment-preflight snapshot | Expected networks, root set and domain, `RegistryActivationV1`, artifact authorizations, ABI templates, deployment recipes, keys, balances, endpoint policies, source implementation snapshot and its confirmed predecessor remote SHA, authorization-event head, and stop rules validate before any deployment submission. `DeploymentIntentV1` binds the registry-activation digest plus both base and `roster_stage=family-complete` artifacts, their digests, `base_entry_count`, byte-identical base prefix, admitted direction-family matrix root, and predeployment activation-subset digest. It contains no controller lease or fencing epoch, activation decision, deployment observation, concrete instance, ABI instance, deployment receipt, or execution result. |
| `PBT-S12-W02` | Deploy and initialize both destinations, then freeze execution intent | `PBT-S12-W01` `[implementation-complete]` | deployment observations; `DestinationAbiInstanceV1`; `RootContextV1`; `ActivationDecisionV1`; deployment receipts; `deploy/runs/<run-id>/run-intent.json`; execution-preflight receipts | Under the immutable deployment intent, both destinations confirm exact code and template bytes. W02 proves an unsuperseded event lineage from the intent's authorization head while each command record binds W02's current lease and fence. Observations create concrete instance ids and ABI instances; the activation decision binds both rosters and exactly their predeployment subset, never gates produced by deployment or execution; initialization produces deployment receipts. Only then does `RunIntentV1` bind the deployment-intent digest, activation decision, receipts, concrete root contexts, both rosters, and execution policy before execution preflight. Any byte, ABI, root, current command fence, network, or intent-lineage mismatch stops W03/W04. |
| `PBT-S12-W03` | Execute Cardano to Midnight for every family | `PBT-S12-W02` `[implementation-complete]` | per-family proof, submission, and Midnight successor-state receipts | Every authorized Cardano family produces a proof and a confirmed atomic Midnight transition under the frozen snapshot. |
| `PBT-S12-W04` | Execute Midnight to Cardano for every family | `PBT-S12-W02` `[implementation-complete]` | per-family Halo2, BSB22, transaction, and Cardano successor-state receipts | Every authorized Midnight family produces both proof layers and a confirmed atomic Cardano transition under the same snapshot. |
| `PBT-S12-W05` | Independently reproduce receipts and successor states | `PBT-S12-W03` `[implementation-complete]`; `PBT-S12-W04` `[implementation-complete]` | independent node and verifier reports | Separate observers reproduce transaction inclusion, code, inputs, proof result, and all four successor states from official roots. |
| `PBT-S12-W06` | Run failure, stale, duplicate, and reset rejection drills | `PBT-S12-W03` `[implementation-complete]`; `PBT-S12-W04` `[implementation-complete]`; `PBT-S12-W05` `[implementation-complete]` | public rejection receipts and local reset drill | Wrong domain, stale root, duplicate claim, altered artifact, invalid proof, unknown runtime, and reset cases reject with authenticated four-state `NO_CHANGE`. |
| `PBT-S12-W07` | Freeze public evidence and classifier candidate | `PBT-S12-W03` `[implementation-complete]`; `PBT-S12-W04` `[implementation-complete]`; `PBT-S12-W05` `[implementation-complete]`; `PBT-S12-W06` `[implementation-complete]` | `program/snapshots/pbt-s12-public-run/`; `ClassifierReadinessV1`; classifier input | Evidence covers every direction-family row, every non-readiness gate evaluation, receipts, runlogs, source roots, and non-claims with no mutable external reference. `ClassifierReadinessV1` binds that candidate; its receipt then supports the readiness gate's own evaluation before PBT-S13. It contains no terminal classification. |

### PBT-S13: Independent Public Closure

OpenSpec change: `openspec/changes/pbt-s13-public-closure/`

| Package | Work package | Depends on | Primary artifacts | Exit or stop evidence |
| --- | --- | --- | --- | --- |
| `PBT-S13-W01` | Freeze and revalidate `PublicRunSnapshotV1` | `PBT-S12-W07` `[closed]` | final snapshot, scope manifest, evidence inventory | All Git objects, external artifacts, source receipts, public transactions, destination states, and graph sources reproduce with no drift. The snapshot binds both rosters, proves the family roster's byte-identical base prefix, binds the admitted matrix root, and contains one current evaluation for every logical base and appended family gate. PBT-S13 reviews remain advisory snapshot-bound artifacts rather than roster or closure inputs. |
| `PBT-S13-W02` | Run fresh isolated Codex audit | `PBT-S13-W01` `[implementation-complete]` | immutable Codex request, JSONL, stderr, response, disposition | Codex inspects a full disposable clone of the committed snapshot and reports 0 Blocking, 0 Major, and 0 Minor findings; no edit or scratch residue occurs. |
| `PBT-S13-W03` | Run fresh proof, consensus, operator, and security council | `PBT-S13-W01` `[implementation-complete]` | four immutable reader reports | Every supervised reader names the same snapshot and checks its declared scope. Reports are advisory; an accepted finding returns to its earliest owning package. |
| `PBT-S13-W04` | Dispose findings and enforce re-entry invalidation | `PBT-S13-W02` `[implementation-complete]`; `PBT-S13-W03` `[implementation-complete]` | disposition ledger and invalidation receipt | No reader-authored count is rewritten. Any accepted fix invalidates dependent artifacts and repeats all affected execution or review steps. |
| `PBT-S13-W05` | Run strict classifier, seal records, and push | `PBT-S13-W01` `[implementation-complete]`; `PBT-S13-W02` `[implementation-complete]`; `PBT-S13-W03` `[implementation-complete]`; `PBT-S13-W04` `[implementation-complete]` | `live-pass` classifier receipt; terminal `RunEvidenceManifestV1` head; `ClosureEnvelopeV1`; archived OpenSpec; sealed wiki and runlogs; remote SHA | Strict OpenSpec, archive, closure-envelope, wiki, runlog, evidence-head chain, 25-section, both roster digests, base-prefix equality, admitted-matrix-root, and remote checks pass. The classifier binds the terminal evidence-head digest and cumulative count, evaluates every base and family gate, and returns public-testnet `live-pass` and nothing weaker. A base roster alone, missing head record, or unevaluated entry rejects. |

## Sprint Plan Generation Checklist

For each sprint after `PBT-S00`, the controller must complete these steps before implementation:

- [ ] Verify every predecessor snapshot and declared external input.
- [ ] Scaffold the named OpenSpec change with proposal, delta specs, design, tasks, and review.
- [ ] Copy the package ids, dependencies, artifacts, and stop evidence from this register without renaming them.
- [ ] Resolve exact upstream objects, tool versions, interfaces, files, endpoints, and test vectors from admitted receipts.
- [ ] Write a code-level plan under `docs/superpowers/plans/` using red-green-refactor steps and explicit commit boundaries.
- [ ] Validate the OpenSpec change, package-plan agreement, program snapshot, and allowed path set.
- [ ] Generate a fresh bounded Grok packet and create the immutable attempt before any mutation.
- [ ] Refuse execution if any required value is unknown, assumed, stale, or supplied only by an untrusted observation.
- [ ] Before successor admission, sync accepted delta requirements into stable specs, validate strictly, archive the sprint change, hash the archive, and verify `ClosureEnvelopeV1`.

## Program Completion Checklist

- [ ] The controller reduces one valid append-only history covering all 106 packages.
- [ ] Exactly 42 Cardano and 52 Midnight predicates are admitted and locally conformed.
- [ ] Every authorized direction-family row has a confirmed public destination successor-state receipt.
- [ ] Official Cardano and Midnight roots, transitions, authenticated source time, and freshness proofs reproduce independently.
- [ ] Circuit, setup, SRS, VK, registry, ABI, deployment, and destination code bytes match one final snapshot.
- [ ] Human ceremony evidence satisfies the frozen circuit policy; agent simulations are labeled only as software tests.
- [ ] Every runlog, command, source receipt, wiki event, evidence item, and review artifact passes cross-file validation and secret scanning.
- [ ] Fresh Codex, proof, consensus, operator, and security reviews bind the final public snapshot; all accepted findings have dispositions and repeated affected tests. Their counts do not determine closure.
- [ ] The canonical design still has exactly 25 numbered sections and reflects current deployed state without revision narration.
- [ ] The strict classifier returns `live-pass`, the final branch is pushed normally, and the remote SHA is independently confirmed.
