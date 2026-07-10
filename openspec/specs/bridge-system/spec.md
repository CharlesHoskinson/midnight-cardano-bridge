# bridge-system Specification

## Purpose
TBD - created by archiving change sprint-01-foundation. Update Purpose after archive.
## Requirements
### Requirement: Bidirectional typed claims
Under the named source-consensus and finality assumptions, the registered proof-suite soundness and setup-integrity assumptions, and the active destination policy, the bridge SHALL authorize a local state transition only after verifying a typed foreign-chain claim. Cardano facts sent to Midnight SHALL use the registered Halo2/Plonk proof path, and Midnight facts sent to Cardano SHALL use the registered full-decider BSB22 commitment-Groth16 proof path over BLS12-381. In either direction, the verifier SHALL bind the claim to the source network and protocol fingerprint, authenticated anchor, predicate and typed result, destination context, expiry, replay scope, root-set digest, deployment domain, registry activation, artifact authorization root, and destination ABI instance; a relayer, indexer, aggregator, or proof service SHALL NOT be treated as a root of trust.

#### Scenario: Each direction verifies a foreign claim before local authorization
- **WHEN** a Cardano-to-Midnight or Midnight-to-Cardano transaction requests authorization from a foreign-chain fact
- **THEN** the destination SHALL verify the direction's registered proof and every proof-bound claim field before authorizing the local state transition

### Requirement: Exact terminal semantic roles
The Cardano-to-Midnight architecture SHALL expose exactly one terminal statement for each role in `[cardano_finality, scls_inclusion, cardano_predicate]`, and the Midnight-to-Cardano architecture SHALL expose exactly one terminal statement for each role in `[midnight_finality, event_inclusion, midnight_predicate]`. Internal recursion or fusion MAY implement a role, but no proof-of-concept profile SHALL omit, duplicate, reorder, substitute, or add a terminal role. A source-dependent profile that lacks its versioned content-addressed artifact, accountable owner, enforcement locus, vector bundle, or activation evidence SHALL remain unavailable without selecting another proof path.

#### Scenario: A fused architecture still proves every required role
- **WHEN** an architecture uses one circuit or recursive graph to implement more than one semantic role
- **THEN** its registered adapter SHALL expose exactly one ordered terminal statement for each of the three required roles or suite activation SHALL fail
