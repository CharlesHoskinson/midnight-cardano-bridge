## ADDED Requirements

### Requirement: Independent structural harnesses
The repository SHALL provide Rust and Go commands that independently decode the
published `GateRosterV1`, reproduce its deterministic-CBOR bytes and SHA-256,
derive structural-lab root-set and deployment-domain vectors, and derive
domain-independent source-event continuity keys. The implementations SHALL share
only versioned fixtures and SHALL fail on byte, digest, field-order, forbidden
post-domain input, or reset-isolation disagreement.

#### Scenario: Both implementations reproduce one vector
- **WHEN** the Rust and Go commands consume the same valid structural fixture
- **THEN** they SHALL emit byte-identical roster, root-set, domain, and continuity digests

#### Scenario: A post-domain field enters the root set
- **WHEN** a fixture adds a deployment domain, activation, ABI instance, transaction, or receipt to a root-set preimage
- **THEN** both commands SHALL reject it before digest derivation

### Requirement: Reproducible conformance entry point
The repository SHALL provide one noninteractive command that runs Rust tests, Go
tests, Python observation-fixture tests, cross-language golden comparison, and
strict OpenSpec validation. It SHALL report each component and return nonzero on
the first failed contract without altering gate state.

#### Scenario: A golden digest is mutated
- **WHEN** the conformance command encounters a fixture whose expected digest differs from either implementation
- **THEN** it SHALL fail and SHALL NOT emit a deployment outcome label
