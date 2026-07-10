## ADDED Requirements

### Requirement: Immutable PoC roots
Within a proof-of-concept deployment domain, the checkpoint digest, finality adapter, anchor profile, proof-suite and artifact-binding graph, VK and SRS set, predicate-registry root, verifier hash, and recovery-policy hash SHALL be immutable. Replacing any such root, performing a testnet reset, or activating a conflicting source-protocol fingerprint SHALL create a new deployment domain and SHALL cause old-domain proofs to be rejected. Conflicting finality evidence or an unknown, downgraded, or mismatched fingerprint SHALL freeze the affected domain for governance review without rolling back an accepted anchor or bypassing the registered recovery policy.

#### Scenario: Replacing a PoC root requires a new deployment domain
- **WHEN** an operator proposes to replace any proof-of-concept trust, proof, or policy root
- **THEN** deployment tooling SHALL derive a new deployment domain and conformance SHALL demonstrate rejection of proofs bound to the prior domain
