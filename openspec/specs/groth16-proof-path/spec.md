# groth16-proof-path Specification

## Purpose
TBD - created by archiving change sprint-01-foundation. Update Purpose after archive.
## Requirements
### Requirement: Full-decider BSB22 landing
The Midnight-to-Cardano proof-of-concept path SHALL use BSB22 commitment-Groth16 over BLS12-381 and SHALL prove the complete Halo2/KZG decision relation, including the final accumulator decider. The Plutus validator SHALL reconstruct the canonical `claim_digest` as an explicit Groth16 public input, and the wrapper SHALL constrain that value to the exact inner Halo2 statement and typed output; BSB22 commitment `D` SHALL NOT substitute for that equality. The suite SHALL bind its wire format, equations, commitment key, verifier-key graph, subgroup rules, KZG SRS, Groth16 setup, and transcripts independently. The gate SHALL reject a forged or invalid accumulator and report its measured resource profile; gate failure SHALL block this path and SHALL NOT silently select vanilla Groth16, native ECDSA, or direct Halo2 verification.

#### Scenario: An invalid KZG accumulator is rejected by the wrapped relation
- **WHEN** an instrumented canonical wrapper witness passes parsing, VK authorization, transcript, preparation, and accumulation preconditions but the authorized final KZG equation is false
- **THEN** the named final-decision constraint SHALL be unsatisfied and no valid outer proof SHALL be produced

### Requirement: Content-addressed complete-decider equivalence profile
The wrapper SHALL constrain one Boolean acceptance result to one only after exact proof and instance parsing with transcript exhaustion, outer and role-specific VK authentication, ordered recomputation of the three-role `claims_hash`, every required inner accumulator decision, outer PLONK preparation, accumulation with the exact outer-instance accumulator, and the final KZG equation under the authorized SRS subset. A content-addressed profile SHALL pin repository identities and commits, feature flags, toolchain or container, native verifier entry point and source inventory, proof and instance encodings, transcript schedule, accumulator types and encodings, every preparation/accumulation/final equation, Poseidon and VK-hash parameters, KZG verifier points and degree, circuit and constraint-system hashes, committed-wire manifest, native/circuit equivalence vectors, owners, enforcement loci, and independent reproduction receipts. Every VK, SRS point, and verifier parameter SHALL be a circuit constant or authenticated profile input.

#### Scenario: Prover-selected VK or SRS is rejected
- **WHEN** the prover substitutes an internally coherent VK, SRS subset, transcript profile, or accumulator parameter set
- **THEN** the wrapper SHALL fail its in-circuit registry/profile equality

#### Scenario: Final-decision and earlier-stage failures are distinct
- **WHEN** control vectors separately violate parsing, VK authorization, transcript, preparation, accumulation, and the final KZG equation
- **THEN** each vector SHALL reject at its declared stage, and only the last vector SHALL count as invalid-accumulator evidence

### Requirement: Complete BSB22 suite-native profile and committed-wire manifest
The domain-neutral BSB22 `SuiteNativeProofProfileV1` SHALL be the sole owner of proof, native-instance, VK, scalar/field, transcript, curve/point, subgroup, and verifier-equation grammar. It SHALL define `A:G1c[48] || B:G2c[96] || C:G1c[48] || D:G1u[96] || PoK:G1c[48]` for exactly 336 proof bytes. Its 672-byte committed VK SHALL contain `alpha:G1` at offset 0 length 48, `beta:G2` at 48 length 96, `gamma:G2` at 144 length 96, `delta:G2` at 240 length 96, `IC0:G1` at 336 length 48, `IC1:G1` at 384 length 48, `K2:G1` at 432 length 48, `CK.G:G2` at 480 length 96, and `CK.GSigmaNeg:G2` at 576 length 96. It SHALL define canonical 32-byte little-endian Fr `pub`, rejection at or above modulus `r` without reduction, exact curve flags, coordinate/sign rules, unique infinity encoding, canonicality/subgroup checks, `eCmt`, PoK, `vkX`, Groth16 pairing equations, and golden/malformed vectors. The Cardano `DestinationAbiTemplateV1` SHALL reference that suite-native digest and embed `pub`, proof, and VK bytes without reinterpretation. It SHALL own only Cardano datum, redeemer, continuing-output, reference-input, value, transaction, resource, receipt, and error wrappers. Neither template SHALL contain a root-set digest, deployment domain, activation, authorization, concrete validator instance, runtime state, or receipt.

After domain derivation, a chain-authenticated `DeploymentObservationV1` SHALL bind the Cardano ABI template, deployment recipe, concrete validator instance, deployed code hash, transaction, confirmation profile, and independent observations. Cardano `DestinationAbiInstanceV1` SHALL consume that record and bind the root-set digest, domain, registry activation, and artifact authorization root. Datum, redeemer, proof payload, continuing state, and receipt SHALL bind that instance digest. Continuing source state SHALL store no proof suite, architecture, VK, SRS, setup, transcript, or curve grammar; those are selected only by authenticated per-claim `ResolvedProofContextV1`. Activation SHALL reject any ABI redefinition or normalization of suite-native bytes. Neither observation nor instance SHALL feed the ABI template, checkpoint, semantic registry template root, artifact template root, or deployment root set.

The content-addressed committed-wire manifest SHALL bind wrapper source and R1CS hash, the single `D` commitment group, exact committed wire indices/order/types/semantics, blinding ownership, constraint locations for `pub == claim_digest`, outer-instance and canonical-result bindings, phase-2 transcript, and ceremony-output VK. Deployment SHALL require byte equality among ceremony output, ABI profile, registry slot, and deployed VK.

#### Scenario: Committed-wire layout mismatch blocks setup use
- **WHEN** a phase-2 or VK artifact uses a committed-variable map, wrapper R1CS, or public equality different from the registered manifest
- **THEN** deployment and suite activation SHALL reject it

#### Scenario: BSB22 parser and final-decider failures are distinct
- **WHEN** valid outer proof bytes are malformed after proof generation
- **THEN** Cardano SHALL reject at parsing, PoK, or pairing as declared and SHALL NOT credit the result as the final-KZG negative

### Requirement: Required Midnight proof roles cannot be omitted
The Midnight-to-Cardano aggregation profile SHALL require exactly `[midnight_finality, event_inclusion, midnight_predicate]`, one terminal statement and registered VK adapter per role, explicit count binding, fixed padding and empty behavior, bounded recursion, and the content-addressed Poseidon profile. It SHALL reject recomputed aggregates that omit, duplicate, reorder, or substitute a role.

#### Scenario: A recomputed aggregate omits one valid role
- **WHEN** an aggregate is rebuilt from otherwise valid statements and VKs but contains fewer than the three required terminal roles
- **THEN** aggregation and the wrapper SHALL reject it
