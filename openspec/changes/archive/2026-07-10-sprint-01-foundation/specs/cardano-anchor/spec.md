## ADDED Requirements

### Requirement: Named Cardano trust profile
Every Cardano anchor SHALL name its Cardano identity, Mithril certificate-chain and aggregate-verification-key trust assumptions, signed-entity type, SCLS version and namespace rules, source-protocol fingerprint, and anchor-profile version. A public-testnet profile SHALL describe a Mithril-certified SCLS artifact only when an accepted public Mithril signer population certifies that exact SCLS signed-entity type. `S01-BLOCK-02/public-scls-availability` SHALL be required for public and public-only for lab. A project-operated signer population SHALL use a distinct lab anchor profile, SHALL NOT be represented as public-testnet consensus, and MAY qualify for `degraded-lab` only when `S01-BLOCK-01`, every other lab-required gate, real certificate-to-SCLS mechanics under `CONS-CARDANO-01`, and both real confirmed destination transitions pass; otherwise the outcome SHALL be `blocked`. A mocked relation, verifier, transaction, transition, or receipt SHALL NOT satisfy the lab profile. Until the public SCLS profile is confirmed, the public-testnet path SHALL remain a hard gate.

#### Scenario: A project-operated signer proof cannot claim public-testnet trust
- **WHEN** a Cardano fact is certified by a project-operated signer population rather than the accepted public Mithril signer population for the required SCLS signed-entity type
- **THEN** the verifier or evidence reporter SHALL classify it under the lab anchor profile and SHALL NOT accept or report it as a public-testnet `live-pass`

### Requirement: Mithril signed message equals the SCLS entity
The Cardano finality relation SHALL derive `CardanoIdentityDescriptorV1` from pinned network magic/id, Byron and Shelley genesis-configuration hashes, era history, protocol-parameter transition adapter, Mithril network id, and identity adapter. It SHALL parse and canonically check the SCLS artifact, recompute its artifact digest, slot, namespace-set commitment, and global root, construct the registered descriptor containing that identity digest and Mithril bootstrap profile, and project it through a pinned source-native adapter into the exact Mithril signed-message bytes. Those bytes SHALL equal the certificate protocol-message field. The SCLS inclusion relation SHALL consume the same identity, slot, namespace commitment, artifact digest, and root without alternate caller-supplied copies. Consensus, identity, circuit, anchor, tree-profile, and conformance owners SHALL enforce the equality and provide two independent message encoders.

#### Scenario: A certified message cannot be paired with another SCLS artifact
- **WHEN** a valid Mithril certificate and an independently valid SCLS artifact do not produce identical registered signed-entity message bytes
- **THEN** the composed proof SHALL reject before SCLS inclusion or predicate output

#### Scenario: One signed-entity descriptor field changes
- **WHEN** the certificate is fixed and the bootstrap profile, entity tag, format version, slot, SCLS version, namespace set, root, artifact digest, projection adapter, or Cardano identity is mutated
- **THEN** certificate-to-SCLS equality SHALL reject before predicate evaluation

### Requirement: Exact SCLS membership and nonmembership semantics
`SclsTreeProfileV1` SHALL fix the complete namespace manifest and order, canonical namespace/key/value bytes, live-entry/tombstone rule, Blake2b-224 leaf and internal domain bytes, child order, empty root, odd-node and power-of-two padding, depth/count bounds, path-direction encoding, namespace-root leaves, and global-tree construction. Membership SHALL authenticate the live entry to its namespace root and that namespace root to the certified global root. Nonmembership SHALL authenticate exactly one of empty namespace, before-first, between-consecutive-neighbors, or after-last under the same namespace and global roots; mere absence of membership SHALL NOT prove nonmembership.

#### Scenario: A nonadjacent range does not prove absence
- **WHEN** a nonmembership witness supplies ordered live neighbors whose authenticated indices are not consecutive
- **THEN** the SCLS relation SHALL reject before predicate evaluation

#### Scenario: Every tree and identity boundary is tested
- **WHEN** activation evidence omits identity/genesis, descriptor/message equality, empty/singleton/odd/padded tree, min/max key, namespace completeness, tombstone, direction, depth, index, adjacency, or cross-root mutation vectors, or two independent tree encoders
- **THEN** `CONS-CARDANO-01` SHALL remain unresolved under the published roster
