## ADDED Requirements

### Requirement: Named Cardano trust profile
Every Cardano anchor SHALL name its Cardano identity, Mithril certificate-chain and aggregate-verification-key trust assumptions, signed-entity type, SCLS version and namespace rules, source-protocol fingerprint, and anchor-profile version. A public-testnet profile SHALL describe a Mithril-certified SCLS artifact only when an accepted public Mithril signer population certifies that exact SCLS signed-entity type. A project-operated signer population SHALL use a distinct lab anchor profile, SHALL NOT be represented as public-testnet consensus, and SHALL limit the program outcome to `degraded-lab`. Until the public SCLS profile is confirmed, the public-testnet path SHALL remain a hard gate.

#### Scenario: A project-operated signer proof cannot claim public-testnet trust
- **WHEN** a Cardano fact is certified by a project-operated signer population rather than the accepted public Mithril signer population for the required SCLS signed-entity type
- **THEN** the verifier or evidence reporter SHALL classify it under the lab anchor profile and SHALL NOT accept or report it as a public-testnet `live-pass`
