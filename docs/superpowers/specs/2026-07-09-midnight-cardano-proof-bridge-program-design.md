# Midnight <-> Cardano proof bridge program design

**Date:** 2026-07-09

**Status:** Approved design for sprint planning

## Purpose

This program turns the current bridge research into a buildable specification and
a reference proof harness aimed at Cardano and Midnight testnets. The harness lets
an application on either chain ask a typed question about the other chain, obtain a
proof from an untrusted prover, and verify that proof before authorizing a local
transaction.

The two proof paths are fixed:

- Cardano facts are proved with Halo2/Plonk and verified by a Midnight contract.
- Midnight facts are recursively processed and wrapped in Groth16 for verification
  by a Cardano Plutus validator.

The program covers the full predicate catalog: 42 Cardano predicates and 52
Midnight predicates. Each predicate receives a precise statement, anchor,
input/output schema, freshness policy, replay policy, proof template, and
cross-chain use. The proof of concept does not require 94 unrelated circuits.
Predicates that share the same proof shape use a common circuit template selected
through the predicate registry.

## Scope

The program produces:

- A current, self-contained design for the complete proof bridge.
- Normative OpenSpec requirements for each bridge capability.
- A normalized matrix for all 94 predicates.
- A shared query, claim, and proof-response protocol.
- Checkpoint bootstrap manifests for both testnets.
- A genesis-verifiable production path for both directions.
- A Cardano-side reference verifier and harness for Groth16 claims.
- A Midnight-side reference verifier and harness for Halo2/Plonk claims.
- Conformance vectors, negative tests, failure codes, and benchmark procedures.
- Deployment and operating instructions for a two-testnet proof of concept.

The program does not claim production readiness. Production requires independent
audits, a reviewed Groth16 ceremony, stable upstream finality formats, an accepted
Cardano state-certification path, and deployment governance.

## Definition of success

The design is buildable when all of the following are true:

1. Every predicate in the 42/52 catalogs has a registry record and traceable
   requirements.
2. Every proof binds a typed claim to a named source network, finality rule,
   authenticated state anchor, destination context, expiry, and replay scope.
3. The Cardano verifier accepts a valid Groth16-wrapped Midnight claim and rejects
   malformed, stale, replayed, misbound, or unregistered claims.
4. The Midnight verifier accepts a valid Halo2/Plonk Cardano claim and rejects the
   same classes of invalid input.
5. Both testnet deployments start from reproducible checkpoint manifests and can
   advance their tracked consensus state without a trusted relayer.
6. At least one end-to-end claim from every proof-template family is exercised.
7. At least one transaction in each direction uses a foreign-chain claim to
   authorize a state change on the destination chain.
8. Costs, proof sizes, proving latency, verification latency, and failure behavior
   are recorded from the deployed harness.

## System boundary

The system has six logical components:

1. A source adapter reads chain data and constructs an authenticated witness.
2. A query interface selects a predicate, source anchor, destination context, and
   result schema.
3. A proof generator executes the correct Halo2 or Groth16 path.
4. An untrusted relayer transports the claim envelope, proof, and public witness.
5. A destination verifier reconstructs the public inputs and checks the proof.
6. A destination application consumes the typed result after freshness, registry,
   context, and replay checks pass.

Relayers, indexers, aggregators, and proof services are data providers. None is a
root of trust. A dishonest provider can delay delivery or submit invalid data, but
cannot make the destination accept a false claim.

## Roots of trust

Each destination has three irreducible trust roots:

| Destination | Foreign consensus root | Proof root | Policy root |
| --- | --- | --- | --- |
| Cardano | Midnight checkpoint and BEEFY authority-set commitment | Groth16 verifier key and ceremony transcript hash | Predicate-registry root and governance policy |
| Midnight | Cardano identity and Mithril genesis key or certified checkpoint | Halo2/Plonk verifier key and accepted Midnight SRS/version | Predicate-registry root and governance policy |

### Cardano-side bootstrap

The Cardano validator tracks this Midnight state:

- source network and genesis identity
- latest finalized block number
- latest accepted MMR root
- current BEEFY validator-set id
- current BEEFY authority root
- active predicate-registry root
- consumed-message or nullifier root

The verifier rules fix the BEEFY commitment encoding, signature domain, quorum
calculation, authority membership proof, mandatory-block handoff, MMR leaf format,
and event inclusion path. The current public networks use equal-weight BEEFY sets.
The published initial sizes are 6 on govnet, 7 on devnet, and 10 on mainnet.

### Midnight-side bootstrap

The Midnight contract tracks this Cardano state:

- Cardano network magic and genesis identity
- latest accepted Mithril certificate hash
- latest certified epoch and SCLS slot
- latest SCLS root
- current Mithril aggregate verification key
- active predicate-registry root
- consumed-message or nullifier root

The verifier rules fix the Mithril certificate-chain algorithm, accepted security
parameter floor, signed-message format, SCLS version, namespace definitions, leaf
hashing, canonical encoding, and result freshness.

### Checkpoint and genesis modes

The proof of concept uses checkpoint bootstrap. A canonical manifest pins one
finalized source checkpoint and the validator state active at that point.
Independent nodes must reproduce every manifest field before deployment.

The production specification also defines genesis bootstrap. In that mode, the
first trusted consensus state is the source genesis identity plus its initial
authority or certification root. Recursive proofs carry every accepted set
transition forward from that state.

Routine governance cannot skip to an arbitrary checkpoint. Emergency checkpoint
replacement requires a separate, delayed recovery policy and produces a new
deployment domain so old proofs cannot cross the boundary.

## Shared claim protocol

A destination verifier receives four objects:

1. A typed query and claim envelope.
2. A proof blob.
3. Public witness data required outside the circuit.
4. A registry proof or registry entry selected by predicate id.

The claim envelope binds:

- schema version
- source system and network
- source era or runtime version
- predicate id and predicate version
- anchor type and anchor digest
- finality rule and parameters
- source time scope
- verifier or program id
- public input and output hashes
- destination context hash
- expiry
- replay scope
- nullifier or message id when consumption is stateful

The validation order is fixed:

    decode
    -> check schema and canonical encoding
    -> check destination context
    -> check expiry and freshness
    -> check replay state
    -> resolve predicate in the registry
    -> check verifier and accepted anchor
    -> reconstruct public inputs
    -> verify proof
    -> decode typed output
    -> apply destination policy
    -> consume nullifier or message id

No caller may choose an arbitrary verifier key. The registry is authoritative.

## Predicate catalog

The catalog is a normative matrix, not a prose appendix. Every row contains:

- predicate id and version
- source chain and source namespace
- natural-language statement
- formal public inputs and outputs
- private witness
- accepted anchor types
- finality and freshness rule
- proof-template family
- verifier key or program binding
- destination context requirements
- replay behavior
- positive and negative vectors
- example use in a trustless transaction
- primary sources and implementation status

The initial source files for the 42 Cardano and 52 Midnight sibling catalogs are
not present in the current checkout. Sprint 1 must recover them or reconstruct a
source-backed equivalent before later sprints can claim complete predicate
coverage. Reconstruction must preserve provenance and may not invent an entry to
reach a target count.

## Living design document

The existing file
knowledge_base/bridges/midnight-cardano-recursive-bridge.md remains the canonical
human-readable design. It describes the system as it currently stands. It does not
narrate edits or refer to earlier drafts. Git history and OpenSpec review artifacts
record how the design changed.

The document has these sections:

1. Document control
2. Purpose and scope
3. System model
4. Terminology and invariants
5. Security and trust model
6. Bootstrap and roots of trust
7. Shared claim protocol
8. Predicate registry
9. Cardano predicate catalog
10. Midnight predicate catalog
11. Cardano state anchoring
12. Cardano to Midnight proof path
13. Midnight state anchoring
14. Midnight to Cardano proof path
15. Proof systems and setup
16. Reference harness
17. Trustless transaction protocol
18. Destination validators
19. Relaying and data availability
20. Governance and upgrades
21. Economics and performance
22. Conformance and security testing
23. Testnet deployment
24. Production path and residual risks
25. Appendices

Each section links normative statements to OpenSpec requirement ids. Detailed
predicate records live in the matrix and stable capability specs so the narrative
remains readable.

## OpenSpec organization

OpenSpec is the normative planning and requirements layer. The repository uses a
custom workflow based on the standard spec-driven artifact chain:

    proposal -> delta specs -> design -> tasks -> review

The review artifact contains council questions, dispositions, and verification
evidence. Stable specs describe accepted behavior. Sprint changes describe
proposed deltas and move into the archive after their acceptance gates pass.

The stable capability domains are:

    bridge-system
    bootstrap-trust
    claim-protocol
    predicate-registry
    cardano-anchor
    midnight-anchor
    halo2-proof-path
    groth16-proof-path
    reference-harness
    settlement-protocol
    operations-governance
    conformance-testnet

Each sprint owns one OpenSpec change directory:

    openspec/changes/sprint-01-foundation/
    openspec/changes/sprint-02-claim-protocol/
    openspec/changes/sprint-03-cardano-anchor/
    openspec/changes/sprint-04-midnight-anchor/
    openspec/changes/sprint-05-proof-architecture/
    openspec/changes/sprint-06-reference-harness/
    openspec/changes/sprint-07-settlement-security/
    openspec/changes/sprint-08-testnet-poc/
    openspec/changes/sprint-09-conformance-closure/

OpenSpec configuration supplies repository context and enforces these rules:

- Requirements use MUST, SHALL, or MAY with testable scenarios.
- Every security-sensitive requirement names its trust assumption.
- Every chain fact cites a primary source or a gated local source pack.
- Every binary format specifies canonical encoding and bounds.
- Every accepted proof has negative scenarios.
- Every change updates the living design and traceability matrix.

## Sprint model

A sprint is a bounded set of agent-executable work packages with one review and
verification gate. It is not an estimate in human hours. The program has nine
sprints and 48 work packages.

### Sprint 1: Foundation and catalog recovery

Five work packages:

1. Initialize OpenSpec with the custom council-review workflow.
2. Establish stable spec domains, requirement ids, and traceability records.
3. Recover or reconstruct the Cardano 42 and Midnight 52 predicate catalogs.
4. Normalize all predicate records and classify their proof-template families.
5. Specify checkpoint and genesis bootstrap manifest schemas.

Exit gate: all 94 catalog positions are accounted for by sourced records or
explicit, evidence-backed gaps. The living document and OpenSpec validation pass.

### Sprint 2: Claim protocol and registry

Five work packages:

1. Specify the canonical query, claim envelope, proof response, and result records.
2. Specify canonical CBOR and deterministic Midnight encodings.
3. Specify predicate-registry entries, membership proofs, and lifecycle states.
4. Specify validation order, failure codes, expiry, context, and replay behavior.
5. Produce cross-language conformance vectors and negative vectors.

Exit gate: both destination harness interfaces can consume the same logical claim
without guessing its meaning.

### Sprint 3: Cardano anchor and Halo2 path

Five work packages:

1. Specify the Cardano bootstrap state and network identity.
2. Specify Mithril certificate-chain and stake-distribution verification.
3. Specify SCLS membership, nonmembership, and freshness proofs.
4. Specify recursive Halo2 state and public inputs.
5. Specify the Midnight verifier contract and its state transitions.

Exit gate: a complete Cardano fact can be traced from source data through a
certified SCLS root into a Midnight-verifiable Halo2 statement.

### Sprint 4: Midnight anchor and Groth16 path

Five work packages:

1. Specify the Midnight bootstrap state and network identity.
2. Specify BEEFY quorum, authority membership, and mandatory-block rotation.
3. Specify the missing ledger-event to BEEFY-MMR inclusion path.
4. Specify recursive preprocessing and the Groth16 public statement.
5. Specify the Cardano validator datum, redeemer, and state transitions.

Exit gate: a complete Midnight fact can be traced from ledger state through a
finalized MMR anchor into a Cardano-verifiable Groth16 statement.

### Sprint 5: Proof architecture and setup

Five work packages:

1. Define reusable Halo2 proof-template interfaces for the predicate families.
2. Define the Halo2-to-Groth16 wrapping circuit and public-input commitment.
3. Define recursive aggregation and verifier-key binding.
4. Define SRS, ceremony, transcript, verifier-key equality, and upgrade policy.
5. Define benchmark fixtures and proof-system acceptance thresholds.

Exit gate: proof statements, setup assumptions, and verifier bindings are precise
enough for independent implementation.

### Sprint 6: Reference harness

Six work packages:

1. Define the shared query/prove/verify command and API surface.
2. Define the Cardano source and witness adapter.
3. Define the Midnight source and witness adapter.
4. Define the Halo2 prover and Midnight verifier harness.
5. Define the recursive wrapper, Groth16 prover, and Cardano verifier harness.
6. Define registry-driven predicate dispatch and fixture loading.

Exit gate: an implementer can run the same logical query flow in both directions
using deterministic fixtures.

### Sprint 7: Settlement, security, and operations

Six work packages:

1. Specify deterministic cross-chain message identity.
2. Specify both destination state machines and transaction authorization.
3. Specify nullifiers, consumed-message records, lanes, ordering, and retries.
4. Specify asset identity, NIGHT/cNIGHT treatment, and two-way conservation.
5. Specify relayer permissionlessness, data availability, fees, and liveness.
6. Complete the threat model, governance model, and recovery policy.

Exit gate: a valid foreign claim can authorize a local state change without hidden
trust in a relayer or indexer.

### Sprint 8: Testnet proof of concept

Six work packages:

1. Produce reproducible Cardano and Midnight checkpoint manifests.
2. Define and execute destination verifier deployments.
3. Define and execute harness and relayer deployments.
4. Run a Cardano to Midnight claim-authorized transaction.
5. Run a Midnight to Cardano claim-authorized transaction.
6. Capture costs, latency, proof sizes, logs, addresses, and operating steps.

Exit gate: both directions run against the selected testnets, or the exact upstream
blocker is reproduced and isolated behind a testable interface.

### Sprint 9: Conformance and closure

Five work packages:

1. Complete 94-predicate traceability and proof-template coverage.
2. Complete conformance, malformed-input, replay, and failure-code suites.
3. Run the final council and security review.
4. Reconcile every remaining examination-checklist entry.
5. Archive accepted OpenSpec changes and publish the production-gap register.

Exit gate: the repository contains one coherent buildable specification, verified
OpenSpec requirements, reproducible PoC evidence, and an explicit production path.

## Traceability

Every normative claim has a stable requirement id. The traceability record maps:

    requirement id
    -> design section
    -> predicate ids
    -> primary sources
    -> OpenSpec change
    -> implementation artifact
    -> conformance vectors
    -> deployment evidence
    -> checklist item

A requirement cannot close because prose exists. It closes only when its stated
evidence and verification command succeed.

## Review council

Three reader agents review each sprint independently:

1. The proof-systems reader checks circuit statements, public inputs, recursion,
   setup, verifier-key binding, and soundness.
2. The consensus reader checks finality, checkpoints, authority or stake rotation,
   state anchoring, and weak-subjectivity assumptions.
3. The implementer/operator reader tries to build and deploy from the document. It
   looks for missing interfaces, formats, tests, failure behavior, and runbook steps.

Reader agents do not edit the document. They return questions with a severity,
location, rationale, and the evidence needed to resolve the issue. The author
records the questions and dispositions in the sprint review artifact, then rewrites
the current design and specs directly.

The canonical design never says that a section was added, corrected, or changed in
an earlier iteration. It describes the bridge as a current system. Git and committed
review artifacts preserve the audit trail.

The council gate is:

    technical draft
    -> humanizer pass
    -> independent council review
    -> question resolution
    -> clean rewrite
    -> humanizer preservation check
    -> fresh council reread
    -> OpenSpec and repository verification

A sprint cannot close with an unanswered blocking question or a major ambiguity
that prevents implementation or testing.

## Writing standard

The Humanizer skill applies to explanatory prose before each council review and
after question resolution. It removes inflated language, filler, vague attribution,
formulaic transitions, repetitive cadence, and diff-anchored narration.

The writing pass may not alter:

- MUST, SHALL, and MAY requirements
- code identifiers or binary layouts
- formulas, thresholds, hashes, or byte lengths
- source quotations
- requirement ids
- security assumptions
- test acceptance criteria

Technical writing remains neutral and direct. Uncertainty is stated at the point
where it matters. Missing evidence is named rather than filled with a plausible
guess.

## Dependencies and hard blockers

The program has four known external dependencies:

1. The three sibling predicate-catalog files are missing from the recorded local
   path. Full catalog recovery or source-backed reconstruction is a Sprint 1 gate.
2. No public Cardano BEEFY validator currently consumes Midnight RelayChainProof.
   The reference Groth16 path must specify and supply that verification boundary.
3. The public relay object does not include the event or MMR-leaf inclusion proof.
   Sprint 4 must define the missing authenticated path.
4. Mithril does not yet provide a confirmed public SCLS certification module for
   this use. A project-operated signer setup can test mechanics, but the design must
   label its trust model and cannot call it Cardano-testnet trustless.

Future Midnight finality changes are isolated behind the finality-certificate
interface. They do not change the claim protocol or predicate catalog.

## Verification

Every sprint runs:

- OpenSpec validation for the active change and affected stable specs
- claim/source quote gates for new research packs
- canonical encoding and conformance-vector tests
- document link and requirement-id checks
- git diff whitespace checks
- the sprint-specific proof, harness, or deployment verification
- a clean working-tree check after the sprint commit

Completion claims cite fresh command output and deployment evidence.
