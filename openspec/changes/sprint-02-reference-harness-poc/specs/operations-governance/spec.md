## ADDED Requirements

### Requirement: Non-activating structural hash profile
The reference harness SHALL identify its executable domain-vector profile as
`mcb.structural-lab.sha256-cbor.v1`. The profile SHALL use fixed deterministic
CBOR and SHA-256 solely to test dependency order, field ownership, mutation
behavior, and reset isolation. Each structural root, deployment-domain,
continuity, and gate-record-set digest preimage SHALL be
`u64_be(domain_byte_length) || UTF8(domain) || u64_be(body_byte_length) || body`.
The harness SHALL emit the canonical bodies and complete preimages as lowercase
hex so independent implementations compare bytes before comparing digests. All
digest-like fixture members are fixed lowercase hexadecimal text in this
diagnostic profile; they are not production typed byte strings. Every result SHALL carry
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

### Requirement: Structural outcome classifier vectors
The harness SHALL construct the ordered gate-record set from the exact 14-entry
published roster plus explicit fixture statuses, evidence-retention decisions,
the selected profile, and two direction-receipt states. It SHALL validate exact
gate ids, order, uniqueness, applicability, and status before applying the five
first-match `OutcomeClassifierV1` rows. The current base fixture SHALL select row
2 because all six `S01-BLOCK-*` and all eight `CONS-*` records are unresolved;
the result SHALL be `blocked`. Counts SHALL derive from those records, not from
roster membership alone. Rows 4 and 5 SHALL be exercised only as synthetic
`classifier_vector_label` values. They SHALL NOT change the structural report's
actual `deployment_outcome=blocked` or `activation_eligible=false`.

#### Scenario: All gates pass but a direction receipt is missing
- **WHEN** every selected-profile gate passes and either direction lacks a confirmed transition plus independent successor-state read
- **THEN** the classifier SHALL select row 3 and return `blocked`

#### Scenario: A gate record is missing or unknown
- **WHEN** the ordered record set differs from the published roster by id, order, count, duplicate, applicability, or unknown status
- **THEN** the classifier SHALL select row 1 and return `blocked`
