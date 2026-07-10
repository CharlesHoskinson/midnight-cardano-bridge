## ADDED Requirements

### Requirement: Cardano proof on Midnight
The Cardano-to-Midnight proof-of-concept path SHALL use the registered Midnight Halo2/Plonkish stack over BLS12-381. A deployed Midnight operation SHALL reconstruct the registered public inputs, verify the complete Cardano finality, SCLS inclusion, and predicate relation against the bound bootstrap manifest, source-protocol fingerprint, proof artifacts, typed output, destination context, replay value, and deployment domain, and atomically update the tracked Cardano state, destination action, and replay state. Failure to demonstrate that an untrusted external proof can drive this execution surface SHALL keep the path blocked rather than infer support from proof-library availability.

#### Scenario: The Midnight operation checks the full Cardano statement and updates state atomically
- **WHEN** a claim supplies a registered Halo2/Plonk proof and the exact predecessor Midnight contract state
- **THEN** the Midnight operation SHALL verify the full Cardano statement and either commit all tracked-state, destination-action, and replay updates together or commit none of them
