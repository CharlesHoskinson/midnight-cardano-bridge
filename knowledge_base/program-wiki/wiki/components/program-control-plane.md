---
id: component.program-control-plane
type: component
title: Program control plane
status: active
updated_at: 2026-07-12T02:20:00Z
sources:
  - source.design-session.2026-07-10-implementation-planning
  - docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md
  - source.design-session.2026-07-12-fable-audit-remediation
---

# Program control plane

The control plane turns the approved sprint graph into recoverable repository
work. It will be implemented by the 18 packages in `PBT-S00`.

Its source of truth is a canonical machine plan plus controller-owned immutable
event objects. A native SCM-compatible broker runs under a dedicated Windows
service SID and owns ACL-protected controller and canonical Git roots. Package
and model children receive a stripped restricted token, a full clone with an
independent object database, and a private per-attempt capability channel.
Direct write, delete, rename, ownership, and DACL access to controller or
canonical Git storage must fail before any package runs. Derived state and JSONL
views can be regenerated. Attempts,
leases and fencing epochs, command starts and results, artifact publication,
invalidation, reviews, deployments, and classifier results remain part of the
event history.

Nine Sprint 0 packages run inside a bounded bootstrap window: W01-W05 and
W13-W16. W05 commits the supervisor before W15 adds quarantine and W16 publishes
the entrypoint. The operator then streams a one-time Git
bundle and complete object manifest through the authenticated administrative
channel. The broker verifies the planning-through-W16 lineage before seeding its
canonical repository. A clean detached replay emits nine package-scoped receipts
and closes the bootstrap window permanently. All later work runs through one
package entrypoint. Returned worker packs pass bounded no-execute quarantine,
strict object validation, platform-path checks, and package allowlists before
import. W08 adds concurrency and remote publication hardening. Sprint 0 packages
reach `closed` only after the complete sprint snapshot and closure envelope pass.

Every child process runs through one supervisor. The supervisor records the
start before launch, keeps stdout and stderr separate, enforces a timeout, kills
the complete process tree, checks required outputs, and records the terminal
result. Unsanitized captures stay in external scratch storage until a
deterministic secret scan permits publication.

Each advisory review binds a complete program snapshot. Codex and the four persona
readers run as separately supervised processes in full disposable clones with
unique writable scratch and separate JSONL and stderr captures. Reader reports
and failed rounds are immutable. OpenSpec relocation is committed as an
archive-only candidate and validated before its receipt exists. A closure
envelope then adds only a typed, digest-enumerated set of attestations, state
transitions, a deterministic raw wiki closure receipt and graph updates, wiki
predicates, inventories, and archive records. Path membership alone is not
enough. Its object inventory excludes the envelope's own fixed path and blob;
the validator checks that one file separately and rejects any other unlisted
delta or self, final-tree, or final-commit digest. The controller then commits and
integrates that final tree, verifies source/integration tree equality, and gives
publication a new context targeting the integration commit. A changed
scoped input creates a new snapshot and invalidates the
dependent review.

Repository mutation uses full package clones inside the restricted OS boundary.
Only the fenced controller can validate and import their trees into canonical
Git. Publication uses a qualified noninteractive, remote-allowlisted opaque
credential handle, separate signed review, pre-fetch, and pre-sign probe receipts,
records fetches before and after the push, and never logs secret bytes. A
controller-signed `RemoteConfirmationBundleV1` contains the
pre-fetch, ordered one or two push attempts, post-fetch records, every exact raw
stream and manifest, all three probes, public credential receipt, controller
identity, and payload
manifest. The broker publishes the complete directory atomically and reconciles
a lost push response with a read-only fetch. Before each package lease, it
imports the cumulative transitive set of required `[closed]` predecessor bundles
and rejects missing or unapproved imports.

The control plane does not establish chain feasibility. Its packet compiler can
issue a bounded discovery packet from unresolved external-input requirements,
then a resolved implementation packet after discovery receipts exist.
`GateRosterV2` retains all unresolved public roots, destination surfaces,
predicate, setup, execution, and closure gates until their owning packages
publish valid `GateEvaluationV1` receipts. Roster bytes retain only unresolved
initial state; current evaluations are append-only, expiring, and invalidatable.
Base-prefix gates use the base roster as their origin exactly once, while only
appended family gates use the family-complete roster. The base roster is permanently execution and
classification ineligible by itself. PBT-S04 must publish a family-complete
roster with every ordered base entry as a byte-identical prefix, then append only
admitted family rows. Public execution binds both artifacts, and the classifier
evaluates every logical base and family gate. PBT-S12-W07 supplies nonterminal
classifier readiness. Final PBT-S13 reader reports remain advisory; deterministic
contracts and external chain receipts authorize closure.
