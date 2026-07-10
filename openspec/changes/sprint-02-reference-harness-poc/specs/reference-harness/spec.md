## ADDED Requirements

### Requirement: Independent structural harnesses
The repository SHALL provide Rust and Go commands that independently decode the
published `GateRosterV1`, reproduce its deterministic-CBOR bytes and SHA-256,
derive structural-lab root-set and deployment-domain vectors, and derive
domain-independent source-event continuity keys. The implementations SHALL share
only versioned fixtures. They SHALL validate closed structural root-set and
`SourceEventIdentityV1` schemas, reject unknown fields, and validate an explicit
producer DAG before encoding. A cycle, unresolved producer, non-forward edge,
post-domain producer, byte mismatch, digest mismatch, field-order mismatch, or
reset-isolation disagreement SHALL fail with a stable error code.

#### Scenario: Both implementations reproduce one vector
- **WHEN** the Rust and Go commands consume the same valid structural fixture
- **THEN** they SHALL emit byte-identical roster, root-set, event, and reset CBOR plus byte-identical framed hash preimages and digests

#### Scenario: A post-domain field enters the root set
- **WHEN** a fixture adds a deployment domain, activation, ABI instance, transaction, or receipt to a root-set preimage
- **THEN** both commands SHALL reject it before digest derivation

#### Scenario: A transitive producer crosses the domain boundary
- **WHEN** an otherwise permitted root member names a producer with a cycle, unresolved dependency, back edge, or post-domain dependency
- **THEN** both commands SHALL reject the producer DAG and SHALL NOT emit `structural-pass`

#### Scenario: A domain field enters a source-event identity
- **WHEN** a source-event identity adds any root, domain, activation, authorization, destination-instance, or unknown field
- **THEN** both commands SHALL reject it before continuity-key derivation

#### Scenario: A source-event index member is absent
- **WHEN** a `SourceEventIdentityV1` omits `source_action_or_event_index`
- **THEN** both commands SHALL reject it with `source-event-schema` and SHALL NOT treat absence as an explicit index zero

### Requirement: Reproducible conformance entry point
The repository SHALL provide one noninteractive command that runs control-test
scripts without recursive verifier invocation, Rust tests, Go tests, Python
observation-fixture tests, cross-language golden comparison, and strict OpenSpec
validation. It SHALL report each component and return nonzero on the first
failed contract without altering gate state. The default command SHALL perform
no network request, SHALL set `OPENSPEC_TELEMETRY=0` and `DO_NOT_TRACK=1` before
every OpenSpec invocation, and SHALL stage generated evidence outside the
repository. It SHALL publish or replace committed evidence only after every
check succeeds, and only under an explicit update mode.

Committed evidence uses one structural payload plus one conformance envelope.
The structural report is the structural payload and need not duplicate execution
bindings. The conformance envelope SHALL bind the structural payload by SHA-256,
plus the input-file hashes, verifier revision, structured command records, tool
versions, and final result needed to distinguish it from a stale prior run.
Readers SHALL select the current generation only through
`reference/evidence/current-generation.json` and SHALL reject missing, mixed, or
hash-mismatched generations.

#### Scenario: A golden digest is mutated
- **WHEN** the conformance command encounters a fixture whose expected digest differs from either implementation
- **THEN** it SHALL fail and SHALL NOT emit a deployment outcome label

#### Scenario: A check fails after cross-language comparison
- **WHEN** roster, observation, OpenSpec, or repository validation fails after a temporary structural report was generated
- **THEN** the command SHALL return nonzero, emit no pass or deployment label, leave committed evidence byte-identical, and remove the temporary run directory

#### Scenario: OpenSpec telemetry is disabled
- **WHEN** the conformance command discovers OpenSpec or runs strict validation
- **THEN** the process environment SHALL contain `OPENSPEC_TELEMETRY=0` and `DO_NOT_TRACK=1`

#### Scenario: A stale structural payload is presented
- **WHEN** the structural payload hash in the conformance envelope does not match the structural file selected by the current generation
- **THEN** the command SHALL fail and SHALL NOT treat the pair as current
