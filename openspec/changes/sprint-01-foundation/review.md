## Evidence dossier

**Review state:** accepted

**Council gate:** closed

The Deep Research Toolkit run on 2026-07-10 compiled 43 pages, 25 claims, 37 entities, and 35 relations, with 43 wiki chunks and 25 claim vectors. It used the deterministic fake embedder for reproducible local review. The dossier query was `roots of trust, proof composition, predicate registry, and testnet deployment for the Cardano Midnight bridge` with `--k 40`.

All 25 dossier claims were included with verbatim evidence references and 0 were rejected. The admitted evidence covers the `RelayChainProof` fields and Cardano serialization boundary, BEEFY authority leaf and current equal-unit runtime evidence, relay subscriptions and unused MMR helper, governance-controlled Cardano-to-Midnight approval, Mithril BLS types, Midnight multi-circuit aggregation and VK authorization, supported Midnight SRS sources, Cardano secp256k1 builtins, and published permissioned authority counts. The dossier does not supply missing predicate rows, deployment roots, proof equations, public trust profiles, or deployment results.

The contradiction query returned three multi-valued non-contradictions:

1. `midnight-srs supports_source {midnight,filecoin}` records two supported sources.
2. `token-type has_variant {shielded,dust,unshielded}` records three variants.
3. `relay-chain-proof contains {signed-commitment,authorities-proof}` records two fields of one structure.

Reader evidence:

- **Proof-systems reader:** Complete; output SHA-256: c6660aff004edd9a351df863a53647babb3e09935921f04977a64126b75e19f4
- **Consensus reader:** Complete; output SHA-256: 2b3fed970eb9961699411ed8d8bd5b16e7e4a8fbfd8c8a21efd70fd57a7a8bf4
- **Implementer/operator reader:** Complete; output SHA-256: 23c7280a663cb1923c9e4478faa22cedadb80d16e5f76ba71999465d9be37a35

Final current-document reread evidence:

- **Proof-systems closure reader:** Complete; output SHA-256: 7d04e27cb06ad479c13123cd1d05cebf404c2343fbe2e4a80e83a724686e6e5b
- **Consensus closure reader:** Complete; output SHA-256: f69d574b18739529359b758bc66546a5a993161d754390dcb6cf1fa9473f30c8
- **Implementer/operator closure reader:** Complete; output SHA-256: 18a8aeef72b75fc412509c3471166f9d89a4cdaf80200ba546e06b883ab0721f

## Initial council questions

The three readers raised 30 questions: 10 blocking, 18 major, and 2 minor. The dispositions below describe the remediation draft. They are not council closure findings.

### Proof-systems reader

| ID | Severity | Initial question and location | Disposition in the remediation draft |
| --- | --- | --- | --- |
| PS-B1 | Blocking | Canonical sections 4, 7, 12, and 14 and `claim-protocol`: no exact acyclic statement/equality graph; `public_input_hash` had no producer and could be circular. | Sections 4 and 7 and `claim-protocol` define the derivation DAG, concrete equality ownership contract, derived `claim_digest`, canonical typed-result binding, and prohibition on undefined or circular public-input digests. Suite activation requires independent byte and field vectors. |
| PS-B2 | Blocking | Canonical sections 4, 8, 12, and 14: aggregation did not prove required role completeness or freeze its Poseidon profile. | Sections 4, 8, 12, and 14 plus `bridge-system`, `predicate-registry`, both proof-path specs, and conformance freeze exactly three terminal roles per direction, per-role VK/adapter policy, count binding, padding and depth rules, and a content-addressed Poseidon/VK-hash artifact with omission, duplication, reorder, and substitution vectors. |
| PS-B3 | Blocking | Canonical sections 14 and 15 and `groth16-proof-path`: the complete Halo2/KZG decider lacked exact parser, transcript, accumulator, equation, and verifier-parameter ownership. | Sections 14 and 15 and `groth16-proof-path` require a source-pinned native/circuit equivalence profile covering every stage and equation, constant or authenticated-input classification, full transcript consumption, exact SRS subset, and final accept-bit constraint. `S01-BLOCK-04` remains open until that content-addressed profile passes. |
| PS-B4 | Blocking | Canonical sections 14, 15, and Appendix A: BSB22 lacked committed wires and a complete 672-byte VK grammar; `pub` admitted aliases. | Sections 15 and 25 and `groth16-proof-path` freeze the evidenced 336-byte proof and 672-byte VK layouts, destination-derived canonical LE32 `pub` with rejection at `>= r`, existing equations, source-pinned curve parser profile, and a committed-wire manifest tied to wrapper R1CS and phase 2. |
| PS-M1 | Major | Canonical sections 4 and 6: bootstrap and domain propagation lacked a mechanical non-circular rule. | Sections 4 and 6 define canonical protocol descriptors, root-set/domain derivation with excluded self-fields, `RootContext`, base/step/final equality, and sibling checkpoint/domain vectors. `CONS-DOMAIN-01` remains an activation artifact. |
| PS-M2 | Major | Canonical sections 14 and 22 and `groth16-proof-path`: the invalid-accumulator gate was not falsifiable. | Sections 14 and 22 and `groth16-proof-path` require an instrumented canonical witness that passes all named earlier preconditions but fails only the final KZG decision, produces no outer proof, and is distinct from malformed outer-proof rejection. |
| PS-M3 | Major | Canonical sections 12 and 18 and `halo2-proof-path`: the Midnight external-proof gate lacked a bridge operation ABI. | Sections 12 and 18 and `halo2-proof-path` require a source-pinned operation profile with proof/instance ABI, role adapters, VK resolution, root context, exact predecessor/successor schemas, result/action/replay ownership, stage errors, resource bounds, and valid/mutated runtime receipts. `S01-BLOCK-05` remains open. |
| PS-M4 | Major | Canonical sections 7 and 18 and `claim-protocol`: typed output was decoded after proof verification. | Sections 4, 7, and 18 plus `claim-protocol` and `settlement-protocol` move registered typed-result decode and canonical re-encoding before public-input reconstruction and reuse the same object for proof, policy, and action with four-owner `NO_CHANGE` on failure. |
| PS-M5 | Major | Canonical sections 8 and 15 and `predicate-registry`: artifact authorization lacked owner and enforcement-locus coverage. | Sections 8 and 15 and `predicate-registry` add the artifact owner/enforcement matrix, constant or authenticated-input rule, content-addressed resolver, deployment VK byte equality, negative tests, and the uniform `GateDeliverableV1` activation envelope. |

### Consensus reader

| ID | Severity | Initial question and location | Disposition in the remediation draft |
| --- | --- | --- | --- |
| CS-B1 | Blocking | Canonical sections 6, 11, and 12: Mithril genesis and checkpoint termination were ambiguous. | Sections 6, 11, and 12 and `bootstrap-trust` define separate rule profiles and instances. Genesis verifies the full chain to the independent genesis VK; checkpoint mode verifies post-checkpoint linkage and cannot claim omitted history. Cross-profile chains fail. |
| CS-B2 | Blocking | Canonical sections 11 and 12 and `cardano-anchor`: certificate signed-message equality to the SCLS entity was absent. | Sections 11 and 12 and `cardano-anchor` define `CertifiedSclsDescriptorV1`, a source-native projection adapter, equality to the certificate protocol message, shared SCLS inclusion inputs, and fixed-field mutation vectors. `CONS-CARDANO-01` and public `S01-BLOCK-02` remain visible. |
| CS-B3 | Blocking | Canonical sections 6 and 13 and `midnight-anchor`: BEEFY successor state lacked complete descriptors, exact unique-member quorum, equal-unit derivation, and mandatory handoff. | Sections 6 and 13 and `midnight-anchor` bind complete current/next descriptors, `floor(2N/3)+1` distinct valid members, total-leaf equality, complete-list unit derivation, signed commitment/finalized state equalities, and the pending mandatory-block handoff state machine. Source-native rules remain `CONS-BEEFY-01` outputs. |
| CS-B4 | Blocking | Canonical section 6 and `bootstrap-trust`: checkpoint body, approval coverage, duplicate keys, threshold, and source eligibility were ambiguous. | Section 6 and `bootstrap-trust` define a canonical unsigned body, separate policy and approval messages, sorted approval set, final nonrecursive manifest digest, duplicate rejection, preauthorized threshold, two-node reproduction, and Cardano/Midnight eligibility before signing. |
| CS-M1 | Major | Canonical sections 5, 6, 13, and 23 and `midnight-anchor`: Midnight identity and initial BEEFY root were not cryptographic. | Sections 6, 13, and 23 and `midnight-anchor` define the genesis, exact chain-spec artifact, native identifiers, release, initial descriptor, and derived-versus-independent root modes while retaining AURA, GRANDPA, and ECDSA BEEFY roles. `CONS-MIDNIGHT-ID-01` remains source-dependent. |
| CS-M2 | Major | Canonical sections 4, 6, and 20 and `operations-governance`: fingerprints and domains were not reproducible roots. | Sections 4, 6, and 20 and `operations-governance` define canonical protocol descriptors, bridge digest domains, a non-circular deployment root set with fresh instance id, proof/replay propagation, mutation vectors, and new-domain reset behavior. |
| CS-M3 | Major | Canonical sections 4, 6, 7, and 18 and `bootstrap-trust`: freshness and source lag lacked trusted clocks and formulas. | Sections 4, 6, 7, and 18 and `bootstrap-trust` define authenticated source time, consensus-backed destination intervals, checked inclusive formulas, source/destination conversion ownership, overflow and era behavior, and endpoint lag as telemetry. Numeric profiles remain `CONS-FRESH-01` outputs. |
| CS-M4 | Major | Canonical sections 5 and 20 and `operations-governance`: unauthenticated fingerprint mismatch could freeze a domain. | Sections 5 and 20 and `operations-governance` make mismatch a no-state-change rejection and restrict freeze to registered valid BEEFY/Mithril conflict or an authenticated unauthorized upgrade. Recovery approval starts only from a matching recorded frozen state. Exact conflict profiles remain `CONS-FREEZE-01` artifacts. |

### Implementer/operator reader

| ID | Severity | Initial question and location | Disposition in the remediation draft |
| --- | --- | --- | --- |
| OP-B1 | Blocking | Canonical sections 11, 23, and 24 and `conformance-testnet`: outcome labels overlapped and allowed a mock transition under `degraded-lab`. | Section 23 and `conformance-testnet` predeclare public/lab profile and gate applicability, use an ordered mutually exclusive table, require both real confirmed destination transitions, allow only named source-root substitution for lab, and classify any mock relation, verifier, transaction, transition, or receipt as `blocked`. |
| OP-B2 | Blocking | Canonical sections 16, 19, and 23 and conformance/reference specs: transaction ids and generic confirmation did not prove chain-specific final state. | Sections 16, 19, and 23 plus `reference-harness` and `conformance-testnet` define chain builders, submission-unknown recovery, common and per-chain receipt fields, independent state reads, confirmation-profile ownership, and timeout/restart/duplicate/rollback or reset drills. Exact chain rules remain content-addressed gate outputs. |
| OP-M1 | Major | Canonical sections 3, 7, 8, and 16 and `reference-harness`: query selection conflicted with registry authorization. | Sections 3, 7, 8, and 16 and `reference-harness` make authorization fields optional query constraints only and make the destination-bound registry resolver the sole owner of anchor, suite, verifier, artifact graph, operation, replay mode, and lifecycle. |
| OP-M2 | Major | Canonical sections 7 and 16 and claim/reference specs: CDDL alone did not own canonical bytes. | Sections 7 and 16 plus `claim-protocol` and `reference-harness` separate bounded CDDL shapes from the deterministic binary owner, require RFC 8949 deterministic encoding, bounded versions, rejection rules, two codecs, and byte/digest/field vectors. |
| OP-M3 | Major | Canonical section 16 and `reference-harness`: captured public and synthetic lab fixtures were conflated. | Section 16 and `reference-harness` define separate fixture records and equality rules. Synthetic roots and domains must differ and cannot claim public byte equivalence; they support `degraded-lab` only with real destination transitions. |
| OP-M4 | Major | Canonical sections 6, 15, 20, and 23 and `operations-governance`: immutable trust and mutable operations shared one manifest scope. | Sections 6 and 23 and `operations-governance` define public trust, artifact, and run manifests plus a non-hashed private operator overlay, canonical generation and approvals, secret syntax boundary, redaction, and verifier-bound versus operational rotation. |
| OP-M5 | Major | Canonical sections 8, 16, and 19 and registry/reference specs: artifact discovery lacked an authorization-preserving resolver. | Sections 8, 16, and 19 plus `predicate-registry` and `reference-harness` require graph-slot and manifest authorization before fetch, exact length/hash checks, content-addressed cache, offline bundles, redundant locations, and distinct discovery error classes. |
| OP-M6 | Major | Canonical sections 16 and 19 and `reference-harness`: relayer idempotency lacked durable job ownership and submission-unknown recovery. | Sections 16 and 19 and `reference-harness` define deterministic job, settlement, and submission ids, durable phases, retry/dead-letter ownership, persistence before side effects, chain query before replacement, witness retention, restart, and two-relayer tests. |
| OP-M7 | Major | Canonical section 17 and `settlement-protocol`: replay modes and rebase behavior were underspecified. | Section 17 and `settlement-protocol` define `message-id`, `nullifier`, and atomic `both` modes, full replay scope, concurrent key tests, and a field-binding-driven rebuild/reprove/terminate/freeze table. |
| OP-M8 | Major | Canonical section 18 and `settlement-protocol`: destination validators lacked normative ABI ownership. | Section 18 and `settlement-protocol` define a common versioned ABI plus Cardano and Midnight gate outputs for canonical inputs, predecessor/successor states, authorization, action/result, replay, resource bounds, stable stage errors, and byte-level construction/runtime vectors. `S01-BLOCK-05` and `S01-BLOCK-06` remain open. |
| OP-M9 | Major | Canonical section 22 and `conformance-testnet`: mutations lacked expected-stage evidence and could invent catalog rows. | Section 22 and `conformance-testnet` define the vector envelope, precondition checks, expected stage/code, all four state digests, independent runners, gate ids, and `structural-test-only` labeling until the 42/52 catalog gate passes. |
| OP-m1 | Minor | Canonical section 19 and `reference-harness`: telemetry names lacked stable units, labels, correlation, redaction, and retention. | Section 19 and `reference-harness` define required event fields, metric units/types/bounded labels, monotonic durations, secret exclusions, and a content-addressed evidence index with retention deadlines and verification commands. |
| OP-m2 | Minor | Canonical section 23 and `conformance-testnet`: the run manifest lacked a Cardano endpoint contract. | Section 23 and `conformance-testnet` require redacted endpoint/socket, network magic and genesis, implementation revision, interfaces, chain-sync state, provenance, transport profile, preflight command/time/digest, and private credential separation. |

## Fresh reread findings

The proof-systems, consensus, and implementer/operator fresh rereads each found the same blocking deployment-domain cycle. The implementer/operator reread also found two major contract conflicts and one operational minor. These dispositions are drafted fixes, not closure findings.

| ID | Severity | Fresh finding | Drafted disposition |
| --- | --- | --- | --- |
| FR-B1 | Blocking | `DeploymentRootSetV1` reached registry, artifact, ABI, and checkpoint values that also carried the concrete domain, so direct exclusion of the outer domain field did not remove the transitive cycle. | Canonical sections 4, 6, 8, 18, 20, 22, and 23; the program roots, checkpoint, registry, ABI, and work-package contracts; OpenSpec decisions 4 and 5; and the bootstrap, registry, settlement, operations, proof-path, harness, and conformance specs now define domain-neutral semantic registry, artifact, ABI, destination-code, deployment-recipe, checkpoint, and policy templates. The fixed topological order derives the root-set digest and domain before `RegistryActivationV1`, `ArtifactAuthorizationV1`, `DestinationAbiInstanceV1`, and `RootContextV1`. Included and excluded fields, two golden derivations, mutation/reset vectors, old-domain rejection, and a transitive schema/DAG check are required. No fixed point or placeholder is allowed. |
| FR-M1 | Major | The program query contract let callers select anchors, retained a generic public-input/output hash, and decoded typed output after proof verification. | The program and canonical sections 3, 4, 7, and 16 plus `claim-protocol`, `predicate-registry`, and `reference-harness` now limit `QueryV1` to requested predicate, typed inputs, destination context, and optional constraints. Registry resolution owns anchor, finality, schemas, suite, VK/SRS/setup, architecture, operation, artifacts, replay mode, and lifecycle. Suite-native instance digests require registered acyclic preimages. Typed-result canonicalization precedes public-input reconstruction, and golden query/resolution bytes plus malformed-result expected-stage vectors are required. |
| FR-M2 | Major | Outcome rules were not one authoritative algorithm, allowed mocked degraded-lab evidence in the program, lacked an exact applicability roster, and omitted explicit catalog and public SCLS owners. | Canonical sections 23 and 24, program completion outcomes, OpenSpec decision 10, and `cardano-anchor` and `conformance-testnet` now define exact `GateRosterV1` and `OutcomeClassifierV1`. Catalogs are required for public and lab. Public SCLS availability is required for public and public-only for lab, while real lab certificate-to-SCLS mechanics remain required under `CONS-CARDANO-01`. S01-BLOCK-03 through 06 and all eight CONS gates are required for both. First-match rows reject bad rosters, then failed required gates, then missing real transitions, before lab or public success. Vectors cover overlaps, mocked lab evidence, root-only lab substitution with two real transitions, public pass, and bad rosters. |
| FR-m1 | Minor | Health/readiness discovery, unsafe versus unavailable behavior, metrics linkage, and evidence-retention effects were incomplete. | Canonical sections 19 and 23, program observability, OpenSpec decision 10, and `reference-harness` and `conformance-testnet` now define `OperationalProbeMetricProfileV1`, deployed `ProbeDiscoveryV1` records, and `EvidenceRetentionProfileV1`. Run manifests bind the profiles without inventing endpoint values. Deployment policy fills actual durations. Required outcome evidence remains through classification and independent review; expiry blocks. Unresolved-gate evidence remains until resolution or content-addressed supersession; unsupported expiry returns the gate to unresolved. |

Fresh reread counts at that checkpoint were one shared blocking finding reported
by all three readers, two major findings, and one minor finding. Those findings
required another current-document-only reread before closure.

## Closure reread dispositions

Later current-document-only reads tested the remediated contracts without reading
this review or earlier council output. Their questions and final dispositions are:

| Area | Closure question | Current disposition |
| --- | --- | --- |
| Cardano proof relation | SCLS membership/nonmembership semantics and Cardano identity were not enforceable under an exact gate. | `CONS-CARDANO-01` now owns the exact identity, certificate-message, two-level tree, membership/nonmembership, boundary, and independent-codec evidence in the machine roster. |
| Recursive bootstrap | `S0` could bind a manifest while using unrelated Cardano or Midnight base-state fields. | `BaseStateEqualityV1` maps every field outside `RootContextV1` to the approved checkpoint body; per-field mutations fail at a named base-equality stage. |
| Context ownership | One root context could accidentally select one proof suite for every predicate. | `RootContextV1` contains deployment/source state only. `ResolvedProofContextV1` owns per-claim predicate, suite, architecture, artifact, replay, and freshness selections; a fixed-domain multi-architecture vector rejects swaps. |
| Validation order | Registry policy, typed results, freshness, replay, and proof verification had conflicting orders. | Cardano, Midnight, the program, and normative specs now use one order from roster/root and authenticated resolution through typed result, authorization, reconstruction, proof, authenticated time, final checks, policy, and atomic transition. |
| Deployment DAG | Concrete code and ABI instances lacked an authenticated producer. | `DeploymentObservationV1` authenticates the confirmed deployment before ABI instantiation, root context, activation decision, initialization, and final deployment receipt. The root-set preimage remains domain neutral. |
| Replay migration | A new-domain proof could replay an event consumed under the old domain. | Every proof authenticates domain-independent `SourceEventIdentityV1`; settlement consumes its continuity key; migration proves complete exact-once continuity-root translation for all replay modes. |
| Wire ownership | Common records, suite-native proof grammar, and chain ABI wrappers overlapped. | Common deterministic CBOR owns shared records, `SuiteNativeProofProfileV1` owns proof/instance/VK/scalar/transcript/curve bytes, and the ABI digest-references and byte-preservingly embeds them while owning only chain wrappers. |
| Gate roster | Prose owner labels and missing codec evidence prevented one canonical roster digest. | `protocol/gate-roster-v1.json` is the sole 14-entry roster. It copies ordered ids into each deliverable and maps common-codec, 94-row, proof-family, performance, execution, and consensus evidence. Its 7,705 deterministic-CBOR bytes hash to `2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f`. |
| Run evidence | A run manifest depended on preflight results while also needing to exist before preflight. | Immutable `RunIntentV1` contains no run result or preflight receipt. `PreflightReceiptV1` and append-only `RunEvidenceManifestV1` bind its digest and cannot feed its preimage. |
| Relayer recovery | Raw id concatenation, open retry targets, and gate/job resume reuse were ambiguous. | Fixed-arity deterministic-CBOR tuple ids, exhaustive `FailureProfileV1` retry targets, and separate compare-and-swap `JobResumeV1` records make recovery deterministic. |
| Freeze and recovery | Delayed governance could be read as a freeze trigger. | Only authenticated source conflict or authenticated forbidden upgrade freezes. Recovery approvals and delay act only from the matching recorded frozen state. |
| Outcome classification | A lab scenario could hide a required consensus gate. | A missing required `CONS-*` entry selects classifier row 2 and only `blocked`; the public SCLS facet is the sole `public-only` lab distinction. |

The final proof-systems, consensus, and implementer/operator reads each reported
zero blocking and zero major findings. The final proof read included a focused
fresh check of the Midnight operation after its chain-specific order was aligned
with the global validation order.

## External gate dispositions

Council remediation specifies what each gate must produce but does not supply source-dependent values or runtime evidence.

| Gate | Current disposition |
| --- | --- |
| `S01-BLOCK-01` | Open. Exactly 42 Cardano and 52 Midnight source-backed rows, uniqueness, required fields, and per-row provenance are still absent. No row was invented. |
| `S01-BLOCK-02` | Open. A public Mithril signer population for the exact SCLS entity is still unconfirmed. The lab profile remains separate. |
| `S01-BLOCK-03` | Open. The authenticated Midnight event-to-header-to-MMR adapter and rejecting prototype remain unavailable. |
| `S01-BLOCK-04` | Open. The source-pinned complete-decider profile, final-KZG negative, setup binding, and measurements remain unavailable. |
| `S01-BLOCK-05` | Open. No deployed Midnight registered-operation ABI and external bridge-proof atomic receipt exists. |
| `S01-BLOCK-06` | Open. No complete Cardano ABI and reference Plutus boundary for the wrapped BEEFY/MMR claim exists. |

Every unresolved source value is an inactive versioned content-addressed gate deliverable with an accountable owner, enforcement locus, vector bundle, independent receipts, and activation rule. The draft does not invent Poseidon parameters, Halo2/KZG equations, Midnight operation names, source roots, network constants, confirmation depths, funding amounts, or predicate rows.

## Verification and closure

- **Initial council questions:** 30 total; 10 blocking, 18 major, and 2 minor.
- **Blocking review questions:** 0
- **Unresolved major review questions:** 0
- **Council gate:** closed
- **Strict change validation:** `npx openspec validate sprint-01-foundation --strict --no-interactive` passed: `Change 'sprint-01-foundation' is valid`.
- **Repository OpenSpec validation:** `npm run openspec:validate` passed: 1 item passed and 0 failed.
- **Canonical heading and nonempty-section checks:** passed with exactly 25 approved headings and 25 nonempty bodies.
- **Gate roster:** 14 unique entries, 7,705 deterministic-CBOR bytes, independently reproduced SHA-256 `2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f`.
- **Stale-claim, placeholder, Humanizer-pattern, ASCII punctuation, and whitespace scans:** passed; `git diff --check` reported no whitespace errors.
