---
type: Concept
title: Compact — circuits and witnesses (bounded ZK circuit model)
timestamp: '2026-07-09T14:19:56Z'
description: How the Compact compiler turns a contract into a fixed ZK circuit whose
  proof attests knowledge of the private witness data that produced the observed on-chain
  behavior.
resource: https://docs.midnight.network/blog/compact-2
tags:
- midnight
- compact
- circuits
- witness
- zk
- bounded
source: src-0008
status: researched
okf_version: '1.0'
---

# Compact — circuits and witnesses (bounded ZK circuit model)

The [Compact](/index.md) compiler turns each contract entry point into a
**circuit** and compiles the contract into JavaScript (the `index.cjs` output)
that implements those circuits and their witnesses. This page distills the
mechanics of that compiled model — what runs, what gets proven, and how public
values are separated from private ones — because those properties fix exactly
what statement a Midnight-side proof attests, and therefore what a
Midnight -> Cardano Groth16 proof could carry to a Cardano verifier.

## Execution and proving model

The big-picture flow for a circuit call (e.g. the tutorial's `post`
transaction) has two phases:

1. **Off-chain execution.** The generated JavaScript runs the circuit *with
   full access to the private state provided by its witnesses*, producing a
   result plus a `ProofData` record.
2. **Proof generation.** The **proof server** is then asked to generate a
   zero-knowledge proof that the circuit ran as expected. The statement proven
   is precisely: *we know the private data required to produce the observed
   on-chain behavior, without revealing that private data.*

That statement is the crux for the bridge. A Midnight proof is a proof of
**knowledge of a private witness** that drives a fixed circuit to a particular
public (on-chain) effect — not an arbitrary open-ended computation. Any Groth16
re-proving of the Midnight side has to attest that same shape of statement.

## Bounded / fixed circuit shape

Compact circuits behave as fixed-size arithmetic circuits rather than
data-dependent programs. When a circuit runs off chain, some conditional
branches are skipped, and the proof then **requires 'dummy' data to fill in for
branches that were not taken**. Padding untaken branches with dummy data is the
tell-tale of a statically-bounded circuit: every branch is accounted for in the
constraint system regardless of the concrete input, so the circuit (and its
proof) has a bounded, input-independent size. This is what makes Compact
statements expressible as a single fixed Groth16 instance.

## Public vs. private: transcripts and witnesses

The `ProofData` record separates a **public transcript** from
**private transcript outputs**:

- A **witness** is a function supplying private inputs. It is invoked with a
  `WitnessContext` that contains the public ledger, the current private state,
  and the contract's address — so a witness can read public state but returns
  private values.
- Each witness's return value is recorded in the proof data's **private
  transcript** while running the outermost circuit call. This value is private
  data that the proof server must know so that it can *prove it knows the
  private data*.
- Public inputs, by contrast, are the on-chain (ledger) values in the public
  transcript, input, and output.

For the bridge this is the public-input boundary: only the public-transcript /
input / output values are visible to a verifier, so those are the only fields a
Cardano-side Groth16 verifier could bind to. Witness values stay private on
both chains.

## Value encoding (public inputs)

Compact keeps two representations of every value: native JavaScript objects, and
a binary **on-chain ledger encoding** whose `Value` type is an array of
`Uint8Array`s (`type Value = Uint8Array[]`). **Descriptors** (objects
implementing `CompactType`, with `toValue` / `fromValue` / `alignment`) convert
between the two. Because the public inputs a verifier sees are these tagged
byte-array ledger values, any cross-chain verifier must agree on the same
alignment/encoding to reconstruct the public signals a Groth16 proof commits to.

## Composition and soundness

- **Composition.** When one Compact circuit calls another, the callee is
  considered part of the *same transaction* being constructed (and the inner
  call reuses the same `ProofData` rather than boxing up a fresh proof). So a
  transaction's proof can span composed circuits within one proving unit.
- **Soundness.** The generated code performs runtime type checks on witness
  return values and circuit arguments; Compact's type safety depends on these
  runtime checks. This is what lets the proof meaningfully attest a
  *well-typed* execution rather than arbitrary bytes.

## Relevance to the Midnight -> Cardano leg

- The proven statement is knowledge-of-witness for a **fixed circuit** — a
  natural fit for Groth16, which proves satisfaction of a fixed R1CS/QAP.
- The **public/private split** (public transcript vs. private transcript) maps
  directly onto Groth16's public-inputs vs. witness split; only ledger-encoded
  public values can become public signals on the Cardano side.
- The **ledger encoding** (`Uint8Array[]` with alignment) is the canonical form
  of those public signals and must be reproduced by any verifier.

See the [sources index](/sources/index.md) and the [knowledge base
index](/index.md) for related Groth16-on-Cardano material.
