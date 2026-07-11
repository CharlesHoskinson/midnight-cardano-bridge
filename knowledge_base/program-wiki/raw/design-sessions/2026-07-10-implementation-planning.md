# Implementation planning record

Source id: `source.design-session.2026-07-10-implementation-planning`
Record type: immutable design session
Recorded at: 2026-07-10T22:33:54Z

## Inputs

- Approved design:
  `docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md`
- Master implementation plan:
  `docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md`
- First executable sprint plan:
  `docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md`
- Approved design-source commit:
  `3db35fa9a7e7257359f5def4bb216c60356643b8`
- Execution planning baseline:
  the later commit that first contains this approved plan and its wiki records

## Planning decision

The implementation baseline contains 14 sprints and 100 stable work packages.
Each package now has a dependency, primary artifact, and objective exit or stop
condition. The package ids and counts are fixed by the approved design.

Canonical sprint ids are `PBT-S00` through `PBT-S13`. Canonical package ids are
the following contiguous ranges:

- `PBT-S00-W01` through `PBT-S00-W12`
- `PBT-S01-W01` through `PBT-S01-W06`
- `PBT-S02-W01` through `PBT-S02-W09`
- `PBT-S03-W01` through `PBT-S03-W08`
- `PBT-S04-W01` through `PBT-S04-W06`
- `PBT-S05-W01` through `PBT-S05-W06`
- `PBT-S06-W01` through `PBT-S06-W07`
- `PBT-S07-W01` through `PBT-S07-W08`
- `PBT-S08-W01` through `PBT-S08-W06`
- `PBT-S09-W01` through `PBT-S09-W07`
- `PBT-S10-W01` through `PBT-S10-W07`
- `PBT-S11-W01` through `PBT-S11-W06`
- `PBT-S12-W01` through `PBT-S12-W07`
- `PBT-S13-W01` through `PBT-S13-W05`

Every package edge uses a full package id and required state. Same-sprint
implementation edges may require `implementation-complete`. Every cross-sprint
edge requires `closed`.

Sprint 0 has a code-level implementation plan because its interfaces can be
derived from the current repository. The plan names exact schemas, modules,
tests, commands, evidence, and commit boundaries for all 12 packages.

Later code-level sprint plans are intentionally generated after their hard
predecessors close. Public SCLS, the complete Midnight event proof, destination
verifier surfaces, predicate catalogs, frozen circuits, and ceremony artifacts
are unresolved inputs. Naming concrete APIs or source files for those systems
before feasibility and source admission would turn assumptions into program
authority. The controller first generates a bounded discovery packet from
immutable external-input requirements. It generates the resolved implementation
packet only after the discovery packages produce qualified tools, networks, and
source receipts.

## Sprint 0 implementation boundary

Sprint 0 owns deterministic text and baseline preservation, the canonical
machine plan, append-only program events, attempts and leases, universal command
supervision, runlog and secret validation, snapshots and invalidation,
repository transactions, bounded Grok packets, detached Codex and council
reviews, program-wiki lint, `GateRosterV2`, CI, and one closure smoke run.

The control plane must reproduce the prior operational failures as negative
tests. These include read-only TEMP failures, mixed Codex output streams,
synthesized command records, process-tree leaks, mutable review rounds,
line-ending drift, stale remote pushes, secret-bearing logs, snapshot drift,
and success labels emitted after failure.

Packages W01 through W05 form a bounded bootstrap window because they create
the event writer, lease model, command supervisor, and package entrypoint. W05
first commits the supervisor. W03 likewise commits the native service source
before two clean, unprivileged builds produce the binary accepted by the
elevated installer. The unelevated operator records the complete qualification
file hash and carries it into the elevated session. The administrator verifies
that hash before trusting the source, receipt, binary, and provisioner pins in
the file. The installer never runs Cargo or a build script. After W05,
the operator streams a one-time Git bundle and complete object manifest through
the authenticated administrative channel. The broker verifies the committed
planning-through-W05 lineage before it can generate the detached replay bundle.
That replay publishes five package-scoped receipts, imports those packages as
`implementation-complete`, and closes the bootstrap window permanently.

One fenced native controller broker owns global event order. It runs under a
dedicated Windows service SID and owns ACL-protected controller and canonical
Git storage. Package children run with a stripped restricted token in full
per-attempt clones with independent Git metadata. Each receives a private
capability channel bound to its lease and fence. The broker publishes complete
immutable event objects atomically, validates clone trees, and serializes
accepted segments into canonical Git. Leases renew and carry monotonic fencing
epochs. Every worker pack enters a bounded no-execute quarantine with strict
object, delta, resource, platform-path, and package-allowlist checks before
import. W06 and later work runs through `invoke-program-package.ps1`.

Reviews bind one immutable implementation snapshot. OpenSpec is first validated
from a clean clone at that commit. After review, the controller commits a
relocation-only archive candidate and validates stable specs from its exact
tree. The archive receipt is created later, so it never hashes a tree containing
itself. A closure envelope permits only reader artifacts, dispositions, the
archive receipt, final event and state, a deterministic raw wiki closure receipt
and graph materialization, inventories, and seal receipts. A behavioral change
creates a new snapshot and repeats affected readers. The envelope's typed object
inventory excludes its own fixed file. A separate schema check covers that file,
and the final delta must equal the inventory plus that path. `FinalizeClosure`
materializes those artifacts, validates the delta, commits and integrates the
tree, verifies byte-identical source and integration trees, and returns a new
closure context that publishes only the integration commit. No Sprint 0 package
becomes `closed` until this envelope validates.

Remote publication uses an opaque, noninteractive credential handle owned by
the controller service and qualified for the exact remote, branch, provider,
scope, service identity, and expiry. The handle is immutable; revocation comes
from append-only lifecycle events. Review, pre-fetch, and pre-sign probes each
produce a separate signed receipt. After push, the controller signs a
confirmation bundle containing the handle, all three probe receipts, pre-fetch,
ordered one or two push attempts, post-fetch command records, every raw stream,
controller identity, and payload manifest. It publishes the verified directory
with one same-volume rename. A lost push response is resolved with a read-only
fetch and never a blind retry. Before each package lease, the controller imports
the complete cumulative set of required `[closed]` predecessor bundles and
rejects extra or missing imports.

`GateRosterV2` is immutable definition data. Its entries start unresolved;
append-only `GateEvaluationV1` records carry current evidence, expiry,
supersession, and invalidation. Base-prefix entries use the base roster as their
origin once, while appended direction-family entries use the family-complete
roster. PBT-S12-W07 first produces classifier-readiness evidence over every other
current evaluation, then appends that gate's own evaluation. Final PBT-S13
reviews are direct classifier inputs, and the terminal classifier receipt is
never its own gate. Activation uses only the roster-defined predeployment subset,
not later deployment, execution, review, or classifier gates.

Sprint 0 does not close a public-chain gate. Deployment remains blocked and
activation remains false.

Predicate recovery and public admission are separate. PBT-S03-W01 through W05
recover exactly 42 Cardano and 52 Midnight source rows containing source
semantics, witnesses, bounds, raw vectors, and provenance. Those bytes do not
claim a proof family, public finality profile, destination policy, or artifact.
W06 through W08 join separate admission records to the immutable catalog digest
after PBT-S02 demonstrates the public profiles. An unsupported but correctly
recovered relation blocks admission without rewriting its source row.

The later proof plan fixes additional boundaries. The Midnight-to-Cardano
Groth16 R1CS recomputes the complete KZG decision instead of accepting an
off-circuit result. A frozen KZG binding profile states whether SRS verifier
material is constant or authenticated input. New or update KZG ceremonies,
Groth16 Phase 1, and per-circuit Phase 2 each have a distinct future beacon and
sealed head keyed by setup kind, stable transcript id, SRS-profile id, phase,
and circuit id or a no-circuit sentinel. Historical KZG bytes follow a separate
qualification path that verifies the original precommitment, chronology, beacon,
transcript algebra, anchors, and final bytes. The bridge cannot add a new beacon
to a sealed historical SRS; missing original evidence blocks or forces a
rebaseline when those constant bytes are required. Immutable artifact templates contain logical slots and
evidence constraints; later authorization records carry concrete circuit, VK,
SRS, transcript, and verification hashes without mutating template roots.
KZG qualification replays every contribution with two independent
implementations, checks the selected protocol's contribution proof and update
relation across all declared G1 and G2 powers, and rejects altered or
inconsistent powers before any SRS authorization.
Human setup counts a contribution only when its signer acknowledges inclusion
in every final publicly anchored head they joined. The pinned commitment-aware
suite verifies `tau/alpha/beta` in Phase 1 and `delta` plus every commitment
`sigma` in Phase 2; `gamma` is the fixed G2 generator.

Deployment has two immutable intent stages. `DeploymentIntentV1` binds the root
set, domain, `RegistryActivationV1`, artifact authorizations, ABI templates,
deployment recipes, roster artifacts, activation subset, and endpoint policies
plus the source snapshot and authorization-event head before submission. It does
not contain a controller lease or fence; each later command binds its current
fence and proves unsuperseded lineage. S12 deployment observations then create concrete ABI
instances, root contexts, activation decisions, and deployment receipts.
`RunIntentV1` binds those results before execution preflight. Destination state
stores the root context and activation decision, while the later deployment
receipt remains external. Execution receipts bind the run intent but never a
manifest that does not yet exist. Immutable `RunEvidenceManifestV1` heads are
created afterward and index receipt digests in predecessor order; the classifier
binds the terminal head.

## Execution handoff

Implementation uses one task per Sprint 0 package. Each task starts with a
failing contract test, adds the smallest implementation that satisfies the
contract, runs its focused and regression suites, and commits only its declared
paths. The final package freezes one complete snapshot and runs fresh Codex,
proof, consensus, operator, and security reviews. A nonzero finding creates a
new implementation target and immutable review round.
