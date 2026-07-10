## ADDED Requirements

### Requirement: Authenticated Midnight event path
A Midnight event claim SHALL be authenticated through the registered BEEFY finality relation, the exact finalized header and MMR root, and a defined event-to-header-to-MMR inclusion path with fixed parent-block, leaf-encoding, and membership rules. The proof SHALL bind the current and next authority-set ids and roots, equal-weight proof-of-concept quorum rule, source-protocol fingerprint, finalized block, MMR root, event position, and deployment domain under the named BEEFY quorum and hash assumptions. A relay object or event payload without that authenticated path SHALL be insufficient, and the proof path SHALL remain blocked until the event-to-MMR gate has a rejecting prototype.

#### Scenario: A fact without an event-to-MMR path is rejected
- **WHEN** a submitted Midnight fact includes an event or relay object but lacks a valid path through its finalized header to the BEEFY-authenticated MMR root
- **THEN** the destination SHALL reject the fact before predicate evaluation or local authorization

### Requirement: Cryptographic Midnight source identity
Every Midnight bootstrap SHALL bind a canonical genesis block hash, canonical genesis state or header digest, exact chain-spec artifact digest, chain-spec derivation adapter, required source-native network identifiers, source release, and complete initial BEEFY descriptor. The initial descriptor SHALL be either derived from the exact chain-spec bytes by a pinned adapter that proves ordered keys and equal-unit values, or labeled and approved as an independent authority root. RPC names and display labels SHALL be advisory. AURA production, GRANDPA local finality, and ECDSA BEEFY destination attestation SHALL remain distinct roles, and no BABE or direct GRANDPA verification assumption SHALL be introduced.

#### Scenario: A display-name match is not chain identity
- **WHEN** a source reports the expected network name but differs in genesis, chain-spec bytes, native identifiers, source release, initial set id/root/count, key order, value, or derivation mode
- **THEN** bootstrap and every proof under that identity SHALL reject

### Requirement: Complete equal-unit BEEFY authority state
The BEEFY relation SHALL bind complete current and announced-next descriptors containing set id, authority root, authority count, `EqualUnit` weighting model, authority-leaf encoding, Keccak commitment rule, ECDSA secp256k1 signature suite, and strict-more-than-two-thirds quorum. For count `N`, quorum SHALL require `floor((2*N)/3)+1` distinct, in-range, membership-authenticated valid signers. `N = 0`, checked-arithmetic failure, duplicate or out-of-range indices, invalid paths, a multiproof total-leaf count different from `N`, or an insufficient quorum SHALL reject. Bootstrap and each transition SHALL use the complete ordered authority list to recompute root and count and prove every native value is exactly one.

#### Scenario: A next root cannot be activated with another count
- **WHEN** a proof uses an authenticated next authority root with a different count, weighting model, value, or quorum denominator
- **THEN** the authority transition SHALL reject without changing tracked state

### Requirement: Mandatory-block BEEFY handoff
The finality relation SHALL bind the signed commitment's validator-set id, block number, and single canonical `MMR_ROOT_ID` payload to the current descriptor and exact successor finalized block id, block number, and MMR root. Authority rotation SHALL pass only through the source-derived mandatory-block adapter authenticated by the outgoing set. The handoff SHALL authenticate the full successor descriptor, pending activation point, exact MMR leaf and root, signing set, successor-id rule, and first valid activation commitment. Skipped ids, root/count substitution, early or late activation, a nonmandatory leaf, the wrong signing set, or a successor different from pending state SHALL reject without state change.

#### Scenario: A nonmandatory or skipped handoff is rejected
- **WHEN** an otherwise valid BEEFY commitment proposes a transition not allowed by the registered mandatory-block rule
- **THEN** the destination SHALL retain the prior current, next, and pending descriptors

### Requirement: Event inclusion remains a content-addressed gate
The event-to-header-to-MMR adapter SHALL remain inactive until its versioned artifact names the source and adapter owners, pinned source rules, enforcement between `midnight_finality` and `midnight_predicate`, canonical encodings, parent rule, vector bundle, independent reproduction receipts, and activation rule. The gate SHALL mutate event bytes and position, containing object, header, parent mapping, leaf, MMR size and path, root, finalized block, fingerprint, and domain.

#### Scenario: Relay serialization cannot close event inclusion
- **WHEN** a relay object has a valid BEEFY commitment and authority proof but lacks the registered event inclusion artifact and path
- **THEN** the `event_inclusion` role SHALL remain unavailable
