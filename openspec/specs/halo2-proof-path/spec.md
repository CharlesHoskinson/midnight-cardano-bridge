# halo2-proof-path Specification

## Purpose
TBD - created by archiving change sprint-01-foundation. Update Purpose after archive.
## Requirements
### Requirement: Cardano proof on Midnight
The Cardano-to-Midnight proof-of-concept path SHALL use the registered Midnight Halo2/Plonkish stack over BLS12-381. A deployed Midnight operation SHALL reconstruct the registered public inputs, verify the complete Cardano finality, SCLS inclusion, and predicate relation against the bound context, and atomically commit tracked Cardano state, application state, value state, and replay state. A non-value operation SHALL commit `ValueStateV1 = Absent(reason_code)` rather than omit that owner. Failure to demonstrate that an untrusted external proof can drive this execution surface SHALL keep the path blocked rather than infer support from proof-library availability.

#### Scenario: The Midnight operation checks the full Cardano statement and updates state atomically
- **WHEN** a claim supplies a registered Halo2/Plonk proof and the exact predecessor Midnight contract state
- **THEN** the Midnight operation SHALL verify the full Cardano statement and either commit all tracked, application, value, and replay updates together or commit none of them

### Requirement: Content-addressed Halo2 operation profile
The execution gate SHALL publish one versioned domain-neutral `SuiteNativeProofProfileV1` and one `DestinationAbiTemplateV1`. The suite-native profile SHALL be the sole owner of Halo2 proof framing and bounds, native public-instance count/order/field encoding, VK bytes and resolution grammar, scalar/field encoding, transcript and challenge schedule, curve/point and subgroup grammar, verifier equations, exact `[cardano_finality, scls_inclusion, cardano_predicate]` terminal-role adapters, and root-context proof constraints. The ABI SHALL reference that profile digest and byte-preservingly embed its native proof, instance, and VK values. The ABI SHALL own only the Midnight operation/call, predecessor/successor Cardano-source state, destination action, value, replay, transaction, resource, receipt, and stable-error wrappers; it SHALL NOT redefine or normalize a common or suite-native field. Both templates SHALL contain no root-set digest, deployment domain, registry activation, artifact authorization, concrete deployed operation, runtime state, or receipt.

After domain derivation, a chain-authenticated `DeploymentObservationV1` SHALL bind the operation template, deployment recipe, concrete deployed operation, deployed code hash, transaction, confirmation profile, and independent observations. `DestinationAbiInstanceV1` SHALL consume that record and bind the root-set digest, domain, registry activation, and artifact authorization root. Contract state SHALL store only `RootContextV1` and source/replay state; authenticated per-claim `ResolvedProofContextV1` SHALL select the suite-native profile and VK. Runtime payloads and receipts SHALL bind the ABI instance and resolved proof-context digests. Neither observation nor instance SHALL feed the operation template, checkpoint, registry or artifact template root, or deployment root set. Activation SHALL schema-walk all three ownership layers and reject any common or suite-native redefinition.

#### Scenario: A generic library proof does not satisfy the bridge gate
- **WHEN** a proof verifies in the underlying library but is not bound to the registered bridge operation profile, three-role graph, root context, or predecessor state
- **THEN** the Midnight operation SHALL reject it without changing tracked, application, value, or replay state

#### Scenario: External proof mutation commits no state
- **WHEN** a valid registered bridge vector mutates one proof-bound field, proof byte range, public instance, role or VK identity, root-context field, canonical typed result, or predecessor state
- **THEN** rejection SHALL occur at the declared stage and all four state owners SHALL remain unchanged
