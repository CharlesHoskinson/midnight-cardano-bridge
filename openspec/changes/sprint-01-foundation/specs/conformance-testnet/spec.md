## ADDED Requirements

### Requirement: Authoritative gate roster
The testnet program SHALL use only `protocol/gate-roster-v1.json` as `GateRosterV1`. Its roster member SHALL decode from the published deterministic-CBOR bytes and match SHA-256 `2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f`. It SHALL contain exactly six `S01-BLOCK-*` and eight `CONS-*` entries with the published stable owner, interface, evidence, applicability, and activation ids. `RunIntentV1` SHALL bind its exact bytes and digest before preflight or source collection. The required evidence SHALL include the complete 94-row vector corpus, every proof-template family end to end, and predeclared performance policy/threshold receipts as mapped in that artifact. No prose table or activation ledger MAY relabel or extend it.

Each `GateDeliverableV1` SHALL copy the decoded entry's exact ordered `owners[]`, `interfaces[]`, `applicability`, `required_evidence[]`, and `activation_ref`. Any omission, addition, substitution, or order change SHALL fail exact-roster validation. Non-roster parties MAY be contributors or enforcement loci but SHALL NOT be gate owners.

#### Scenario: A roster entry is missing or changed
- **WHEN** a roster omits, duplicates, adds, or changes any gate key, owner, affected interface, applicability, evidence schema, or activation reference
- **THEN** exact-roster validation SHALL fail before outcome conditions are evaluated

### Requirement: Gate evidence includes coverage and predeclared performance
The roster-mapped evidence SHALL include schema, registry round-trip, positive, and required negative vectors for all 94 predicates; at least one end-to-end claim from every proof-template family; and `PerformanceThresholdReceiptV1` records for the full-decider, Midnight-execution, and Cardano-execution gates. `PerformancePolicyV1` SHALL fix metric ids/units, hardware disclosure, target parameters, sample/percentile method, proof/transaction limits, proving RAM/latency, verification limits, fees, and margin before measurement. Each receipt SHALL bind policy, suite/architecture, artifacts, raw-sample digest, computed metrics, threshold decisions, and independent reproduction.

#### Scenario: A threshold is chosen after measurement
- **WHEN** a performance receipt cites a policy created after its raw sample set or omits an independent reproduction
- **THEN** the mapped gate evidence SHALL be invalid

### Requirement: Versioned first-match outcome classifier
The testnet program SHALL predeclare a `public` or `lab` profile and SHALL use `OutcomeClassifierV1`. The classifier SHALL first validate exact `GateRosterV1` version and digest, complete key set, uniqueness, owners, interfaces, allowed applicability, evidence schemas, activation references, statuses, evidence digests, evidence-retention validity, and selected profile. Invalid, missing, duplicate, unknown, or unauthorized `not-applicable` gate records and missing or expired required outcome evidence SHALL select row 1 and return `blocked`.

After exact-roster validation, the classifier SHALL select the first matching row and stop: row 2 returns `blocked` when any selected-profile required gate is not `passed`, including unresolved, failed, mocked, or returned-to-unresolved status; row 3 returns `blocked` when either direction lacks a real destination transition confirmed under its registered profile and independent successor-state read; row 4 returns `degraded-lab` when the selected profile is lab; and row 5 returns `live-pass` when the selected profile is public. Exactly one row SHALL be selected through short-circuit evaluation; the classifier SHALL NOT require only one condition to be true. A lab profile MAY replace only the named public source root. A mocked proof relation, verifier, transaction, destination transition, or receipt SHALL NOT satisfy a required gate.

#### Scenario: Lab or blocked paths cannot be reported as live-pass
- **WHEN** deployment evidence contains a lab-only trust root or any unresolved hard gate in either proof direction
- **THEN** the program SHALL report `degraded-lab` or `blocked` as applicable and SHALL NOT report `live-pass`

#### Scenario: A lab trust root does not excuse a mocked transition
- **WHEN** both directions have named lab roots but either destination action or confirmation is mocked
- **THEN** classification SHALL return `blocked` and identify the missing real receipt

#### Scenario: A mocked lab gate selects the required-gate row
- **WHEN** a lab run uses the named root substitution and real destination transactions but any lab-required proof, consensus, catalog, execution, or receipt gate is mocked
- **THEN** the classifier SHALL select row 2 and return `blocked`

#### Scenario: Overlapping failures select the first row
- **WHEN** a run has a bad roster, an unresolved required gate, and a missing real transition
- **THEN** the classifier SHALL select row 1, return `blocked`, and SHALL NOT evaluate the later matching conditions

#### Scenario: Root-only lab substitution can degrade
- **WHEN** the exact lab roster marks only public SCLS availability as public-only, every required gate including catalogs and real lab certificate-to-SCLS mechanics passes, and both real destination transitions are independently confirmed
- **THEN** the classifier SHALL select row 4 and return `degraded-lab`

#### Scenario: Complete public evidence passes
- **WHEN** the exact public roster and every required gate pass and both real destination transitions are independently confirmed
- **THEN** the classifier SHALL select row 5 and return `live-pass`

#### Scenario: Required outcome evidence expires
- **WHEN** evidence required for a selected-profile gate or destination transition expires before classification and independent review complete
- **THEN** the classifier SHALL select row 1 and return `blocked`

#### Scenario: Unauthorized not-applicable is a bad roster
- **WHEN** any required entry is marked `not-applicable` or the public SCLS lab facet is encoded as `not-applicable` instead of `public-only`
- **THEN** the classifier SHALL select row 1 and return `blocked`

### Requirement: Independently verifiable destination receipts
Each direction SHALL produce a versioned receipt binding the immutable run-intent digest, run evidence manifest, correlation, profile, root-set digest, domain, root template, artifact template, activation manifest, registry activation, artifact authorization root, destination ABI instance, canonical query, resolution and claim, predicate and suite, destination identity, transaction id and body, confirmation profile and observations, concrete verifier or operation, predecessor and successor tracked/application/value/replay state, replay keys and result, fees and resources, raw evidence, evidence-retention profile, and independent query command and result. Cardano evidence SHALL also bind network magic and genesis, containing block and slot, state output references, validator/datum/redeemer/reference-input digests, execution units, value conservation, and its registered stability rule. Midnight evidence SHALL also bind genesis and chain spec, finalized block, deployed execution identifiers, public state or event digests, and its registered finalized-state query. Submission acknowledgement, mempool presence, or one indexer response SHALL not count as confirmation.

#### Scenario: A transaction id without confirmed state is insufficient
- **WHEN** evidence has a transaction id but lacks registered confirmation observations or independently read successor application and replay state
- **THEN** the direction and run SHALL remain `blocked`

### Requirement: Consensus bootstrap gates remain independently visible
Deployment evidence SHALL report `CONS-BOOT-01`, `CONS-CARDANO-01`, `CONS-BEEFY-01`, `CONS-CHECKPOINT-01`, `CONS-MIDNIGHT-ID-01`, `CONS-DOMAIN-01`, `CONS-FRESH-01`, and `CONS-FREEZE-01` with the exact ordered roster owners and interfaces, enforcement evidence, vectors, artifact digest, activation reference, retention status, and activation status. All eight gates SHALL be required for public and lab. A blocked source-native rule, missing independent vector implementation, unresolved equality, or expired unresolved-gate evidence without accepted supersession SHALL return the gate to unresolved, retain its reproducer and resume condition, and block the selected profile.

#### Scenario: A happy path cannot conceal a bootstrap gate
- **WHEN** a transaction succeeds but a required consensus gate lacks its canonical schema, source derivation, mutation vectors, or independent receipt
- **THEN** the classifier SHALL select required-gate row 2 and return only `blocked`

### Requirement: Rejection occurs at the intended validation stage
Every vector SHALL name fixture and trust profile, available predicate id or `structural-test-only`, deployment/trust/artifact/registry/suite/ABI digests, canonical input and expected field digests, predecessor tracked/application/value/replay state, exact mutation, required preconditions, expected stage and code, expected successors or `NO_CHANGE`, required gates, runner revision, reproduction command, and evidence digest. The runner SHALL prove all earlier prerequisites valid. Rejection at an earlier stage SHALL not satisfy the intended vector. Two independent runners SHALL reproduce each applicable vector, and structural vectors SHALL not count toward the unavailable 42/52 catalogs.

#### Scenario: A proof mutation fails during decoding
- **WHEN** a vector intended for proof verification instead fails an earlier decode check
- **THEN** that execution SHALL not satisfy the proof-verification vector

### Requirement: Reproducible endpoint, operational profile, and evidence index
Immutable `RunIntentV1` SHALL bind profile, roster, root/activation, `OperationalProbeMetricProfileV1`, health/readiness/metrics schemas, required component roles, endpoint intent, timeouts, sampling/staleness/retry values, and `EvidenceRetentionProfileV1` before preflight, with no observed result. `PreflightReceiptV1` SHALL bind the intent digest and observed Cardano and Midnight endpoint identities, revisions, interfaces, chain-sync status, commands, times, results, evidence, and one `ProbeDiscoveryV1` per component. `RunEvidenceManifestV1` SHALL bind the intent and ordered receipt/evidence digests. Every later receipt SHALL bind the same intent digest, and the intent preimage SHALL exclude all receipt and evidence-manifest digests.

Probe evidence SHALL map valid dependency failure to `unavailable/not-ready-unavailable` without safety-state change and valid unsafe verifier evidence to `unsafe/not-ready-unsafe` with proving and submission stopped until registered recovery. Unknown, malformed, or unauthorized status SHALL map to unavailable. Unsafe SHALL survive outage and restart and SHALL NOT be downgraded to unavailable.

The evidence index SHALL retain every referenced witness, artifact, raw receipt, gate-resume record, and log through its declared deadline with content hash, length, media type, storage class, access method, profile digest, and verification command. Required outcome evidence SHALL remain available through classification and independent review. Gate-resume evidence SHALL remain until resolution or accepted content-addressed supersession. Expired required outcome evidence SHALL be `blocked`; expired unresolved-gate evidence without supersession SHALL return that gate to `unresolved`. Credentials and secret handles SHALL remain in the private overlay.

#### Scenario: Cardano is identified only as Preview
- **WHEN** a run names Cardano Preview but omits endpoint or socket, genesis, revision, chain-sync observation, or preflight evidence
- **THEN** deployment preflight SHALL fail and the run SHALL remain `blocked`

#### Scenario: Unsafe and unavailable are not interchangeable
- **WHEN** one component has a transport timeout and another has a valid latched verifier self-check failure
- **THEN** conformance SHALL report the first as `not-ready-unavailable`, the second as `not-ready-unsafe`, and SHALL keep the unsafe latch through restart

#### Scenario: Unresolved-gate evidence expires
- **WHEN** a gate remains unresolved and its resume evidence expires without an accepted content-addressed supersession record
- **THEN** the gate SHALL return to `unresolved` and `OutcomeClassifierV1` SHALL return `blocked`
