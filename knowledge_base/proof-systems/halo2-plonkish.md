---
type: Concept
title: PLONKish arithmetization (Halo2)
timestamp: '2026-07-09T14:20:58Z'
description: How Halo2's PLONKish arithmetization encodes circuits as a matrix of
  fixed/advice/instance columns with custom gates and lookup arguments, underpinning
  the Cardano to Midnight (Plonk/Halo2) proof direction.
resource: https://zcash.github.io/halo2/concepts/arithmetization.html
tags:
- halo2
- plonk
- plonkish
- arithmetization
- proof-system
- custom-gates
- lookups
source: src-0009
status: researched
okf_version: '1.0'
---

# PLONKish arithmetization (Halo2)

*Arithmetization* is the step that turns the statement you want to prove into an
algebraic object a proof system can operate on. Halo2's arithmetization is
**PLONKish**: it comes from **PLONK**, and more precisely its *UltraPLONK*
extension that adds **custom gates** and **lookup arguments**. This page
captures the shape of that encoding, which underpins the **Cardano → Midnight**
proof direction (Plonk/Halo2) in the recursive bridge study. See the
[knowledge base index](/index.md) and the [sources index](/sources/index.md).

## The circuit as a matrix

A PLONKish circuit is defined in terms of a **rectangular matrix of values**,
with the conventional notions of *rows*, *columns*, and *cells*. Cell values are
elements of a finite field F, and the number of rows n is typically a **power of
two** (it must be the size of a multiplicative subgroup of F×, which is what
makes the FFT-based polynomial machinery efficient).

Every column carries one of three roles:

- **Fixed** columns are fixed by the circuit itself (constants, and the
  *selectors* described below).
- **Advice** columns correspond to **witness** values — the prover's private
  data.
- **Instance** columns are normally used for **public inputs**, i.e. values
  shared between prover and verifier.

## Constraints: gates, lookups, and copies

Three constraint mechanisms sit on top of the matrix:

- **Polynomial constraints** are multivariate polynomials over F that must
  **evaluate to zero for each row**. A constraint's variables may reference a
  cell in the current row or in another row at a fixed relative offset (with
  wrap-around mod n), which is what lets a gate span adjacent rows. The
  *maximum constraint degree* in the configuration bounds these polynomials.
- **Lookup arguments** are defined over tuples of *input expressions* and
  *table columns*, letting the circuit assert that some combination of values
  appears in a precomputed table — cheap for otherwise expensive relations
  (range checks, bitwise ops, S-boxes).
- **Equality constraints** specify that two given cells must have **equal
  values** (copy constraints), wiring outputs of one region into inputs of
  another.

Polynomial constraints are switched off and on by **selectors** defined in fixed
columns: a constraint `q_i · p(…) = 0` is disabled on row *i* by setting
`q_i = 0`. A set of constraints controlled by selectors that are meant to be
used together is called a **gate**. There is typically a **standard gate** for
generic field arithmetic (multiplication, division) and, distinctively for
PLONKish, **custom gates** for more specialized operations.

From a circuit description Halo2 derives a **proving key** and a **verification
key** used for proving and verification of that circuit.

## Relevance to the Cardano → Midnight direction

The bridge study pairs two proof directions: **Groth16** for Midnight → Cardano
(compact, pairing-checkable proofs that Cardano's on-chain BLS12-381 primitives
verify), and **Plonk/Halo2** for Cardano → Midnight. The PLONKish structure is
what makes the second direction attractive:

- **Expressive encoding for verifier circuits.** Custom gates and lookup
  arguments let a circuit express expensive relations (hashes, elliptic-curve
  ops, range checks) far more compactly than a flat R1CS/QAP encoding of the
  Groth16 style, where every relation is reduced to rank-1 multiplication
  constraints. This matters when the statement being proved is itself a
  *verifier* — the core building block of a recursive/trustless bridge.
- **One universal setup, many circuits.** Because a PLONKish configuration is
  parameterized by columns, gates, and lookups rather than a circuit-specific
  structured reference string, the same setup serves many circuits — unlike
  Groth16, which needs a fresh per-circuit trusted-setup MPC. This is the
  property that makes iterated proof composition (recursion) practical on the
  Cardano → Midnight side.
- **Recursion-friendly shape.** The matrix/column model, deterministic key
  generation, and relative-offset constraints are the substrate on which
  Halo2-style accumulation and recursive verification are built, i.e. proving
  the correctness of a previous proof inside a new one.

> Note: this page is grounded in the Halo2 Book's *PLONKish Arithmetization*
> concept page, which defines the encoding but does not itself discuss trusted
> setup, R1CS, or recursion; those comparisons are synthesis drawn from the
> broader bridge study and should be corroborated against dedicated sources.
