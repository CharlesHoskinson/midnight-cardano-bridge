## ADDED Requirements

### Requirement: Non-activating structural hash profile
The reference harness SHALL identify its executable domain-vector profile as
`mcb.structural-lab.sha256-cbor.v1`. The profile SHALL use fixed deterministic
CBOR, fixed domain strings, and SHA-256 solely to test dependency order, field
ownership, mutation behavior, and reset isolation. Every result SHALL carry
`activation_eligible = false` until the source-backed `CONS-DOMAIN-01` artifact
selects and authorizes a production profile.

#### Scenario: Structural roots derive consistently
- **WHEN** both implementations derive a root-set digest and deployment domain from one permitted fixture
- **THEN** the values SHALL match and SHALL be marked non-activating

#### Scenario: A caller requests activation
- **WHEN** a caller attempts to use the structural profile in an activation decision or chain submission
- **THEN** the harness SHALL reject the request with `structural-profile-not-activating`

### Requirement: Reset and continuity vectors
The structural profile SHALL prove that changing the fresh deployment instance
id changes root-set and domain digests while leaving domain-independent
`SourceEventIdentityV1` continuity keys stable. It SHALL reject a migrated event
already present in the imported continuity set and accept an unrelated event.

#### Scenario: A consumed event is reproved after reset migration
- **WHEN** a new-domain structural claim carries the same authenticated source-event identity as an imported consumed event
- **THEN** replay evaluation SHALL reject it while an unrelated source-event identity remains unused
