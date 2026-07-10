# settlement-protocol Specification

## Purpose
TBD - created by archiving change sprint-01-foundation. Update Purpose after archive.
## Requirements
### Requirement: Concurrent claim consumption
The settlement protocol SHALL support `advance-and-consume`, which advances from the exact predecessor light-client state and consumes a claim under the successor anchor, and `consume-current-anchor`, which leaves the tracked anchor unchanged and consumes a distinct message id or nullifier under the current anchor. Both transitions SHALL verify the registered proof and destination policy and SHALL atomically apply the destination action and replay update. A rejected or interrupted submission SHALL NOT consume replay state, an older anchor SHALL NOT be consumed after advancement, and submissions racing on one predecessor SHALL refresh or rebase without duplicating settlement.

#### Scenario: Distinct claims may consume one current anchor without duplicate settlement
- **WHEN** two valid claims reference the same current authenticated anchor and carry distinct registered message ids or nullifiers
- **THEN** each claim SHALL be independently consumable exactly once through `consume-current-anchor` without advancing the anchor or authorizing a duplicate settlement

### Requirement: Canonical typed result and four-owner atomicity
After registry resolution and before public-input reconstruction, each destination SHALL decode and canonically re-encode the typed result under its registered schema. The same object SHALL drive claim digest, proof binding, policy, and action. Tracked source state, destination application state, value movement, and replay state SHALL be the four atomic owners; every decode, authorization, proof, policy, construction, or action failure SHALL preserve all four predecessor digests.

The destination SHALL follow one authenticated order: roster/root binding; registry resolution and `ResolvedProofContextV1`; typed-result canonicalization; artifact authorization and public-input reconstruction; proof verification; proof-authenticated source-time extraction; final context, expiry, freshness, and replay checks; policy; atomic transition. Advisory prechecks SHALL NOT accept or permanently reject. A non-value action SHALL use explicit `ValueStateV1 = Absent(reason_code)`.

#### Scenario: Each proof-stage failure preserves the predecessor
- **WHEN** an executable vector rejects at any registered validation stage
- **THEN** it SHALL record `NO_CHANGE` for tracked, application, value, and replay state

#### Scenario: Cardano follows the global authenticated order
- **WHEN** an instrumented Cardano vector supplies a malformed typed result or a proof whose authenticated source time later fails freshness
- **THEN** malformed result SHALL fail before verifier invocation, while final context, freshness, replay, and policy SHALL run only after proof verification and all failures SHALL preserve all four owners

### Requirement: Registered replay modes
Each predicate SHALL declare exactly one replay mode: `message-id`, `nullifier`, or `both`. Registry resolution SHALL own that mode. The replay scope SHALL bind root-set digest, deployment domain, registry activation, artifact authorization root, destination ABI instance, destination network and concrete verifier or operation, source network and handler, lane, and predicate replay policy. Every proof SHALL also authenticate a domain-independent `SourceEventIdentityV1` and derive `continuity_key = Digest("mcb/continuity-key/v1", CanonicalEncode(SourceEventIdentityV1))`. The replay owner SHALL check and consume that key in `continuity_replay_root` atomically with the mode-specific key or keys. `SourceEventIdentityV1` SHALL contain no domain, activation, authorization, or destination-instance value. `both` SHALL check all three keys unused and consume all in one atomic transition. A caller nonce SHALL alter settlement identity only when the predicate semantics authorize it.

#### Scenario: One key is changed under both mode
- **WHEN** a settled claim is resubmitted with the same message id and a different nullifier, or the same nullifier and a different message id
- **THEN** settlement SHALL reject without changing tracked, application, value, or replay state

#### Scenario: A consumed event is re-proved after domain migration
- **WHEN** the same authenticated source event receives a fully valid new-domain proof under `message-id`, `nullifier`, or `both`
- **THEN** the identical imported `continuity_key` SHALL reject while an unrelated event with a distinct key SHALL pass the continuity check

### Requirement: Rebase follows proof binding
A stale job SHALL rebuild or reprove according to the field-binding matrix. If only replay state changes and is not proof-bound, the client MAY rebuild replay witness and transaction. If the source anchor advances, it SHALL refresh authenticated source data and regenerate every anchor-bound proof component. If only the predecessor output changes while representing the same anchor, it SHALL refresh predecessor and replay witnesses and rebuild. Domain or registered-root changes SHALL terminate the old job. Authenticated conflict SHALL freeze and require manual recovery.

#### Scenario: Another claim advances the anchor first
- **WHEN** a valid submission loses the predecessor race and the accepted anchor has advanced
- **THEN** the loser SHALL obtain authenticated successor data and regenerate the anchor-bound proof before resubmission

### Requirement: Destination ABI conformance
Each destination SHALL publish one versioned content-addressed `DestinationAbiTemplateV1`. It SHALL contain only the domain-neutral destination network identity, transition and state schemas, verifier or operation template hash, deployment recipe digest, references to common-record and suite-native schema/profile digests, chain-specific construction and runtime wrappers, resource-bound policy, receipt schema, and stable validation-stage and error mapping. The common CBOR profile SHALL exclusively own query, resolution, claim, typed-result, submission, and receipt bytes. `SuiteNativeProofProfileV1` SHALL exclusively own native proof, instance, VK, scalar/field, transcript, curve/point, subgroup, and verifier-equation grammar. The ABI SHALL reference that digest, embed its bytes unchanged, own only chain-specific datum, redeemer, call, predecessor/successor, value, transaction, and receipt wrappers, and SHALL NOT redefine or normalize a common or suite-native record. Activation SHALL run a no-redefinition schema walk, and nested-byte golden vectors SHALL cover all three layers. The template SHALL NOT contain a root-set digest, deployment domain, registry activation, artifact authorization, concrete deployed destination id, runtime state, transaction, or receipt.

After domain derivation, `DeploymentObservationV1` SHALL authenticate the fresh deployment instance id, concrete destination instance, and deployed code hash against the ABI template, verifier or operation template hash, deployment recipe, confirmed deployment transaction, and independent observations. `DestinationAbiInstanceV1` SHALL consume that record and bind the root-set digest, deployment domain, registry activation, and artifact authorization root. Claim authorization, exact predecessor state, construction payload, runtime call, expected successor commitments, and receipt SHALL bind that instance digest and the same `RootContextV1`. The Cardano template and instance SHALL own datum, redeemer, continuing-state, reference-input, value, collateral, execution-unit, and receipt encodings. The Midnight template and instance SHALL own deployed contract/program/operation resolution, operation call, proof/public-input/tracked-state encodings, fee/signing responsibilities, and finalized receipt extraction. Neither the observation, instance, nor either digest SHALL feed the ABI template, checkpoint, artifact template root, semantic registry template root, or deployment root set. No operation or chain encoding SHALL be inferred from library availability.

#### Scenario: A submission client uses a different state encoding
- **WHEN** a client constructs a predecessor, proof, action, replay, or successor representation that differs from the registered ABI vector
- **THEN** the destination SHALL reject it and all four state owners SHALL remain unchanged

#### Scenario: A valid ABI template is used under another instance
- **WHEN** a payload uses the registered ABI template but changes the deployment domain, concrete destination instance, deployed code hash, registry activation, or artifact authorization root
- **THEN** destination authorization SHALL reject before transition execution and all four state owners SHALL remain unchanged
