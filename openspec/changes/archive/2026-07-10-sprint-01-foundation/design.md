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

Cardano-to-Midnight uses the registered Midnight Halo2/Plonkish stack over BLS12-381. A Midnight operation reconstructs public inputs, verifies the complete Cardano finality, SCLS inclusion, and predicate statement, and atomically updates tracked Cardano state, application state, value state, and replay state. A non-value operation commits the explicit `ValueStateV1 = Absent(reason_code)` representation.

Midnight-to-Cardano uses BSB22 commitment-Groth16 over BLS12-381. Its wrapper proves the complete inner Halo2/KZG decision relation, including the final accumulator decider. The Cardano validator reconstructs canonical `claim_digest` as an explicit public input and the wrapper constrains it to the exact inner statement and typed result. BSB22 commitment `D` binds designated wires but cannot replace that equality.

Alternative proof systems remain production candidates only through a versioned decision record backed by target-network measurements. Allowing a fallback under the same proof-of-concept suite id was rejected because it would change the trust and verification contract without changing the claim label.

### 3. Compose finality, inclusion, and predicate relations by equality

Each direction has exactly three terminal semantic roles. Cardano-to-Midnight uses `[cardano_finality, scls_inclusion, cardano_predicate]`; Midnight-to-Cardano uses `[midnight_finality, event_inclusion, midnight_predicate]`. Internal recursion or fusion is permitted only when the registered architecture exposes exactly one ordered terminal statement per role. The aggregation profile binds count three, role tags, role-specific VKs and statement adapters, recursion bounds, padding behavior, and a content-addressed Poseidon/VK-hash profile. Omitted, duplicated, reordered, or cross-role statements fail even if each supplied proof verifies alone.

Each suite publishes an acyclic derivation from canonical proof-bound fields to `claim_digest`, relation I/O to role-tagged one-field statements, the ordered role/VK sequence to `claims_hash`, and root context, role outputs, canonical typed result, destination context, expiry, and replay to the outer instance. `claim_digest` is destination-derived. The common envelope has no generic public-input digest; any suite-native instance digest must have a registered acyclic preimage with an exact producer, consumers, wires, and constraints. The circuit binds network, deployment domain, height or slot, anchor digest, state version, source protocol fingerprint, predicate id, output schema, destination context, and replay value. A finality proof for one root cannot be paired with inclusion or predicate evidence for another root.

The recursive base case binds the complete bootstrap-manifest digest and deployment domain. Each step binds its exact predecessor and successor light-client states. Treating independently valid subproofs as composable without these equality constraints was rejected because it permits mixed-root and sibling-domain statements.

### 4. Make registry authorization part of proof semantics

The domain-neutral semantic registry template selects the predicate version, accepted anchor and finality templates, statement and result schemas, proof-suite and circuit-architecture templates, verifier-key and artifact template slots, SRS and setup templates, ABI template, replay policy, lifecycle policy, and proof-bound template selector. Its root feeds `DeploymentRootSetV1`. After domain derivation, `RegistryActivationV1` binds that template root, domain, destination identities, activated entry set, and lifecycle state. Destination state stores the activation digest. Callers cannot select an arbitrary verifier key or other authorization field. Cryptographic verification with an absent or inconsistent template, activation, or artifact authorization still fails authorization.

The catalog cannot populate the registry until mechanical validation reports exactly 42 unique Cardano records and 52 unique Midnight records with no duplicate ids and a provenance digest for each row. Generating filler rows or treating circuit-template reuse as a substitute for predicate records was rejected.

### 5. Bind checkpoints and immutable roots through an acyclic domain construction

Checkpoint mode is the proof-of-concept bootstrap and an explicit weak-subjectivity decision. The approved domain-neutral manifest binds source and destination identity templates, finalized point and anchor, current and next authority or certification commitments, proof and policy templates, and recovery template. The deployed verifier binds its digest and the separately derived `RootContextV1`, which contains the root-set digest and deployment domain. At least two independently administered full nodes reproduce derivable fields before the configured approver threshold signs the manifest; this detects error but does not remove checkpoint trust.

Checkpoint approvals cover a domain-separated digest of a canonical unsigned body under a preauthorized approval policy. Every body and manifest field is domain neutral. The body contains source and destination identity templates, bootstrap and consensus descriptors, semantic registry template root, artifact template root, ABI template digests, verifier or operation template hashes, deployment recipe digests, replay, freshness, recovery and approval templates, the fresh deployment instance id, derivation evidence, eligibility evidence, and cutoff time. It excludes its digest, approvals, approval-set digest, final manifest digest, root-set digest, deployment domain, activation and authorization records, concrete deployed destination instances, runtime state, and receipts. The final manifest digest derives from the approval-policy digest, body digest, and canonical approval-set digest. Cardano and Midnight eligibility use their own authenticated source relations before approval.

The pre-domain digest order is fixed: canonical source, catalog, schema, code, setup, and policy bytes produce source fingerprints, semantic registry leaves and root, artifact leaves and root, ABI templates, destination verifier or operation template hashes, and deployment recipe digests; those values produce the checkpoint body, approval set, and manifest digests; the approved manifests and template roots produce `DeploymentRootSetV1`; its canonical digest produces `root_set_digest`; and that digest produces `deployment_domain`. No fixed point or iterative derivation is permitted.

`DeploymentRootSetV1` contains only domain-neutral bridge program and fresh deployment instance ids, source identity/fingerprint pairs, destination network identity templates, checkpoint-manifest digests, anchor/finality/proof templates, semantic registry template root, artifact template root, ABI template digests, destination code or operation template hashes, deployment recipes, and replay, freshness, recovery, approval, and hash-policy templates. It excludes its own digest and domain and every value whose producer consumes either.

Only after the domain exists does the system derive `RegistryActivationV1` and `ArtifactAuthorizationV1` records and their root. A confirmed chain deployment produces `DeploymentObservationV1`; `DestinationAbiInstanceV1` accepts its concrete instance and code hash only from that observation; `RootContextV1` consumes the ABI instance; `ActivationDecisionV1` authorizes initialization; and `DeploymentReceiptV1` authenticates final continuing state. Destination state, registry membership, claim authorization, proof instances, construction and runtime payloads, replay keys, and receipts bind those outputs. None feeds a checkpoint, template root, or root set. Two independent golden derivations compare canonical bytes and every digest in topological order. A mechanical schema walk resolves all transitive references reachable from `DeploymentRootSetV1`, rejects post-domain fields and types, and topologically sorts the digest graph. Activation fails on a cycle, back edge, or unresolved producer. Vectors mutate every included root leaf, each excluded post-domain record, and the fresh instance id; they require a new domain for included mutations and resets, authorization failure for post-domain substitution, and old-domain rejection.

`RootContextV1` contains deployment and source context only. Registry resolution produces a per-claim `ResolvedProofContextV1` that binds predicate, suite, architecture, roles, artifact graph, result schema, replay policy, and exact freshness adapters, units, conversions, integer width, comparisons, era schedule, and numeric bounds. Continuing source state stores no suite, architecture, VK, SRS, setup, transcript, or curve selector. `BaseStateEqualityV1` maps every Cardano and Midnight recursive-base field outside `RootContextV1` to its exact approved checkpoint-body field; per-field mutation vectors hold root context fixed and reject, while two independent decoders reproduce positive states. A fixed-domain multi-architecture vector accepts two separately resolved architectures and rejects swapping their proof contexts. The post-domain DAG continues through chain-authenticated deployment observation, ABI instantiation, `ActivationDecisionV1` authorized by the pre-domain approval policy and exact roster evidence, destination initialization, and final `DeploymentReceiptV1`.

State-bearing replacement uses `DomainMigrationV1` with authenticated old/new contexts and activation decisions, final tracked/replay state, replay/application/value roots, complete old/new `continuity_replay_root`, count and completeness/translation proof, cutover, job disposition, monotonic sequence, approvals, proposal time, bounded delay/unit, earliest execution, and execution time. `SourceEventIdentityV1` excludes domain values and derives a continuity key consumed in every replay mode. The proof imports every old key exactly once; a new-domain proof of an old event rejects, while an unrelated event passes. One-unit-early execution rejects and equality passes.

The checkpoint digest, finality and anchor templates, proof-suite and artifact template roots, VK and SRS templates, semantic registry template root, destination code and ABI templates, replay rule, and recovery policy remain immutable within a proof-of-concept deployment domain. Their domain-bound activation, authorization, ABI instance, and root-context records are also fixed. Replacement or a testnet reset creates a new domain and old proofs fail. In-place root replacement was rejected because in-flight proofs and replay state cannot be made unambiguous without a separately specified transition state machine.

Genesis mode remains the production path. It starts from source genesis identity plus the initial authority or certification root and recursively verifies rotations. Cardano genesis does not derive the Mithril genesis verification key, which remains an independent trust root.

### 6. Name source trust profiles without upgrading them implicitly

Cardano anchors bind Cardano identity, Mithril certificate-chain and AVK assumptions, the exact certified signed-entity type, SCLS rules, and a Cardano source protocol fingerprint. Only an accepted public Mithril signer population certifying the required SCLS entity can support the public profile. Project-operated signing is a separate lab profile and can qualify for `degraded-lab` only when catalog completeness, real certificate-to-SCLS mechanics under `CONS-CARDANO-01`, every other lab-required gate, and both real confirmed destination transitions pass; otherwise the outcome is `blocked`. Public SCLS availability remains public-only for lab.

`CONS-CARDANO-01` binds a genesis-derived `CardanoIdentityDescriptorV1`, exact certificate-to-SCLS descriptor/message equality, and a complete `SclsTreeProfileV1`. The profile fixes namespace completeness and ordering, canonical key/value bytes, live/tombstone semantics, Blake2b-224 domains, child order, empty root, odd and power-of-two padding, depth/count bounds, direction bits, namespace leaves, and global construction. Membership authenticates both tree levels. Nonmembership authenticates empty, before-first, consecutive-neighbor, or after-last cases; absence of a membership proof is never enough. Independent message and tree codecs plus descriptor, identity, boundary, padding, namespace, tombstone, and certificate mutation vectors are required.

Midnight anchors bind a cryptographic genesis and chain-spec identity and complete current and next BEEFY descriptors with set id, root, count, equal-unit model, ECDSA/Keccak/leaf rules, and strict-more-than-two-thirds unique-member quorum. Bootstrap and each transition derive root, count, and unit weights from the complete ordered authority list. Authority rotation uses a source-derived mandatory-block state machine that authenticates the full successor descriptor, finalized block id and number, and MMR root under the outgoing set. A public relay object without the event-to-header-to-MMR path is insufficient.

Treating SCLS as Cardano consensus or treating an event payload as MMR membership was rejected because both would silently strengthen the source trust claim.

### 7. Use canonical claims and registry-first validation

Each suite publishes a field-binding matrix and a bounded, domain-separated canonical transcript. Common records use only `mcb.common-cbor.rfc8949-deterministic.v1`. `SuiteNativeProofProfileV1` solely owns proof, instance, VK, scalar/field, transcript, curve/point, subgroup, and equation grammar. The ABI references that digest, embeds native bytes unchanged, and owns only chain wrappers. Schema-walk vectors reject redefinition. `QueryV1` contains only schema version, requested predicate, bounded typed inputs, destination context, and optional constraints. Before preflight the harness binds the roster and resolves `ResolvedProofContextV1`. Validation then follows typed result, authorization/reconstruction, proof, proof-authenticated time, final context/freshness/replay/policy, and atomic four-owner transition order.

The common protocol has no undefined generic public-input digest. A suite-native instance digest requires a registered producer, acyclic canonical preimage, consumers, wire locations, and constraints; its preimage excludes `claim_digest`, BSB22 `pub`, and their derivatives. Golden vectors publish byte-exact query and resolution records for both directions under two independent codecs. Malformed-result vectors start from a valid resolution, expect rejection at typed-result canonicalization, prove that proof verification was not invoked, and require `NO_CHANGE` for all four state owners. An earlier failure does not satisfy those vectors.

This ordering rejects malformed framing, unauthorized semantics, and malformed results before proof verification and prevents replay consumption on failure. Freshness, replay, and policy run after proof-authenticated source time. Permitting implementation-specific encodings or verifier-selected validation order was rejected because independent implementations could accept different statements.

### 8. Support two atomic settlement transitions

`advance-and-consume` verifies the exact predecessor state, advances monotonically to a successor anchor, applies one destination action, and consumes replay atomically. `consume-current-anchor` keeps the current anchor. Every mode consumes its proof-bound domain-independent `continuity_key` with the message id, nullifier, or both. Claims racing on one predecessor refresh or rebase.

A single continuing-state transition was rejected because it would serialize independent claims that share an authenticated anchor. Each predicate selects `message-id`, `nullifier`, or `both`; `both` consumes both keys atomically. Rebase behavior follows the field-binding matrix: replay-only changes may rebuild, anchor changes require fresh authenticated data and reproving, and a domain, semantic registry template root, or registry activation change terminates the old job. Allowing partial writes was rejected because failed decode, proof, policy, construction, or submission handling must not change tracked state, application state, value, or replay state.

### 9. Preserve six named hard gates

The foundation records these gates without predicting their outcome:

1. Recover the missing sibling predicate catalogs or reconstruct source-backed equivalents, then prove the exact 42 Cardano and 52 Midnight counts, uniqueness, and per-row provenance without invented entries.
2. Confirm that an accepted public Mithril signer population certifies the exact required SCLS signed-entity type; otherwise keep the distinct lab profile and cap the outcome at `degraded-lab`.
3. Resolve and prototype the authenticated Midnight event-to-header-to-MMR path, including parent-block and inclusion rules; an event or relay object alone is not accepted.
4. Build and measure the full Halo2/KZG decider inside the BSB22 commitment-Groth16 wrapper and demonstrate rejection of a forged or invalid accumulator; failure blocks the selected path without fallback.
5. Demonstrate the deployed Midnight execution surface with an untrusted external Cardano proof, registry-selected VK, reconstructed inputs, all four atomic state owners, and confirmed receipt.
6. Demonstrate the complete Cardano BSB22/Plutus verification boundary, ABI mutations, all four atomic state owners, resources, and confirmed receipt; no public validator support is assumed.

### 10. Freeze on unsafe consensus evidence and label outcomes honestly

An unauthenticated unknown, downgraded, or mismatched source protocol fingerprint rejects without changing safety state. Source-evidence freeze requires two individually valid conflicting BEEFY commitments, two individually chain-valid conflicting Mithril certificates, or an authenticated unauthorized source upgrade. Governance signatures and elapsed delay are not source evidence. Delayed recovery starts only from a recorded frozen state through `RecoveryAuthorizationV1`; its receipt binds all four state owners, and root replacement uses `DomainMigrationV1`. Duplicate or racing recovery sequences fail without effect.

The sole authoritative roster is `protocol/gate-roster-v1.json`, whose roster member has deterministic-CBOR SHA-256 `2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f`. It contains exactly six `S01-BLOCK-*` and eight `CONS-*` entries. Existing `CONS-DOMAIN-01` owns the exact common-codec interface and evidence ids. `GateDeliverableV1` copies ordered owners, interfaces, applicability, evidence, and activation reference exactly; other parties are contributors or enforcement loci. `RunIntentV1` binds the roster before preflight.

`OutcomeClassifierV1` validates the exact roster before outcome evaluation. Invalid version or digest, missing, duplicate or unknown keys, changed owners or interfaces, unauthorized `not-applicable`, malformed status, missing or expired required evidence, or a retention failure selects `blocked`. It then uses first-match short-circuit rows: any required gate not `passed` selects `blocked`; either direction missing a real confirmed destination transition selects `blocked`; lab selects `degraded-lab`; otherwise public selects `live-pass`. Exactly one row is selected because evaluation stops at the first match, although later conditions may also be true. A mocked relation, verifier, transaction, transition, or receipt never passes a required gate. Vectors cover overlapping failures, mocked lab evidence, root-only lab substitution with two real transitions, public pass, bad rosters, and evidence expiry.

Chain receipts bind the claim, root set, registry activation, artifact authorization, ABI instance, and manifests to independently confirmed predecessor, successor, application, value, and replay state under versioned confirmation profiles. A lab trust root or unresolved gate can never be reported as `live-pass`.

Immutable `RunIntentV1` binds roster, roots, profiles, endpoint intent, and policy values without results. `PreflightReceiptV1` binds its digest and observations; `RunEvidenceManifestV1` binds ordered receipt/evidence digests afterward. Every receipt binds the intent, and the intent preimage excludes receipts. Operational probe and retention behavior otherwise follows their registered profiles.

`EvidenceSupersessionV1` and `GateResumeV1` govern gates. Separate `FailureProfileV1` enumerates every job retry target, and `JobResumeV1` binds the job, failure, allowed target, evidence, approvals, and compare-and-swap sequence. All id preimages are canonical CBOR tuples; boundary and resume-race vectors reject ambiguity and dual effects.

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
3. Run all six blocker feasibility packages before proof implementation. Record `FeasibilityDecisionV1 = demonstrated | conditional | not-demonstrated`; these engineering decisions are distinct from deployment outcome labels.
4. Implement later sprint changes against the registered proof paths, canonical statement, immutable root set, and atomic settlement interface.
5. Archive this change only after all downstream foundation tasks, proof/consensus/operator review, strict validation, and living-design checks pass.

There is no runtime rollback in this specification-only change. Before archive, a failed review leaves the delta active for correction. After deployment, rejected transitions make no state change; authenticated source conflict freezes the domain; delayed recovery is separately authorized; state-bearing replacement uses `DomainMigrationV1`; and destructive lab reset claims no replay, application, or value continuity.

## Open Questions

- Where are the missing sibling predicate catalogs, or which primary-source procedure will reconstruct each record with its provenance digest?
- Does an accepted public Mithril signer population expose the exact required SCLS signed-entity type, and what evidence identifies that profile?
- What exact Midnight parent-block, header, MMR-leaf, and event-inclusion rules close the authenticated event path?
- What constraint count, maximum SRS degree, proving RAM and latency, and Cardano verification cost result from the full Halo2/KZG decider wrapper, including the invalid-accumulator test?
- Which deployed Midnight operation and program/VK resolution interface demonstrates untrusted external Halo2 proof verification and all-or-nothing state update?
- Which reference Plutus interface and vectors demonstrate the BSB22-wrapped BEEFY/MMR verification boundary that no public Cardano validator currently supplies?
