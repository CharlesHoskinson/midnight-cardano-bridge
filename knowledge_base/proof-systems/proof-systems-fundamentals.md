---
type: Concept
title: Proof-system fundamentals: NIZK, SNARKs, soundness, zero-knowledge
timestamp: '2026-07-09T14:19:48Z'
description: Shared proof-system vocabulary (statement, witness, soundness, knowledge
  soundness, zero knowledge, SNARK) grounding both directions of the recursive Midnight<->Cardano
  bridge.
resource: https://zcash.github.io/halo2/concepts/proofs.html
tags:
- proof-system
- nizk
- snark
- zero-knowledge
- soundness
- witness
source: src-0010
status: researched
okf_version: '1.0'
---

# Proof-system fundamentals: NIZK, SNARKs, soundness, zero-knowledge

This page fixes the shared vocabulary that both legs of the recursive
Midnight<->Cardano bridge are built on. The source is the halo2 Book's
["Proof systems" concept page](https://zcash.github.io/halo2/concepts/proofs.html)
(`src-0010`), which uses terminology aligned with the ZKProof Community Reference.
See the [sources index](/sources/index.md) and the
[knowledge base index](/index.md) for related material. The concrete Plonkish/Halo2
instantiation of these terms lives in
[Halo2 / Plonkish arithmetization](/proof-systems/halo2-plonkish.md).

Both bridge directions are proof systems in exactly this sense, so pinning down the
terms once avoids re-deriving them per leg: **Groth16** on the Midnight -> Cardano
leg and **Plonk/Halo2** on the Cardano -> Midnight leg are both zk-SNARKs. They
differ in setup and arithmetization, not in the core statement/witness/soundness
contract described here.

## The core objects

- **Proof system / statement.** The aim of a proof system is to prove mathematical
  or cryptographic **statements**. A protocol proves *families* of statements that
  differ in their **public inputs**; the prover must also know **private inputs**
  that make the statement hold.
- **Relation and circuit.** A **relation** `R` specifies which combinations of
  public and private inputs are valid. Its concrete implementation inside a proof
  system is a **circuit**; the language used to express circuits is an
  **arithmetization** (typically polynomial constraints over a field).
- **Witness.** The prover computes intermediate **advice** values from the inputs;
  the private inputs plus advice together are the **witness**. In the Halo2 usage,
  everything the prover feeds the circuit, not just the secret inputs.

## The security contract

- **Non-interactive argument.** A prover creates a **proof**, which is data that convinces
  a **verifier** that *there exists* a witness for which the statement holds, with no
  interaction.
- **Soundness.** The property that proofs cannot falsely convince a verifier.
- **Knowledge soundness (NARK).** A Non-interactive Argument of Knowledge further
  convinces the verifier the prover actually *knew* a witness. Knowledge soundness
  **implies** soundness, and is formalized by an **extractor** that, observing how
  the proof was generated, can recover the witness. For a bridge this is the property
  that matters: we need each side to prove it *holds* a valid state/transition
  witness, not merely that one exists.
- **Zero knowledge.** The proof reveals nothing about the witness beyond that a
  witness exists and was known to the prover.
- **Succinctness and SNARKs.** A proof system is **succinct** if proofs are short,
  polylogarithmic in circuit size. A succinct NARK is a **SNARK**; a **zk-SNARK** is
  a zero-knowledge SNARK.

## Proof size vs. verification cost (why the bridge is asymmetric)

The source distinguishes proof size from verifier work: succinctness constrains **proof size**, and a
SNARK **need not** have verification time polylogarithmic in the circuit size. Proof
size and verification cost are separate budgets. This is exactly the axis the bridge
design exploits:

- **Midnight -> Cardano (Groth16).** Groth16 gives constant-size proofs and a fixed,
  cheap verifier (a few pairings), which fits an on-chain
  Plutus script with a hard execution budget.
- **Cardano -> Midnight (Plonk/Halo2).** The selected KZG-backed Halo2 stack uses
  an updatable universal trusted SRS. It avoids a new SRS ceremony for each
  circuit, but it is not transparent. Its heavier verifier fits the Midnight
  execution surface better than Cardano's on-chain Plutus budget.

In both directions the object being checked is a **circuit** encoding a **relation**,
with a **public-input / private-witness** split, verified **non-interactively** and
**succinctly** with **knowledge soundness**. That is the shared contract this page names.

> Scope note: this is a definitional concept page. It does not specify curves,
> setup ceremonies, recursion mechanics, or performance figures; those are covered by
> the scheme-specific pages in this KB.
