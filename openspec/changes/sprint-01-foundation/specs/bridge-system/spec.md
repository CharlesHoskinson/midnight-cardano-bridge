## ADDED Requirements

### Requirement: Bidirectional typed claims
Under the named source-consensus and finality assumptions, the registered proof-suite soundness and setup-integrity assumptions, and the active destination policy root, the bridge SHALL authorize a local state transition only after verifying a typed foreign-chain claim. Cardano facts sent to Midnight SHALL use the registered Halo2/Plonk proof path, and Midnight facts sent to Cardano SHALL use the registered full-decider BSB22 commitment-Groth16 proof path over BLS12-381. In either direction, the verifier SHALL bind the claim to the source network and protocol fingerprint, authenticated anchor, predicate and typed result, destination context, expiry, replay scope, and deployment domain; a relayer, indexer, aggregator, or proof service SHALL NOT be treated as a root of trust.

#### Scenario: Each direction verifies a foreign claim before local authorization
- **WHEN** a Cardano-to-Midnight or Midnight-to-Cardano transaction requests authorization from a foreign-chain fact
- **THEN** the destination SHALL verify the direction's registered proof and every proof-bound claim field before authorizing the local state transition
