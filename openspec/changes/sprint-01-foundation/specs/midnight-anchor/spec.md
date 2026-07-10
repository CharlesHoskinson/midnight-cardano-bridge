## ADDED Requirements

### Requirement: Authenticated Midnight event path
A Midnight event claim SHALL be authenticated through the registered BEEFY finality relation, the exact finalized header and MMR root, and a defined event-to-header-to-MMR inclusion path with fixed parent-block, leaf-encoding, and membership rules. The proof SHALL bind the current and next authority-set ids and roots, equal-weight proof-of-concept quorum rule, source-protocol fingerprint, finalized block, MMR root, event position, and deployment domain under the named BEEFY quorum and hash assumptions. A relay object or event payload without that authenticated path SHALL be insufficient, and the proof path SHALL remain blocked until the event-to-MMR gate has a rejecting prototype.

#### Scenario: A fact without an event-to-MMR path is rejected
- **WHEN** a submitted Midnight fact includes an event or relay object but lacks a valid path through its finalized header to the BEEFY-authenticated MMR root
- **THEN** the destination SHALL reject the fact before predicate evaluation or local authorization
