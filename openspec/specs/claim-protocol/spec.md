# claim-protocol Specification

## Purpose
TBD - created by archiving change sprint-01-foundation. Update Purpose after archive.
## Requirements
### Requirement: Canonical claim digest
Each proof suite SHALL define a domain-separated canonical transcript for every proof-bound claim field, including bounded types, units, byte order, length and integer limits, inclusive time comparisons, hash-to-field mapping, and rejection of aliases or trailing data. The destination verifier SHALL reconstruct `claim_digest` from that transcript and the proof relation SHALL constrain it to the exact finality, inclusion, predicate, typed-output, destination-context, expiry, replay, source-protocol-fingerprint, and deployment-domain statement. Validator-only or advisory fields SHALL be identified separately and SHALL NOT be interpreted as proof-bound.

#### Scenario: Mutating any proof-bound field changes verification
- **WHEN** a conformance case holds the proof fixed and mutates any field classified as proof-bound in the suite's field-binding matrix
- **THEN** the reconstructed `claim_digest` SHALL no longer match the proved public statement and verification SHALL reject the claim

### Requirement: Acyclic proof-bound statement derivation
Each registered suite profile SHALL define a directed acyclic derivation from canonical proof-bound fields to `claim_digest`, from every terminal relation's public I/O to one role-tagged field statement, from the exact ordered role sequence and role-specific VK digests to `claims_hash`, and from root context, terminal outputs, `claims_hash`, canonical typed-result binding, destination context, expiry, and replay value to the outer public instance. `claim_digest` SHALL be destination-derived and SHALL NOT be a prover-supplied claim field. The common protocol SHALL define no generic public-input digest. Any suite-native instance digest SHALL name its exact producer, canonical preimage, consumers, wire or instance locations, types, encodings, bounds, and constraints, and its preimage SHALL exclude `claim_digest`, BSB22 `pub`, and every value derived from either. The profile SHALL identify the concrete producer, consumer, wire or instance location, type, encoding, bound, and constraint for every equality.

#### Scenario: Circular public-input definition blocks activation
- **WHEN** a suite profile includes `claim_digest`, BSB22 `pub`, an undefined derivative, or a cycle in the canonical claim preimage
- **THEN** registry activation SHALL reject the suite before any proof or predicate uses it

#### Scenario: Independent statement reconstruction agrees
- **WHEN** two registered independent encoders process a fixed positive claim, role-I/O, aggregation, and outer-instance vector
- **THEN** they SHALL produce identical canonical bytes and field elements at every declared derivation boundary

### Requirement: Canonical typed result precedes proof verification
After registry and suite resolution, the destination SHALL decode the result under the registered bounded schema, reject aliases, duplicates, unknown critical fields, out-of-range values, and trailing bytes, canonically re-encode the result, and use that same object for claim reconstruction, proof binding, policy, and action. Result failure SHALL occur before public-input reconstruction or proof verification and SHALL leave tracked source state, application state, value movement, and replay state unchanged.

#### Scenario: Malformed typed result fails before proof verification
- **WHEN** a fixed proof is paired with a noncanonical or schema-confused typed-result encoding
- **THEN** validation SHALL reject at the declared `typed-result-canonicalization` stage, SHALL prove that the proof verifier was not invoked, and SHALL record `NO_CHANGE` for all four state owners

### Requirement: Registry-owned query and resolution
`QueryV1` SHALL contain only schema version, requested predicate, bounded typed inputs, destination context, and optional constraints. Registry resolution SHALL own predicate version, anchor and finality rule, statement and result schemas, proof suite, every VK/SRS/setup profile, circuit architecture, destination verifier or operation, artifact graph, replay mode, and lifecycle. The canonical resolution SHALL also bind root-set digest, deployment domain, registry activation, artifact authorization root, and destination ABI instance. A query constraint SHALL only assert equality with a resolved value and SHALL NOT select authorization.

Each successful resolution SHALL produce `ResolvedProofContextV1` binding the deployment/source-only `RootContextV1`, predicate/version, schemas, anchor/finality, suite, architecture, ordered roles, artifacts, ABI/entry point, replay and destination policies, and exact source/destination time adapter digests, units, conversion, unsigned width, inclusive comparison, numeric bounds, era schedule, and expiry rule. The harness SHALL bind the published roster and authenticate registry resolution before preflight or source collection. It SHALL canonicalize the typed result before public-input reconstruction, verify the proof, authenticate source time from that proof, then perform final context, expiry, freshness, replay, and policy checks before the atomic transition. Advisory prechecks SHALL NOT accept or permanently reject.

Golden vectors for both directions SHALL publish the complete diagnostic value, canonical query bytes, canonical resolution bytes, record digests, resolved fields, and expected stage for every malformed or mismatched case. Two independent codecs SHALL reproduce the bytes and digests. Malformed-result vectors SHALL start from a valid golden resolution, prove every earlier precondition, expect `typed-result-canonicalization`, and SHALL NOT pass when rejection occurs during query decode or resolution.

#### Scenario: Two codecs resolve one query identically
- **WHEN** two independent implementations process a fixed query and the same active registry activation
- **THEN** they SHALL produce byte-identical query and resolution records and identical digests before source collection

#### Scenario: A malformed result fails at the wrong stage
- **WHEN** a malformed-result vector is rejected before its valid golden resolution or after proof verification begins
- **THEN** the execution SHALL not satisfy the vector

#### Scenario: One root context supports distinct authorized architectures
- **WHEN** two predicates in one deployment resolve to different suite and architecture pairs
- **THEN** both SHALL share byte-identical `RootContextV1`, use distinct `ResolvedProofContextV1` records, verify only under their own graphs, and reject a resolved-context swap

### Requirement: One deterministic wire owner
CDDL SHALL own bounded common record shapes, and `mcb.common-cbor.rfc8949-deterministic.v1` SHALL exclusively own hashable common bytes and domain separators. `QueryV1` SHALL be a five-element deterministic-CBOR array in declared field order. Query, resolution, resolved-proof-context, envelope, proof-response, result, verification, gate, submission, receipt, and vector records SHALL require definite lengths, preferred integer/length forms, deterministic map-key ordering, and rejection of duplicate keys, indefinite forms, tags, floating point, aliases, unknown critical fields, and trailing bytes. `SuiteNativeProofProfileV1` SHALL exclusively own native proof, instance, VK, scalar/field, transcript, curve/point, subgroup, and verifier-equation grammar. Common records SHALL carry those values only as typed native byte strings. An ABI SHALL reference the suite-native digest and embed those bytes unchanged; it SHALL own only chain wrappers. Neither SHALL redefine common framing or typed-result bytes. JSON SHALL remain diagnostic only. Rust, Go, and TypeScript codecs SHALL reproduce every common byte sequence and digest.

#### Scenario: An alternate valid CBOR spelling is supplied
- **WHEN** bytes represent the same data model using an unregistered or non-preferred CBOR spelling
- **THEN** canonical decoding SHALL reject before public-input reconstruction

#### Scenario: A suite attempts to redefine common framing
- **WHEN** a suite profile changes a `QueryV1` field, common record key/order, domain separator, or typed-result encoding
- **THEN** suite activation SHALL reject under the common-codec no-redefinition vector
