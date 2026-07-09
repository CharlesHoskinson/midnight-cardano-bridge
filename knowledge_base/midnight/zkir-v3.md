---
type: Concept
title: ZKIR v3 — Midnight's zero-knowledge circuit IR (Compact → ZKIR → PLONK)
timestamp: '2026-07-09T16:10:09Z'
description: ZKIR v3 is the low-level, serialisable circuit IR that a Midnight (bridge)
  circuit compiles to, sitting between Compact and the PLONK proof system.
resource: https://github.com/midnightntwrk/midnight-ledger/blob/tna/feature-documentation-zkir_v3/spec/zkir.md
tags:
- midnight
- zkir
- zkir-v3
- circuit-ir
- plonk
- compact
- ledger-9
- elliptic-curve
- pr-617
source: src-0031
status: researched
okf_version: '1.0'
---

# ZKIR v3 — Midnight's zero-knowledge circuit IR (Compact → ZKIR → PLONK)

> **Provenance / status.** This page is researched from the ZKIR v3 spec in
> [Midnight ledger PR #617](https://github.com/midnightntwrk/midnight-ledger/blob/tna/feature-documentation-zkir_v3/spec/zkir.md)
> (open PR, base **ledger-9**). **ZKIR 3.0 is not yet frozen**: the spec itself
> states that the authoritative definition of 3.0 is the released
> `midnight-zkir-v3` crate, not the document — where the two disagree, the code
> wins. Treat instruction details here as provisional.

## What ZKIR is

**ZKIR** ("zero-knowledge intermediate representation") is the low-level,
serialisable representation of a Midnight circuit. It has two specified
serialised forms — a **JSON** representation and a **binary** representation —
and is the interchange format between the [Compact](/midnight/compact-circuits.md)
front-end and the PLONK proving system. (Internally the `zkir-v3` crate
deserialises ZKIR into an in-memory `IrSource` value, a Rust implementation
detail rather than the interchange format.)

## The compile → prove pipeline

The Compact compiler lowers each exported circuit to ZKIR JSON; the proving
stack then loads that ZKIR, synthesises it into a concrete PLONK circuit,
generates prover/verifier keys, and produces proofs:

```
Compact circuit ──compile──▶ ZKIR (JSON / binary) ──synthesise──▶ PLONK circuit ──prove──▶ Proof
```

ZKIR sits squarely between Compact and the proof system, which is why it is the
natural place to reason about a bridge circuit's cost and capabilities. See
[Midnight proofs & recursion](/midnight/midnight-proofs-recursion.md) for the
surrounding proving stack.

## Version and packaging (Ledger 9)

This spec describes **ZKIR version 3.0**, the IR defined by the `zkir-v3` crate
(`midnight-zkir-v3` **3.0.0-rc.2**), which is the version integrated into
**Ledger 9** — consumed by `proof-server` and published to JS/TS as
`@midnight-ntwrk/zkir-v3` (via the `zkir-v3-wasm` crate). The previous stable
line, ZKIR 2.x (`midnight-zkir` 2.2.0, published as `@midnight-ntwrk/zkir-v2`),
is what the current stable Compact toolchain emits and is retained only for
reference.

## Execution model: a typed register machine in SSA form

A ZKIR v3 program is a language for a **register machine**: a flat list of
instructions over a **named memory** of typed values, where the "registers" are
named variables. A variable is **written once and never reassigned (SSA by
name)** — each producing instruction reads its operands and binds its output(s)
to fresh, explicitly-named variables (`%name`); operands are either a variable
reference or an inline immediate (`0x…`), not the positional tape indices of v2.

A ZKIR circuit is consumed in **two passes**:

1. **Off-circuit preprocessing** (used by both `prove` and `check`) —
   concretely evaluates the program against a `ProofPreimage` to populate
   witness values and derive the public inputs (this is where most runtime
   error / UB rules are enforced).
2. **In-circuit synthesis** — emits the PLONK constraints that enforce each
   instruction, using the `midnight-zk` standard library
   ([`ZkStdLib`](/midnight/zk-stdlib-gadgets.md)).

## Instruction set

There are **33** v3 instructions, grouped into field/curve arithmetic,
boolean & selection, constraints & assertions, bit decomposition/comparison,
copies, encoding & type conversions, hashing, elliptic-curve operations, and
I/O + public inputs.

### Hashing

* `TransientHash` — **Poseidon** hash over the native scalar field; cheap
  in-circuit, for transient/ephemeral hashing.
* `PersistentHash` — **SHA-256** digest, bound as a single 32-byte `Bytes<32>`
  value; more expensive in-circuit, for stable cross-context digests.
* `Keccak256` — behaves as `PersistentHash` but computes the **Keccak-256**
  digest.

### Elliptic-curve operations

Values are typed, and the type system includes first-class **Jubjub** points and
scalars plus an emulated **SECP256k1** family (`Point<Secp256k1>`,
`Base<Secp256k1>`, `Scalar<Secp256k1>`) worked over the native field. Point
addition is `Add` on point operands; the dedicated EC instructions are:

* `EcMul { a, scalar }` — scalar multiplication of a point (`scalar · a`).
* `EcMulGenerator { scalar }` — multiplies the curve's fixed generator
  (`scalar · G`).
* `HashToCurve` — hashes native inputs onto a `JubjubPoint`.
* `IntoCoordinates` / `FromCoordinates` — convert between a point and its affine
  coordinates.

The emulated SECP256k1 support (points, base and scalar fields) plus the SHA-256
and Keccak-256 gadgets are exactly what let a Midnight circuit verify
**foreign-chain signatures and hashes in-circuit**.

## Relationship to the Impact VM and public inputs

The `Impact` instruction (together with the `PublicInput` / `PrivateInput`
transcript witnesses) is the channel between the proof and the on-chain VM: the
**public inputs a ZKIR proof commits to *are* the guarded Impact-VM operations**
the chain executes if the proof verifies. `Impact` subsumes v2's
`DeclarePubInput` + `PiSkip` pairing. ZKIR and the Impact VM are distinct
layers and should not be confused.

## Bridge relevance

For the [Midnight ↔ Cardano recursive trustless bridge](/bridges/midnight-cardano-recursive-bridge.md),
ZKIR is the layer a bridge verifier circuit is ultimately authored/compiled to.
A circuit that checks, e.g., a Cardano finality certificate needs to verify
foreign signatures and hashes; ZKIR v3's emulated **SECP256k1** elliptic-curve
instructions (`EcMul`, `EcMulGenerator`) together with its **SHA-256** and
**Keccak-256** hashing enable that foreign verification directly in-circuit,
with the resulting proof gating which Impact-VM operations reach the chain.

## Sources

- [Sources index](/sources/index.md) — `src-0031`
- Provenance: Midnight ledger PR #617 (open, base ledger-9),
  `spec/zkir.md` — ZKIR 3.0 not yet frozen; the released `midnight-zkir-v3`
  crate is authoritative.
- Knowledge base [index](/index.md)
