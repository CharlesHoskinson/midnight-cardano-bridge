# predicate-registry Specification

## Purpose
TBD - created by archiving change sprint-01-foundation. Update Purpose after archive.
## Requirements
### Requirement: Authorized proof semantics
The destination SHALL resolve proof semantics from the active `RegistryActivationV1` and SHALL reject caller-selected authorization. `QueryV1` SHALL contain only schema version, requested predicate, bounded typed inputs, destination context, and optional constraints. The semantic registry template SHALL bind predicate id and version, accepted anchor and finality templates, statement and result schemas, proof-suite and circuit-architecture templates, complete artifact template slots including every VK/SRS/setup profile, proof-bound selector, ABI template, replay policy, lifecycle policy, audit digest, and provenance digest. Neither a semantic entry nor any transitive reference SHALL contain the root-set digest, deployment domain, registry activation, artifact authorization, ABI instance, concrete deployed destination id, runtime lifecycle state, or receipt. Its ordered leaves SHALL produce `semantic_registry_template_root`, which SHALL feed `DeploymentRootSetV1`.

After domain derivation, `RegistryActivationV1` SHALL bind the root-set digest, deployment domain, semantic registry template root, destination identities, activated entry set, and lifecycle state, and its digest SHALL be stored in destination state. The canonical resolution SHALL own the predicate version, anchor, finality rule, statement and result schemas, suite, every VK/SRS/setup profile, architecture, destination verifier or operation, artifacts, replay mode, and lifecycle and SHALL bind the root-set digest, domain, registry activation, artifact authorization root, and ABI instance. Query constraints SHALL only assert equality with those resolved values. Registry population SHALL remain blocked until a mechanical gate reports exactly 42 unique Cardano records and 52 unique Midnight records, no duplicate ids, and a provenance digest for every row; the system SHALL NOT invent or duplicate a row to satisfy either count.

`RootContextV1` SHALL contain deployment and source context only. Resolution SHALL place predicate, suite, architecture, roles, authorized artifacts, schemas, replay/destination policies, and the complete freshness adapter/unit/conversion/width/comparison/bounds/era contract in `ResolvedProofContextV1`. The active roster and registry activation SHALL be authenticated before preflight or source collection. A missing numeric bound or unauthenticated time adapter SHALL block resolution.

#### Scenario: An unregistered VK, suite, architecture, or SRS is rejected
- **WHEN** a submitted claim names a verifier key, proof suite, circuit architecture, or SRS that is absent from or inconsistent with its active registry entry
- **THEN** the destination SHALL reject the claim even if its cryptographic proof would otherwise verify

#### Scenario: A query attempts to select authorization
- **WHEN** a query carries an anchor, suite, VK, SRS, setup, architecture, operation, artifact, replay mode, or lifecycle value outside its optional constraint map or a constraint differs from the resolved value
- **THEN** query decoding or registry resolution SHALL reject before source collection and no prover SHALL run

#### Scenario: An incomplete predicate catalog blocks registry population
- **WHEN** the catalog gate finds a missing record, duplicate id, wrong Cardano or Midnight count, or absent provenance digest
- **THEN** registry population SHALL stop without synthesizing a replacement row

### Requirement: Complete artifact enforcement graph
Every semantic predicate template SHALL bind a content-addressed suite-profile template containing the exact three-role sequence for its direction, role-specific statement adapters and allowed VK template slots, aggregation count and padding rules, recursion bounds, complete Poseidon and VK-hash export, field and equality matrix, inner and aggregation VK templates, destination operation or wrapper VK template, KZG verifier SRS template, transcript template, committed-wire template where applicable, setup template and receipts, destination ABI template, and an enforcement-locus record. Each artifact template SHALL name its authoritative owner, runtime or deployment enforcement point, cryptographic binding template, replacement rule, positive and negative vectors, and activation rule. It SHALL be domain neutral.

After domain derivation, each active artifact SHALL have one `ArtifactAuthorizationV1` binding root-set digest, deployment domain, registry activation, artifact template root and leaf digest, graph slot, content hash, and lifecycle status. The authorization records SHALL produce the artifact authorization root stored in `RootContextV1`. A witness-supplied verifier parameter SHALL be authenticated in-circuit against that root. `DeploymentObservationV1` SHALL authenticate the confirmed destination deployment, ABI template, verifier or operation template hash, deployment recipe, concrete destination instance, deployed code hash, and independent observations. `DestinationAbiInstanceV1` SHALL accept its concrete fields only from that observation and bind them to the registry activation and artifact authorization root. None of these post-domain records SHALL feed the semantic registry template root, artifact template root, checkpoint, or deployment root set.

#### Scenario: A valid but wrong-role VK is rejected
- **WHEN** every supplied proof verifies in isolation but one role uses a VK authorized only for another terminal position
- **THEN** aggregation SHALL reject the role substitution even after all remaining hashes are recomputed

#### Scenario: A listed but unconstrained artifact blocks activation
- **WHEN** a suite lists a VK, SRS point, transcript parameter, or commitment key without classifying it as a circuit constant or authenticated profile input at a named enforcement locus
- **THEN** registry activation SHALL fail

#### Scenario: Ceremony and deployed VK differ
- **WHEN** ceremony output, ABI profile, registry slot, or deployed destination state contains different VK bytes
- **THEN** deployment and suite activation SHALL fail before claim verification

#### Scenario: A domain-bound authorization appears in a template
- **WHEN** a semantic registry, artifact, or ABI template transitively references an activation, authorization, concrete destination instance, runtime lifecycle state, or deployment domain
- **THEN** the template and root-set acyclicity checks SHALL reject it before root derivation

### Requirement: Content-addressed artifact discovery
`ArtifactTemplateRefV1` SHALL contain only domain-neutral artifact kind, logical graph slot, suite and architecture templates, canonical encoding, exact byte length, content hash, and artifact-template membership proof. `ArtifactFetchHintV1` SHALL carry advisory locations and SHALL NOT be an authorization or root-set input. Starting from the canonical registry resolution and `RootContextV1`, the artifact resolver SHALL verify registry activation, `ArtifactAuthorizationV1`, artifact-template membership, logical graph slot, deployment domain, ABI-instance expectations, canonical encoding, exact byte length, and content hash before cache or use. Location hints SHALL be advisory, caches SHALL be keyed by content hash and retain the domain-bound authorization proof, and offline bundles SHALL use the same checks. Unavailable, malformed, hash-mismatched, and well-formed but unauthorized artifacts SHALL have distinct failure classes.

#### Scenario: A location serves a valid unregistered key
- **WHEN** an advisory URI returns a well-formed verifier key whose digest is not authorized for the resolved graph slot
- **THEN** resolution SHALL fail permanently even if cryptographic verification under that key would succeed

### Requirement: Missing source values are explicit gate artifacts
Every unavailable chain constant, protocol parameter, equation set, operation identity, source root, confirmation rule, funding value, or catalog row SHALL remain absent from active semantics until a versioned content-addressed `GateDeliverableV1` copies the decoded roster entry's exact ordered `owners[]`, `interfaces[]`, `applicability`, `required_evidence[]`, and `activation_ref`, then binds its pinned source or source-absence record, enforcement loci, vector bundle, independent reproduction receipts, failure code, and supersession rule. Other parties SHALL be contributors or enforcement loci, not owners. Implementers SHALL NOT select a convention to fill a missing deliverable.

#### Scenario: A gate artifact omits activation evidence
- **WHEN** a proposed source-dependent artifact lacks its owner, enforcement test, required vector bundle, or independent reproduction receipt
- **THEN** the affected registry slot SHALL remain inactive without authorizing a fallback
