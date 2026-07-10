## ADDED Requirements

### Requirement: Canonical claim digest
Each proof suite SHALL define a domain-separated canonical transcript for every proof-bound claim field, including bounded types, units, byte order, length and integer limits, inclusive time comparisons, hash-to-field mapping, and rejection of aliases or trailing data. The destination verifier SHALL reconstruct `claim_digest` from that transcript and the proof relation SHALL constrain it to the exact finality, inclusion, predicate, typed-output, destination-context, expiry, replay, source-protocol-fingerprint, and deployment-domain statement. Validator-only or advisory fields SHALL be identified separately and SHALL NOT be interpreted as proof-bound.

#### Scenario: Mutating any proof-bound field changes verification
- **WHEN** a conformance case holds the proof fixed and mutates any field classified as proof-bound in the suite's field-binding matrix
- **THEN** the reconstructed `claim_digest` SHALL no longer match the proved public statement and verification SHALL reject the claim
