## ADDED Requirements

### Requirement: Executable BSB22 native-byte parser
The Go reference harness SHALL parse the exact 336-byte BSB22 proof and 672-byte
committed VK grammar from `SuiteNativeProofProfileV1`, expose each field at its
registered offset and length, require a 32-byte little-endian public scalar below
the BLS12-381 scalar modulus without reduction, and reject length, scalar,
trailing-byte, and offset mutations. The parser SHALL NOT claim subgroup checks,
pairing verification, full-decider soundness, or Cardano execution.

#### Scenario: Exact zero-filled layout is split by offsets
- **WHEN** the parser receives exact-length structural proof and VK fixtures plus a canonical scalar
- **THEN** it SHALL return every registered field with the exact offset and length

#### Scenario: Public scalar equals the modulus
- **WHEN** the parser receives the canonical little-endian encoding of modulus `r`
- **THEN** it SHALL reject the scalar without reducing it

#### Scenario: Parser conformance passes
- **WHEN** every byte-layout test passes
- **THEN** `S01-BLOCK-04` and `S01-BLOCK-06` SHALL remain unresolved
