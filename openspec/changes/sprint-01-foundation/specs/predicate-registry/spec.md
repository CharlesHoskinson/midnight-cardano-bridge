## ADDED Requirements

### Requirement: Authorized proof semantics
The destination SHALL resolve proof semantics from the active predicate-registry root and SHALL reject caller-selected proof artifacts. An accepted registry entry SHALL bind the predicate id and version, accepted anchor and finality rule, statement and result schemas, proof-suite id, circuit-architecture hash, complete verifier-key graph, SRS manifest and setup transcripts, proof-bound template selector, and deployment domain. Registry population SHALL remain blocked until a mechanical gate reports exactly 42 unique Cardano records and 52 unique Midnight records, no duplicate ids, and a provenance digest for every row; the system SHALL NOT invent or duplicate a row to satisfy either count.

#### Scenario: An unregistered VK, suite, architecture, or SRS is rejected
- **WHEN** a submitted claim names a verifier key, proof suite, circuit architecture, or SRS that is absent from or inconsistent with its active registry entry
- **THEN** the destination SHALL reject the claim even if its cryptographic proof would otherwise verify

#### Scenario: An incomplete predicate catalog blocks registry population
- **WHEN** the catalog gate finds a missing record, duplicate id, wrong Cardano or Midnight count, or absent provenance digest
- **THEN** registry population SHALL stop without synthesizing a replacement row
