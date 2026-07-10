## ADDED Requirements

### Requirement: Symmetric query and proof flow
The reference harness SHALL expose versioned query, resolution, claim-envelope, proof-response, result, verification, submission, receipt, and inspection interfaces with the same canonical statement rules in both bridge directions. `QueryV1` SHALL contain only schema version, requested predicate, bounded typed inputs, destination context, and optional constraints. For captured public bytes under the same authenticated source bundle, root template manifest, registry activation, and deployment domain, an offline adapter and live-node adapter SHALL produce the same canonical query and resolved public statement, including source fingerprint, anchor, predicate, resolved suite, typed-result schema, destination context, expiry, replay scope, root context, and domain. Adapters, provers, and relayers SHALL remain untrusted data providers whose output is accepted only through destination verification.

#### Scenario: Offline and live adapters produce the same canonical statement
- **WHEN** offline and live adapters use one captured-public source bundle, root template and activation manifests, deployment domain, and versioned query
- **THEN** both adapters SHALL emit byte-identical canonical statement inputs and field elements for the selected proof suite

### Requirement: Registry-owned query resolution
Before preflight, endpoint discovery, source collection, or proving, the harness SHALL bind the exact published `GateRosterV1` bytes/digest and active deployment/source-only `RootContextV1`, then resolve each query through the active `RegistryActivationV1`. The canonical `ResolvedProofContextV1` SHALL fix predicate/version, anchor/finality, schemas, suite, VK/SRS/setup, architecture, roles, artifact graph, ABI/entry point, replay/destination policies, and exact freshness adapters, units, conversion, width, comparisons, era schedule, and bounds. Query values for a resolved field SHALL be non-authoritative constraints and mismatch SHALL be a permanent resolution error.

#### Scenario: A query requests an unauthorized proof suite
- **WHEN** a query's suite, VK, SRS, architecture, operation, or anchor constraint differs from the active predicate resolution
- **THEN** resolution SHALL fail before source collection and no prover SHALL run

#### Scenario: A query carries an authorization field
- **WHEN** a query places an anchor, suite, VK, SRS, setup, architecture, operation, artifact, replay mode, or lifecycle value outside the optional constraint map
- **THEN** canonical query decoding SHALL reject it before registry resolution

### Requirement: Independent codec conformance
Two independently maintained codecs SHALL round-trip every versioned query, resolution, response, result, receipt, and vector through the registered deterministic binary profile and produce identical bytes, digests, and field elements. Golden records for both directions SHALL include the diagnostic query and resolution values, exact canonical bytes, digests, resolved registry and artifact fields, and expected stages for malformed cases. The codecs SHALL reject duplicate fields, alternate integer or length forms, indefinite forms, unknown critical fields, aliases, trailing bytes, and caller-selected authorization.

#### Scenario: Cross-language round trip preserves the hashable form
- **WHEN** one implementation encodes a golden record and the other decodes and re-encodes it
- **THEN** the second byte sequence SHALL equal the first byte for byte

### Requirement: Fixture provenance determines equality
The harness SHALL distinguish `captured-public` fixtures bound to their original authenticated source bundle, root template and activation manifests, domain, receipts, and clock from `synthetic-lab` fixtures bound to dedicated lab root template and activation manifests, domain, deterministic witness, clock, and RNG seed. Byte identity with a live adapter SHALL be required only for captured public data under the same roots. A synthetic fixture MAY compare intended typed semantics but SHALL produce a different proof-bound statement and SHALL support `degraded-lab` only after both real destination transitions execute.

#### Scenario: A synthetic fixture changes a proof-bound root
- **WHEN** a synthetic fixture uses a lab anchor for the same typed result as a public source fact
- **THEN** the harness SHALL require a different canonical statement and SHALL NOT report public-profile equivalence

### Requirement: Discovery cannot grant artifact authority
The harness resolver SHALL start from the canonical resolution and `RootContextV1`. It SHALL use `ArtifactFetchHintV1` locations only to fetch bytes and SHALL require exact registry activation, `ArtifactAuthorizationV1`, domain-neutral artifact-template membership, graph-slot equality, deployment domain, destination ABI instance expectations, exact encoding and length, and content hash before cache or use. Caches SHALL be content-addressed and retain the domain-bound authorization proof, and offline bundles SHALL pass the same checks. Neither location hints nor post-domain authorization records SHALL feed the artifact template root or deployment root set.

#### Scenario: One authorized location is unavailable
- **WHEN** one location fails and another returns byte-identical bytes authorized for the same content hash and graph slot
- **THEN** the resolver MAY retry without changing authorization, resolution digest, or job id

### Requirement: Restart-safe idempotent orchestration
The harness SHALL derive `relayer_id`, `job_id`, `settlement_id`, `attempt_id`, and `submission_id` from fixed-arity deterministic-CBOR tuples containing their declared fields; raw concatenation SHALL be forbidden. Boundary-shift vectors such as `("ab","c")` and `("a","bc")` SHALL have different bytes and ids. Timestamps, endpoints, process ids, and secrets SHALL NOT enter these ids. `FailureProfileV1` SHALL map every failure code to stage, class, owner, budget, backoff, replay effect, and an exhaustive ordered allowed-retry-target set. The harness SHALL persist phase, ids, evidence, retry owner, and selected allowed successor before every side effect. The normative table SHALL cover received, roster-bound, resolved, source-ready, proving, result-canonical, proof-ready, locally-verified, constructed, submitting, submission-unknown, submitted, confirmed, settled, retry-wait, permanent-failure, superseded, dead-letter, and manual-recovery. `JobResumeV1`, distinct from `GateResumeV1`, SHALL bind job/settlement ids, root context, prior record/phase, failure code, selected allowed target, evidence, policy/approvals, and expected/new job sequence. Compare-and-swap SHALL permit one resume winner. Result canonicalization SHALL precede public-input reconstruction; submission-unknown SHALL query by transaction/body before replacement. On-chain replay protection SHALL NOT substitute for job idempotency.

#### Scenario: Restart occurs during an unknown submission
- **WHEN** the coordinator restarts while the destination may have accepted a persisted transaction body but no acknowledgement was retained
- **THEN** it SHALL query by transaction id or body digest before constructing any replacement

#### Scenario: Two relayers process one settlement
- **WHEN** two relayers observe the same settlement id concurrently
- **THEN** they SHALL converge on one durable settlement record and destination evidence SHALL show at most one authorized state transition

#### Scenario: Two job resumes race
- **WHEN** two authorized `JobResumeV1` records cite the same expected job sequence
- **THEN** exactly one MAY select an allowed retry target and the loser SHALL cause no proving, submission, or state effect

### Requirement: Chain-specific submission ownership
The Cardano and Midnight clients SHALL own transaction construction, submission-unknown recovery, confirmation tracking, and receipt emission under their registered ABI and confirmation profiles. The common coordinator SHALL NOT infer confirmation from a transport response.

#### Scenario: An acknowledgement is lost after submission
- **WHEN** a chain client times out after the transaction may have been accepted
- **THEN** it SHALL persist `submission-unknown` and query destination state before replacement

### Requirement: Versioned operational probes and metrics
Every immutable `RunIntentV1` SHALL bind one `OperationalProbeMetricProfileV1`, exact roster, root/activation, required component roles, endpoint intent, timeout/sampling/staleness/retry values, and one `EvidenceRetentionProfileV1`, with no observed result or receipt. `PreflightReceiptV1` SHALL bind the intent digest and observed `ProbeDiscoveryV1` records, checks, and results. `RunEvidenceManifestV1` SHALL bind the intent and ordered receipt/evidence digests. Every later receipt SHALL bind the same intent digest; no receipt or evidence-manifest digest SHALL occur in the intent preimage.

A valid healthy result with available required dependencies SHALL map to `healthy/ready`. Dependency timeout, transport failure, capacity exhaustion, and stale probes SHALL map to `unavailable/not-ready-unavailable`, stop new work, preserve safety state, and follow retry policy. A verifier self-check failure, integrity failure, authenticated conflict, or latched unsafe state SHALL map to `unsafe/not-ready-unsafe`, stop proving and submission, preserve evidence, and require registered recovery. Unsafe SHALL NOT be downgraded by outage or restart. Unknown, malformed, or unauthorized probe status SHALL map to unavailable. Unavailable SHALL NOT freeze a domain, and only registered authenticated evidence SHALL invoke the freeze rule.

Every structured event SHALL include bounded schema version, run/correlation/job/attempt ids, settlement id when known, direction, domain, profile, phase, owner, failure code, evidence digest, wall-clock timestamp, monotonic duration, and redaction status. Every metric id SHALL link through the metrics schema to a unit, numeric type, bounded label schema, collection interval, aggregation rule, and correlated event fields. Events and labels SHALL exclude credentials, secret handles, signing material, and private witnesses.

#### Scenario: An unavailable dependency is not reported as unsafe
- **WHEN** a required RPC or proof service times out without authenticated safety evidence
- **THEN** readiness SHALL be `not-ready-unavailable`, safety state SHALL remain unchanged, and the retry evidence SHALL use the registered profile

#### Scenario: An unsafe latch survives restart
- **WHEN** a component records a valid unsafe result and restarts before registered recovery
- **THEN** its readiness SHALL remain `not-ready-unsafe` and proving and submission SHALL remain stopped

#### Scenario: A retry crosses a process restart
- **WHEN** a retry resumes after restart
- **THEN** events SHALL retain the original job and settlement ids, use a new attempt id, and link the persisted failure and evidence digests

### Requirement: Evidence retention through outcome and gate review
Every run SHALL bind one `EvidenceRetentionProfileV1` containing evidence-class rules, outcome-review retention, unresolved-gate retention, content-addressed supersession, expiry evaluation, storage integrity and access, owners, and audit rules. Deployment policy SHALL fill actual durations and deadlines before the run begins. The public evidence index SHALL record content hash, length, media type, storage class, access method, retention deadline, profile digest, and independent verification command.

Required outcome evidence SHALL remain available through classification and independent review; expiry before that point SHALL make the run `blocked`. Resume evidence for an unresolved gate SHALL remain available until resolution or until an accepted content-addressed supersession record binds complete replacement evidence. Expiry without resolution or supersession SHALL return the gate to `unresolved` and stop dependent work.

#### Scenario: Required outcome evidence expires before review
- **WHEN** a receipt or witness required by the selected profile is unavailable before independent outcome review completes
- **THEN** classification SHALL return `blocked` even if the evidence passed an earlier check

#### Scenario: Unresolved-gate evidence expires without supersession
- **WHEN** a gate remains unresolved and its resume evidence expires without an accepted content-addressed replacement
- **THEN** the gate SHALL return to `unresolved` and dependent orchestration SHALL stop
