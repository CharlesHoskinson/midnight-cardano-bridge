## ADDED Requirements

### Requirement: Symmetric query and proof flow
The reference harness SHALL expose versioned query, claim-envelope, proof-response, result, verification, and submission interfaces with the same canonical statement rules in both bridge directions. For identical authenticated source facts, an offline-fixture adapter and a live-node adapter SHALL produce the same canonical query and public statement, including the source protocol fingerprint, anchor, predicate, proof-suite selection, typed result schema, destination context, expiry, replay scope, and deployment domain. Adapters, provers, and relayers SHALL remain untrusted data providers whose output is accepted only through destination verification.

#### Scenario: Offline and live adapters produce the same canonical statement
- **WHEN** offline and live adapters are given equivalent authenticated source data and the same versioned query
- **THEN** both adapters SHALL emit byte-identical canonical statement inputs and field elements for the selected proof suite
