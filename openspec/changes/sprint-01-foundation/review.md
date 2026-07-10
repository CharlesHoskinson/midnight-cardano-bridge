## Evidence dossier

**Review state:** Initialized for Sprint 1. The proof-systems, consensus, and implementer/operator readers defined by `S01-T05-W03` have not yet performed their independent reads. This artifact does not claim council closure.

**Council gate:** not run

The initial specification review uses these local inputs:

- `docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md`
- `docs/superpowers/plans/2026-07-09-proof-bridge-foundation-and-living-design.md`, Tasks 3 through 6
- `openspec/changes/sprint-01-foundation/proposal.md`
- `openspec/changes/sprint-01-foundation/design.md`
- All twelve delta specs under `openspec/changes/sprint-01-foundation/specs/`

The Deep Research Toolkit compilation, verbatim-gated dossier, and contradiction adjudication remain pending under `S01-T05-W01` and `S01-T05-W02`. Until those tasks complete, this artifact treats the council-reviewed program design as planning context and does not use an absent dossier to close an external-source question.

## Blocking questions

### S01-BLOCK-01: Missing sibling predicate catalogs

- **Severity:** BLOCKING program gate; foundation specification coverage recorded.
- **Reader:** Implementer/operator focus; independent read pending.
- **Document location:** `design.md`, Decisions 4 and 9; `specs/predicate-registry/spec.md`, Authorized proof semantics.
- **Technical reason:** Registry semantics and 94-predicate coverage cannot be established from absent source records, and adding plausible entries would create unsupported proof semantics.
- **Required evidence:** A mechanical result showing exactly 42 unique Cardano records and 52 unique Midnight records, no duplicate ids, all required fields, and a provenance digest for every row.
- **Owner:** `S01-W03` catalog recovery or source-backed reconstruction and `S01-W04` normalization and validation.
- **Reproducer:** Inspect the recorded search locations and run the catalog validator produced by `S01-W04`; any missing record, wrong count, duplicate id, or absent provenance digest reproduces the block.
- **Resume condition:** The count, uniqueness, schema, and provenance gates all pass without a synthesized filler row.
- **Affected interface:** Predicate catalog, predicate registry, proof-template selection, traceability, and conformance coverage.
- **Disposition:** The foundation rejects registry population on an incomplete catalog and prohibits invented rows. This resolves the specification question but does not close the program gate.
- **Verification result:** Requirement and negative scenario are present; catalog recovery and its mechanical validator have not run.

### S01-BLOCK-02: Public Mithril SCLS trust profile

- **Severity:** BLOCKING public-testnet gate; foundation specification coverage recorded.
- **Reader:** Consensus focus; independent read pending.
- **Document location:** `design.md`, Decisions 6 and 9; `specs/cardano-anchor/spec.md`, Named Cardano trust profile.
- **Technical reason:** A project-operated signer population can test SCLS mechanics but cannot establish that the selected public Cardano testnet certified the exact SCLS signed-entity type.
- **Required evidence:** Primary or gated evidence identifying an accepted public Mithril signer population, the exact SCLS signed-entity type it certifies, its certificate-chain and AVK profile, and a public-network positive and negative verification result.
- **Owner:** `S02-W04` public SCLS certification determination and lab-profile separation.
- **Reproducer:** Attempt to obtain and verify the required SCLS certificate from the selected public signer population; absence of the entity type or reliance on project signers reproduces the gate.
- **Resume condition:** The public profile is confirmed with reproducible evidence, or the program continues only under the separately named lab profile and reports at most `degraded-lab`.
- **Affected interface:** Cardano anchor profile, Cardano-to-Midnight Halo2 statement, checkpoint manifest, and testnet outcome label.
- **Disposition:** The foundation names both profiles and forbids a lab proof from claiming public-testnet trust. This resolves the trust-label specification question but does not close the external dependency.
- **Verification result:** Requirement and negative scenario are present; public signer support has not been demonstrated.

### S01-BLOCK-03: Authenticated Midnight event-to-MMR path

- **Severity:** BLOCKING proof-path gate; foundation specification coverage recorded.
- **Reader:** Consensus and proof-systems focus; independent reads pending.
- **Document location:** `design.md`, Decisions 6 and 9; `specs/midnight-anchor/spec.md`, Authenticated Midnight event path.
- **Technical reason:** The public relay object does not itself authenticate an event or MMR leaf. Accepting it without fixed parent-block, header, leaf, and inclusion rules would break the finality-to-inclusion equality.
- **Required evidence:** A specified event-to-header-to-MMR relation, canonical encodings, parent-block rule, positive inclusion vector, and negative vectors for wrong event, header, leaf position, MMR root, and finalized block.
- **Owner:** `S02-W03` path resolution and prototype, followed by `S05-W02` implementation and vectors.
- **Reproducer:** Submit a fact or relay object without a valid event-to-header-to-MMR path and show deterministic rejection before predicate evaluation.
- **Resume condition:** The authenticated path has a rejecting prototype and traceable primary or verbatim-gated source evidence.
- **Affected interface:** Midnight source adapter, BEEFY/MMR anchor, Midnight predicate relation, recursive aggregation, and Groth16 landing.
- **Disposition:** The foundation makes the complete authenticated path mandatory and rejects event-only evidence. This resolves the acceptance-boundary question but does not close the path gate.
- **Verification result:** Requirement and negative scenario are present; the path prototype and vectors have not run.

### S01-BLOCK-04: Full Halo2/KZG decider wrapper

- **Severity:** BLOCKING proof-system gate; foundation specification coverage recorded.
- **Reader:** Proof-systems focus; independent read pending.
- **Document location:** `design.md`, Decisions 2 and 9; `specs/groth16-proof-path/spec.md`, Full-decider BSB22 landing.
- **Technical reason:** Preparing or accumulating a KZG check without enforcing the final decider does not prove the selected inner Halo2 relation. BSB22 commitment `D` also cannot replace equality between verifier-reconstructed `claim_digest` and the inner typed statement.
- **Required evidence:** A BSB22 commitment-Groth16 prototype over BLS12-381 that constrains the full Halo2/KZG decider, rejects a forged or invalid accumulator, binds explicit `claim_digest`, and reports constraint count, maximum SRS degree, proving memory and latency, and Cardano verification cost.
- **Owner:** `S02-W01` feasibility prototype and decision record.
- **Reproducer:** Hold the claim inputs well formed, forge or invalidate the KZG accumulator, and show that the final wrapped relation rejects it.
- **Resume condition:** The rejecting prototype and named resource measurements meet the recorded pass threshold; otherwise the selected path remains blocked without fallback.
- **Affected interface:** Inner Halo2 statement, KZG accumulator, BSB22 wrapper, Groth16 public inputs, Plutus verifier, artifact-binding graph, and setup inventories.
- **Disposition:** The foundation fixes the full-decider relation and forbids substitution by commitment `D`, vanilla Groth16, native ECDSA, or direct Halo2 under the same path. This resolves the relation-definition question but not feasibility.
- **Verification result:** Requirement and invalid-accumulator scenario are present; the measured prototype has not run.

### S01-BLOCK-05: Midnight external-proof execution surface

- **Severity:** BLOCKING program dependency outside the four named foundation hard gates.
- **Reader:** Implementer/operator and proof-systems focus; independent reads pending.
- **Document location:** `design.md`, Decisions 2 and 9; `specs/halo2-proof-path/spec.md`, Cardano proof on Midnight.
- **Technical reason:** Proof-library availability does not demonstrate that a deployed Midnight operation can accept an untrusted Cardano proof, resolve its registered VK/program, reconstruct the full statement, and update tracked and replay state atomically.
- **Required evidence:** A deployed-operation prototype that accepts a valid external Halo2/Plonk proof, rejects malformed or misbound proofs, resolves only registered artifacts, and proves all-or-nothing state updates.
- **Owner:** `S02-W02` execution-surface prototype.
- **Reproducer:** Submit a valid and then a mutated external Cardano proof to the selected Midnight operation while observing predecessor, destination, and replay state.
- **Resume condition:** The valid proof commits all expected state changes and each rejected proof commits none.
- **Affected interface:** Midnight verifier operation, program/VK resolution, Cardano tracked state, destination action, and replay state.
- **Disposition:** The foundation requires the demonstrated surface and forbids inference from library support. The dependency remains pending Sprint 2 evidence.
- **Verification result:** Requirement and atomic scenario are present; no deployed-operation prototype has run.

### S01-BLOCK-06: Cardano BEEFY verification boundary

- **Severity:** BLOCKING program dependency outside the four named foundation hard gates.
- **Reader:** Proof-systems and implementer/operator focus; independent reads pending.
- **Document location:** `design.md`, Decisions 2 and 9; `specs/groth16-proof-path/spec.md`, Full-decider BSB22 landing.
- **Technical reason:** No public Cardano BEEFY validator currently consumes `Midnight RelayChainProof`. The reference Groth16/Plutus path must supply the complete BEEFY/MMR verification boundary rather than infer native support.
- **Required evidence:** A reference Plutus verifier and complete wrapped relation that reconstruct canonical `claim_digest`, verify the registered BSB22 commitment-Groth16 proof for the exact BEEFY finality, MMR inclusion, predicate, and typed-output statement, and reject malformed, stale, mixed-root, unregistered, and cryptographically mutated claims.
- **Owner:** `S05-W04` complete Groth16 public relation and `S05-W05` Cardano continuing-state prototype, followed by `S07-W03` wrapper and `S07-W04` Plutus verifier implementation.
- **Reproducer:** Submit a golden wrapped Midnight claim and then mutate its BEEFY set, MMR root or path, `claim_digest`, registry artifact, and proof bytes at the reference Cardano validator boundary.
- **Resume condition:** The reference Cardano boundary accepts the golden claim, rejects every required mutation, and atomically preserves continuing and replay state on failure.
- **Affected interface:** Midnight recursive statement, BSB22 wrapper, Plutus public-input reconstruction and verification, Cardano continuing state, and settlement authorization.
- **Disposition:** The foundation fixes the reference Groth16/Plutus path as the required boundary and forbids assuming a public native validator. Implementation evidence remains pending the named work packages.
- **Verification result:** The fixed landing and canonical public-input requirements are present; no reference Cardano BEEFY verifier has run.

## Major questions

No independent-reader major question has been recorded yet. The council task must add any finding with its document location, technical reason, required evidence, disposition, and verification result. A major finding cannot remain unresolved when the change is archived.

## Minor questions

No independent-reader minor question has been recorded yet. Minor findings may remain only with an explicit disposition that preserves an implementable and testable design.

## Dispositions

The initial author review confirms that the foundation text records all four named hard gates, the separate Midnight execution-surface and Cardano BEEFY-verifier dependencies, the fixed proof paths, explicit trust-profile labels, source-protocol-fingerprint and deployment-domain binding, immutable proof-of-concept roots, atomic failure behavior, and the prohibition on invented catalog rows.

This is specification coverage, not feasibility closure. `S01-BLOCK-01` through `S01-BLOCK-06` retain their stated downstream evidence requirements. The later council review must distinguish a resolved question about what the system requires from a still-pending external dependency or prototype.

## Verification

- **Council gate:** not run
- **Blocking review questions:** not counted; independent council pending.
- **Unresolved major review questions:** not counted; independent council pending.
- **Strict change validation:** `npx openspec validate sprint-01-foundation --strict --no-interactive` passed after all artifacts were created.
- **Repository OpenSpec validation:** `npm run openspec:validate` passed with one item passed and zero failed.
- **Artifact status:** `npx openspec status --change sprint-01-foundation` reported 5/5 artifacts complete.
- **Task 2 self-review:** Passed exact capability, requirement, scenario, 25-section outline, four-gate, 23-step checklist, and six-blocker coverage checks.
- **Task 2 read-only artifact review:** PASS after correcting non-vacuous council checks, failure-preserving Task 6 verification, and the sixth dependency register entry. This review is not the Task 5 council.
- **Proof-systems reader:** Not run; output SHA-256: absent; scheduled by `S01-T05-W03`.
- **Consensus reader:** Not run; output SHA-256: absent; scheduled by `S01-T05-W03`.
- **Implementer/operator reader:** Not run; output SHA-256: absent; scheduled by `S01-T05-W03`.
- **Deep Research Toolkit dossier:** Not compiled; scheduled by `S01-T05-W01` and `S01-T05-W02`.
- **Whitespace check:** `git diff --check` and `git diff --cached --check` passed after removal of trailing blank lines.
