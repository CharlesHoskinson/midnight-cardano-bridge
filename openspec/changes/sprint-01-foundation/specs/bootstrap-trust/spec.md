## ADDED Requirements

### Requirement: Deployment-bound checkpoint
Checkpoint bootstrap SHALL be an explicit weak-subjectivity trust profile whose deployed verifier binds the complete approved checkpoint-manifest digest, source identity and protocol fingerprint, destination network, and deployment domain. The checkpoint profile SHALL define its approver keys and threshold, independent-node reproduction rule, finalized-point agreement rule, maximum age and lag, derivation procedure, and signature algorithm. A stale, mismatched, under-approved, alternate-checkpoint, or cross-domain proof SHALL be rejected, and replacement of a checkpoint SHALL create a new deployment domain rather than rewrite the active proof-of-concept trust root.

#### Scenario: A proof from another checkpoint or deployment domain is rejected
- **WHEN** a proof is valid relative to a checkpoint-manifest digest or deployment domain other than the values bound by the deployed verifier
- **THEN** verification SHALL reject the proof before any tracked consensus, application, or replay state changes
