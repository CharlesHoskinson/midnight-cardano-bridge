## Context

The council-reviewed [program design](../../../docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md) defines a bidirectional proof bridge in which untrusted data providers can transport foreign-chain facts but cannot authorize a destination transition. The repository needs two coordinated records of that system:

- The [canonical living design](../../../knowledge_base/bridges/midnight-cardano-recursive-bridge.md) is the readable, source-linked description of the current system.
- OpenSpec capability specs are the normative requirements and executable review boundary. Active sprint deltas become stable specs only after validation and acceptance.

The living design will use the approved 25-section outline:

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

The source predicate catalogs are not present in the current checkout. Catalog recovery or source-backed reconstruction must preserve provenance and pass count and uniqueness gates; a plausible row is not evidence and cannot be added to reach a target count.

## Goals / Non-Goals

**Goals:**

- Establish one normative baseline requirement for each of the twelve stable capability domains.
- Preserve the fixed Cardano-to-Midnight Halo2/Plonk and Midnight-to-Cardano full-decider BSB22 commitment-Groth16 proof paths.
- Make source-consensus, proof-soundness, setup-integrity, checkpoint, policy-root, and deployment-domain assumptions explicit and testable.
- Require every proof statement and recursive base or step relation to bind a source protocol fingerprint and deployment domain.
- Define negative behavior for unregistered artifacts, mixed anchors, stale or replayed claims, cross-domain proofs, incomplete authenticated paths, and failed atomic transitions.
- Carry the downstream 25-section design, documentation, evidence review, validation, and archive work as stable, verifiable tasks.

**Non-Goals:**

- Implement circuits, contracts, adapters, relayers, deployment scripts, or the 94-row predicate catalog in this change.
- Claim that the bridge is production-ready or that a checkpoint removes weak subjectivity.
- Treat a project-operated Mithril signer population as a public-testnet trust root.
- Substitute direct Halo2/KZG verification, native BEEFY-ECDSA verification, a future BLS verifier, or vanilla Groth16 for either proof-of-concept path.
- Infer an authenticated Midnight event path or Midnight proof-execution surface from library or relay-object availability.
- Permit in-place replacement of proof-of-concept trust, proof, or policy roots.

## Decisions

### 1. Keep the canonical narrative and normative specs separate

The living design describes the whole bridge as a current system, explains evidence and interfaces in the 25-section outline, and stays readable across capabilities. OpenSpec specs state narrow SHALL/MUST behavior with negative scenarios, support mechanical validation, and retain sprint-level review history through delta changes and archives. Requirement identifiers and the traceability matrix will connect the two records.

Combining both roles in one document was rejected because revision history, detailed predicate records, and test scenarios would obscure the system narrative, while explanatory prose alone cannot provide a mechanically checked acceptance contract. Neither record supersedes the other: an accepted change must leave the narrative, stable specs, traceability, and review evidence consistent.

### 2. Fix the two proof-of-concept proof paths

Cardano-to-Midnight uses the registered Midnight Halo2/Plonkish stack over BLS12-381. A Midnight operation reconstructs public inputs, verifies the complete Cardano finality, SCLS inclusion, and predicate statement, and atomically updates tracked Cardano state, destination action, and replay state.

Midnight-to-Cardano uses BSB22 commitment-Groth16 over BLS12-381. Its wrapper proves the complete inner Halo2/KZG decision relation, including the final accumulator decider. The Cardano validator reconstructs canonical `claim_digest` as an explicit public input and the wrapper constrains it to the exact inner statement and typed result. BSB22 commitment `D` binds designated wires but cannot replace that equality.

Alternative proof systems remain production candidates only through a versioned decision record backed by target-network measurements. Allowing a fallback under the same proof-of-concept suite id was rejected because it would change the trust and verification contract without changing the claim label.

### 3. Compose finality, inclusion, and predicate relations by equality

Each direction exposes a finality relation, an inclusion relation, and a predicate relation. The circuit binds their network, deployment domain, height or slot, anchor digest, state version, source protocol fingerprint, predicate id, output schema, destination context, and replay value. A finality proof for one root cannot be paired with inclusion or predicate evidence for another root.

The recursive base case binds the complete bootstrap-manifest digest and deployment domain. Each step binds its exact predecessor and successor light-client states. Treating independently valid subproofs as composable without these equality constraints was rejected because it permits mixed-root and sibling-domain statements.

### 4. Make registry authorization part of proof semantics

The active registry root selects the predicate version, accepted anchor and finality rule, statement and result schemas, proof suite, circuit architecture, full verifier-key graph, SRS and setup manifests, and proof-bound template selector. Callers cannot select an arbitrary verifier key. Cryptographic verification with an absent or inconsistent registry node still fails authorization.

The catalog cannot populate the registry until mechanical validation reports exactly 42 unique Cardano records and 52 unique Midnight records with no duplicate ids and a provenance digest for each row. Generating filler rows or treating circuit-template reuse as a substitute for predicate records was rejected.

### 5. Bind checkpoints and immutable roots to deployment domains

Checkpoint mode is the proof-of-concept bootstrap and an explicit weak-subjectivity decision. The deployed verifier binds the full approved manifest digest, including source and destination identities, finalized point and anchor, current and next authority or certification commitments, proof and policy artifacts, recovery policy, and deployment domain. At least two independently administered full nodes reproduce derivable fields before the configured approver threshold signs the manifest; this detects error but does not remove checkpoint trust.

The checkpoint digest, finality adapter, anchor profile, proof-suite graph, VK and SRS set, predicate registry, verifier hash, and recovery-policy hash remain immutable within a proof-of-concept deployment domain. Replacement or a testnet reset creates a new domain and old proofs fail. In-place root replacement was rejected because in-flight proofs and replay state cannot be made unambiguous without a separately specified transition state machine.

Genesis mode remains the production path. It starts from source genesis identity plus the initial authority or certification root and recursively verifies rotations. Cardano genesis does not derive the Mithril genesis verification key, which remains an independent trust root.

### 6. Name source trust profiles without upgrading them implicitly

Cardano anchors bind Cardano identity, Mithril certificate-chain and AVK assumptions, the exact certified signed-entity type, SCLS rules, and a Cardano source protocol fingerprint. Only an accepted public Mithril signer population certifying the required SCLS entity can support the public profile. Project-operated signing is a separate lab profile and limits the outcome to `degraded-lab`.

Midnight anchors bind the BEEFY current and next authority-set ids and roots, equal-weight proof-of-concept quorum, mandatory-block transition, finalized header and MMR formats, authenticated event inclusion, and a Midnight source protocol fingerprint. A public relay object without the event-to-header-to-MMR path is insufficient.

Treating SCLS as Cardano consensus or treating an event payload as MMR membership was rejected because both would silently strengthen the source trust claim.

### 7. Use canonical claims and registry-first validation

Each suite publishes a field-binding matrix and a bounded, domain-separated canonical transcript. The destination follows the fixed validation order: decode; canonical schema; destination context; expiry and freshness; replay state; registry resolution; verifier and anchor authorization; public-input reconstruction; proof verification; typed-output decoding; destination policy; replay consumption.

This ordering rejects cheap and policy-level failures before proof verification and prevents replay consumption on failure. Permitting implementation-specific encodings or verifier-selected validation order was rejected because independent implementations could accept different statements.

### 8. Support two atomic settlement transitions

`advance-and-consume` verifies the exact predecessor state, advances monotonically to a successor anchor, applies one destination action, and consumes its replay key atomically. `consume-current-anchor` keeps the current anchor and consumes a distinct message id or nullifier. Claims racing on one predecessor refresh or rebase; the proof of concept does not consume an older anchor after advancement.

A single continuing-state transition was rejected because it would serialize independent claims that share an authenticated anchor. Allowing partial writes was rejected because failed proof, policy, or submission handling must not consume replay state or authorize settlement.

### 9. Preserve four named hard gates

The foundation records these gates without predicting their outcome:

1. Recover the missing sibling predicate catalogs or reconstruct source-backed equivalents, then prove the exact 42 Cardano and 52 Midnight counts, uniqueness, and per-row provenance without invented entries.
2. Confirm that an accepted public Mithril signer population certifies the exact required SCLS signed-entity type; otherwise keep the distinct lab profile and cap the outcome at `degraded-lab`.
3. Resolve and prototype the authenticated Midnight event-to-header-to-MMR path, including parent-block and inclusion rules; an event or relay object alone is not accepted.
4. Build and measure the full Halo2/KZG decider inside the BSB22 commitment-Groth16 wrapper and demonstrate rejection of a forged or invalid accumulator; failure blocks the selected path without fallback.

The separate Midnight execution-surface prototype must also show that an untrusted Cardano proof can be verified by the deployed operation and can update state atomically before implementation relies on that surface.

No public Cardano BEEFY validator currently consumes `Midnight RelayChainProof`. The reference BSB22 commitment-Groth16 and Plutus path must therefore supply that verification boundary and demonstrate it directly; native validator support cannot be assumed.

### 10. Freeze on unsafe consensus evidence and label outcomes honestly

An unknown, downgraded, or mismatched source protocol fingerprint or conflicting finality evidence freezes the affected domain for governance review. The proof of concept does not roll an accepted anchor backward, mutate an active root, or consume replay state after a rejected or interrupted transition. Recovery follows the registered policy and, when it replaces a root, creates a new deployment domain.

Testnet evidence receives `live-pass`, `degraded-lab`, or `blocked` according to the capability spec. A lab trust root or unresolved gate can never be reported as `live-pass`.

## Risks / Trade-offs

- [Missing catalog evidence] -> Keep dependent registry work blocked until exact count, uniqueness, and provenance checks succeed; do not add inferred rows.
- [Public Mithril SCLS certification is unavailable] -> Use a separately identified lab profile for mechanical testing and report at most `degraded-lab`.
- [Midnight event inclusion cannot be authenticated to the finalized MMR root] -> Record a `blocked` outcome with the reproducer, owner, interface, and resume evidence; do not accept relay data directly.
- [The full decider exceeds proving or Cardano verification limits] -> Preserve measurements and the rejecting prototype, block the requested path, and evaluate alternatives only in a new versioned decision record.
- [The Midnight operation cannot accept and atomically apply an external proof] -> Stop dependent Cardano-to-Midnight implementation and retain a runnable surface reproducer.
- [No public Cardano validator supplies the BEEFY boundary] -> Require the reference Groth16/Plutus verifier to reconstruct and reject the complete Midnight statement before dependent settlement work proceeds.
- [Checkpoint or protocol evidence conflicts after deployment] -> Freeze the affected domain; do not roll back the anchor or bypass the recovery policy.
- [Narrative and normative records diverge] -> Require traceability, council review, strict OpenSpec validation, and current-document rereads before archive.
- [Concurrency causes stale predecessor submissions] -> Require refresh or rebase onto `consume-current-anchor`; preserve replay state on rejection.

## Migration Plan

1. Keep this change active while the twelve baseline deltas, 25-section narrative, traceability, and initial review evidence are reconciled.
2. Recover and validate the predicate catalogs before registry population. A failed gate leaves dependent tasks unchecked and records a blocker; it does not alter counts.
3. Run the four named feasibility gates and the Midnight execution-surface prototype before proof implementation. Record `go`, `degraded-lab`, or `blocked` without changing claim semantics.
4. Implement later sprint changes against the registered proof paths, canonical statement, immutable root set, and atomic settlement interface.
5. Archive this change only after all downstream foundation tasks, proof/consensus/operator review, strict validation, and living-design checks pass.

There is no runtime rollback in this specification-only change. Before archive, a failed review leaves the delta active for correction. After deployment, rejected transitions make no state change; unsafe consensus evidence freezes the domain; root replacement and testnet reset migrate to a new deployment domain whose verifier rejects prior-domain proofs.

## Open Questions

- Where are the missing sibling predicate catalogs, or which primary-source procedure will reconstruct each record with its provenance digest?
- Does an accepted public Mithril signer population expose the exact required SCLS signed-entity type, and what evidence identifies that profile?
- What exact Midnight parent-block, header, MMR-leaf, and event-inclusion rules close the authenticated event path?
- What constraint count, maximum SRS degree, proving RAM and latency, and Cardano verification cost result from the full Halo2/KZG decider wrapper, including the invalid-accumulator test?
- Which deployed Midnight operation and program/VK resolution interface demonstrates untrusted external Halo2 proof verification and all-or-nothing state update?
- Which reference Plutus interface and vectors demonstrate the BSB22-wrapped BEEFY/MMR verification boundary that no public Cardano validator currently supplies?
