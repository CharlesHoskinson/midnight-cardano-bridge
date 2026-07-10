## ADDED Requirements

### Requirement: Full-decider BSB22 landing
The Midnight-to-Cardano proof-of-concept path SHALL use BSB22 commitment-Groth16 over BLS12-381 and SHALL prove the complete Halo2/KZG decision relation, including the final accumulator decider. The Plutus validator SHALL reconstruct the canonical `claim_digest` as an explicit Groth16 public input, and the wrapper SHALL constrain that value to the exact inner Halo2 statement and typed output; BSB22 commitment `D` SHALL NOT substitute for that equality. The suite SHALL bind its wire format, equations, commitment key, verifier-key graph, subgroup rules, KZG SRS, Groth16 setup, and transcripts independently. The gate SHALL reject a forged or invalid accumulator and report its measured resource profile; gate failure SHALL block this path and SHALL NOT silently select vanilla Groth16, native ECDSA, or direct Halo2 verification.

#### Scenario: An invalid KZG accumulator is rejected by the wrapped relation
- **WHEN** a BSB22 commitment-Groth16 proof contains or derives a forged or invalid KZG accumulator while its other claim inputs remain well formed
- **THEN** the full wrapped relation SHALL fail at the final decider and the Cardano validator SHALL reject the claim
