# operations-governance Specification

## Purpose
TBD - created by archiving change sprint-01-foundation. Update Purpose after archive.
## Requirements
### Requirement: Immutable PoC roots
Within a proof-of-concept deployment domain, the checkpoint digest, finality and anchor templates, proof-suite and artifact template roots, VK and SRS templates, semantic registry template root, destination verifier or operation and ABI templates, deployment recipes, replay rule, and recovery-policy template SHALL be immutable. Their domain-bound registry activation, artifact authorization root, ABI instances, and root context SHALL also be immutable. Replacing any such template or instance or performing a testnet reset SHALL create a new deployment instance and domain and SHALL cause old-domain proofs to be rejected. An unauthenticated unknown, downgraded, or mismatched fingerprint SHALL reject without changing safety state. Only registered authenticated source conflict or unauthorized-upgrade evidence SHALL freeze a domain. Recovery evidence SHALL authorize an action only from the matching recorded `Frozen` state.

#### Scenario: Replacing a PoC root requires a new deployment domain
- **WHEN** an operator proposes to replace any proof-of-concept trust, proof, or policy root
- **THEN** deployment tooling SHALL derive a new deployment domain and conformance SHALL demonstrate rejection of proofs bound to the prior domain

### Requirement: Reproducible fingerprints and deployment domains
A Cardano source fingerprint SHALL be the deterministic digest of Cardano identity and era history, Mithril bootstrap and transition rules, AVK and parameter rules, signed-entity projection, SCLS format/tree rules, and finality adapter. A Midnight source fingerprint SHALL be the deterministic digest of Midnight identity, AURA/GRANDPA/BEEFY role profile, runtime release, BEEFY ECDSA/Keccak/quorum/leaf rules, mandatory handoff, header/MMR/parent rules, event inclusion adapter or canonical blocked marker, and finality adapter. Every component SHALL resolve to immutable source/spec/code bytes.

`DeploymentRootSetV1` and every transitive value reachable from it SHALL be domain neutral. It SHALL contain only the bridge program id, fresh deployment instance id, source identity/fingerprint pairs, destination network identity templates, approved domain-neutral checkpoint-manifest digests, anchor/finality/proof templates, semantic registry template root, artifact template root, ABI template digests, destination verifier or operation template hashes, deployment recipe digests, and replay, freshness, recovery, approval, and bridge-hash policy templates. It SHALL exclude its own digest and domain, any value whose producer consumes either, registry activations, artifact authorizations, ABI instances, concrete deployed destination ids, runtime lifecycle state, cache authorization, claims, proofs, jobs, replay keys, transactions, run manifests, and receipts.

The system SHALL derive `root_set_digest = Digest("mcb/deployment-root-set/v1", CanonicalEncode(DeploymentRootSetV1))` and then `deployment_domain = Digest("mcb/deployment-domain/v1", root_set_digest)` exactly once. Only afterward SHALL it derive `RegistryActivationV1` and `ArtifactAuthorizationV1` records and their root. A confirmed deployment SHALL produce `DeploymentObservationV1` binding the fresh deployment instance id, destination network, ABI template, code or operation template, recipe, concrete instance, code hash, deployment transaction, confirmation profile, and independent observations. `DestinationAbiInstanceV1` SHALL accept concrete fields only from that record, and deployment/source-only `RootContextV1` SHALL consume the ABI instance. The system SHALL then produce approval-threshold-authorized `ActivationDecisionV1`, initialize destination state, and authenticate final `DeploymentReceiptV1` against the chain and independent observation. These records SHALL enforce exact checkpoint-manifest, fresh-instance, root-set, domain, root-context, source identity/fingerprint, activation, artifact-root, deployment-observation, ABI-instance, destination-identity, template, recipe, concrete-code, and roster equalities. Per-claim suite/architecture/predicate values SHALL reside in `ResolvedProofContextV1`. No post-domain record or digest SHALL feed a checkpoint, template root, or deployment root set.

`CONS-DOMAIN-01` SHALL publish two independent golden derivations that agree on canonical bytes and digests at every pre-domain and post-domain boundary. Its existing roster entry SHALL include `interface.common-codec`, `evidence.domain.common-codec-polyglot-golden-vectors`, and `evidence.domain.common-codec-no-redefinition-vectors`; these SHALL NOT create a new gate. A mechanical check SHALL resolve all schema and digest references reachable from `DeploymentRootSetV1`, reject forbidden post-domain fields and types, and topologically sort the complete digest graph. A cycle, back edge, unresolved producer, placeholder, fixed point, or iterative hash search SHALL fail activation. Vectors SHALL mutate every included field, every excluded post-domain record, and the fresh deployment instance id and SHALL prove domain changes, authorization failure, reset isolation, old-domain rejection, common-codec agreement, and no-redefinition as applicable.

#### Scenario: A codec or root change cannot reuse a domain
- **WHEN** any source interpretation rule, verifier-bound artifact, destination code hash, replay rule, checkpoint, or deployment instance id changes
- **THEN** the old fingerprint or domain SHALL not authorize it and old proofs and replay records SHALL fail

#### Scenario: A transitive post-domain dependency is found
- **WHEN** the schema walker reaches a deployment domain, activation, authorization, ABI instance, runtime payload, or receipt through any root-set field or digest preimage
- **THEN** deployment root validation SHALL fail before computing an accepted root-set digest

### Requirement: Only authenticated safety evidence freezes a domain
Safety state SHALL be `Active(root_set_digest)` or `Frozen(root_set_digest, reason, authenticated_evidence_digest, transition_id)`. Source-evidence freeze SHALL require a registered proof of two individually valid conflicting BEEFY commitments with one source-native conflict key, two individually chain-valid conflicting Mithril certificates with one entity/beacon conflict key, or a currently authenticated unauthorized source upgrade. Governance approvals and elapsed delay SHALL NOT be source evidence or trigger freeze. A successful freeze SHALL change only safety state and SHALL NOT advance or roll back an anchor, apply an action, move value, consume replay state, replace a root, or select a branch. Authorized delayed recovery SHALL start only from a recorded frozen state; `RecoveryAuthorizationV1` SHALL bind freeze evidence, root context, action, policy, timing, threshold approvals, sequence, and migration digest, while `RecoveryRecordV1` SHALL bind all four pre/post state-owner digests. Same-domain resume SHALL preserve every root and rule, and root replacement SHALL use `DomainMigrationV1`.

#### Scenario: Arbitrary fingerprint input cannot freeze settlement
- **WHEN** an untrusted submission carries an unknown or mismatched fingerprint without registered authenticated upgrade or conflict evidence
- **THEN** the submission SHALL reject and safety state SHALL remain unchanged

#### Scenario: Valid equivocation freezes without selecting a branch
- **WHEN** two individually valid source objects have the same registered conflict key and different finality or certification results
- **THEN** the domain SHALL atomically enter `Frozen` with their evidence digest and SHALL not advance, roll back, settle, or consume replay state

#### Scenario: Recovery approvals cannot freeze an active domain
- **WHEN** threshold-valid recovery approvals and the full delay exist while safety state is `Active`
- **THEN** recovery SHALL reject and safety, tracked, application, value, and replay state SHALL remain unchanged

### Requirement: Domain migration preserves authenticated continuity
`DomainMigrationV1` SHALL bind old/new root contexts and activation decisions, old final tracked and replay states, replay/application/value import roots, old/new `continuity_replay_root`, continuity leaf count, export-manifest digest, authenticated completeness/translation proof, import profile, cutover points and transactions, in-flight disposition, policy, monotonic sequence, approvals, proposal time, delay amount and unit, delay-bounds profile, earliest execution time, and execution time. Checked bounded arithmetic SHALL require `earliest_execution_time = proposal_time + delay_amount` and `execution_time >= earliest_execution_time`. The continuity proof SHALL authenticate the complete old continuity root inside the terminal replay state and translate every leaf exactly once into the new root; omission, insertion, duplication, or substitution SHALL fail. Unchanged codecs SHALL require byte-preserving leaves and equal roots. The old domain SHALL shut down before imported state is exposed. A destructive lab reset SHALL declare no continuity, import no replay/application/value root, cancel old jobs, and SHALL NOT serve as a state or asset migration receipt.

#### Scenario: Old consumed event is replayed after migration
- **WHEN** a fully valid new-domain proof is made for an event consumed in the old domain under `message-id`, `nullifier`, or `both`
- **THEN** its domain-independent imported `continuity_key` SHALL reject without changing any state owner, while an unrelated event SHALL pass the continuity check

#### Scenario: Migration timing is at the exact boundary
- **WHEN** execution is one unit before or exactly at the checked earliest execution time
- **THEN** the early record SHALL reject and equality SHALL pass; mutation of any timing field after approval SHALL invalidate the approval

### Requirement: Evidence supersession and gate resume are race-safe
`EvidenceSupersessionV1` SHALL bind roster/gate/activation ids, old/new evidence, reason, deadlines, timing, retention/owner policies, approvals, and evidence sequence while preserving old bytes. `GateResumeV1` SHALL bind current root context, prior record/status, effective evidence, dependency snapshot, resume time, roster-owner plus governance approvals, and expected/new gate sequence. Late supersession SHALL first return the gate to unresolved. Compare-and-swap sequences SHALL allow at most one race winner; stale, duplicate, or competing records SHALL make no gate, safety, value, or replay change.

#### Scenario: Two resumes race
- **WHEN** two authorized resume records cite the same expected gate sequence
- **THEN** at most one SHALL advance the sequence and the loser SHALL record `NO_CHANGE`

### Requirement: Immutable manifests are isolated from mutable operations
The public root template manifest SHALL contain domain-neutral source/destination identity templates, checkpoint, consensus and anchor templates, fingerprint policy, semantic registry template root, destination code and ABI templates, deployment recipes, replay, recovery, and approval templates. The public artifact template manifest SHALL contain domain-neutral suite slots, schema/circuit/VK/SRS/setup/transcript/build evidence and expose the artifact template root. A public activation manifest SHALL contain the root-set digest, domain, registry activation, artifact authorization root, ABI instances, concrete deployed destination ids, and deployment receipts; it SHALL NOT enter domain derivation. Immutable `RunIntentV1` SHALL contain run/profile ids, root and activation digests, exact roster, software revisions, endpoint intent, funded-role requirements, operational probe/metric, confirmation, and evidence-retention profiles, declared evidence locations, and preflight policy, but no observed result or receipt. `PreflightReceiptV1` SHALL bind the intent digest and observed checks/results. `RunEvidenceManifestV1` SHALL bind the intent and ordered receipt/evidence digests. Every later receipt SHALL bind the intent digest. The schema DAG SHALL forbid a receipt or evidence-manifest digest in the intent preimage. A private operator overlay SHALL contain credentials, signing handles, secret-store locations, sockets, funding sources, and mutable limits and SHALL NOT enter domain derivation.

#### Scenario: An RPC credential rotates
- **WHEN** an operator changes only a credential or secret handle in the private overlay
- **THEN** the deployment domain SHALL remain unchanged and public run evidence SHALL identify the overlay revision without exposing the secret

#### Scenario: Preflight cannot rewrite its intent
- **WHEN** preflight completes and any `RunIntentV1` field is changed or a receipt digest is inserted into its preimage
- **THEN** every receipt SHALL fail intent binding and the manifest DAG SHALL reject the back edge
