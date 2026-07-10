# Midnight <-> Cardano proof bridge program design

**Date:** 2026-07-09

**Status:** Council-reviewed design for user approval

## Purpose

This program turns the current bridge research into a buildable specification and
a reference proof harness aimed at Cardano and Midnight testnets. The harness lets
an application on either chain ask a typed question about the other chain, obtain a
proof from an untrusted prover, and verify that proof before authorizing a local
transaction.

The proof-of-concept paths are fixed:

- Cardano facts are proved with Halo2/Plonk and verified by a Midnight contract.
- Midnight facts are recursively processed and wrapped in Groth16 for verification
  by a Cardano Plutus validator.

Direct Halo2/KZG verification, native BEEFY-ECDSA verification, and a future
BLS-finality verifier remain production alternatives. They do not replace the
Groth16 landing in this proof of concept. A production mode can be selected only
through a versioned decision record backed by target-network measurements.

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
- Implemented proof circuits, destination validators, source adapters, and
  submission clients needed by the reference harness.
- Conformance vectors, negative tests, failure codes, and benchmark procedures.
- Deployment and operating instructions for a two-testnet proof of concept.

The program does not claim production readiness. Production requires independent
audits, a reviewed Groth16 ceremony, stable upstream finality formats, an accepted
Cardano state-certification path, and deployment governance.

## Completion outcomes

Program results use three labels:

- **live-pass:** both selected public testnets accept claim-authorized
  transactions under the stated source-consensus and proof assumptions.
- **degraded-lab:** both directions execute, but at least one direction uses a
  project-operated certifier, fixture anchor, mock transition, or other trust root
  that is not part of the selected public testnet.
- **blocked:** a required proof relation, authenticated state path, execution
  surface, or public-testnet dependency cannot be completed.

Only live-pass satisfies the proof-of-concept success claim. A degraded-lab result
is useful engineering evidence but cannot be described as a trustless testnet
bridge. A blocked result records the reproducer, owner, interface boundary, and
evidence needed to resume.

The design is buildable, and the proof of concept reaches live-pass, when all of
the following are true:

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
   meet stated thresholds on named hardware and target-network protocol
   parameters.
9. Every one of the 94 predicates passes schema validation, registry round-trip,
   a positive vector, and its required negative vectors. The live testnet subset
   is recorded separately.

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
root of trust. Under the named source-consensus threshold, proof-soundness,
setup-integrity, and governance assumptions, a dishonest provider can delay
delivery or submit invalid data but cannot make the destination accept a false
claim.

This document uses "proof-enforced" for that property. "Trustless" is reserved for
a named trust profile and never means that consensus, setup, or governance
assumptions have disappeared.

## Roots of trust

Each destination has three categories of trust root. A category can contain
several cryptographic artifacts.

| Destination | Foreign consensus root | Proof root | Policy root |
| --- | --- | --- | --- |
| Cardano | Midnight checkpoint, BEEFY current-set commitment, and finality-adapter version | Groth16 wrapper VK, every authorized inner/aggregation VK, KZG SRS hashes, and ceremony transcript hashes | Predicate-registry root, deployment policy, and emergency-recovery policy |
| Midnight | Cardano identity, Mithril genesis verification key or approved certificate checkpoint, and anchor-profile version | Halo2/Plonk operation VKs, aggregation VKs, and accepted Midnight SRS hashes | Predicate-registry root, deployment policy, and emergency-recovery policy |

The proof root is an artifact-binding graph. It records which proof suite, circuit
architecture, statement schema, VK, proving key, SRS prefix, and setup transcript
belong together. A proof is rejected if any node in that graph is absent from the
active registry, even when the cryptographic proof verifies.

Each tracked consensus state also carries a source-protocol fingerprint. For
Midnight this binds the runtime code or spec version, consensus configuration,
authority-selection rules, state encoding, and MMR format. For Cardano it binds
the ledger era, protocol-parameter hash, signed-entity type, SCLS version, and
certificate-suite version. The proof authenticates the fingerprint from finalized
source state when the source exposes it. Otherwise, a policy-root transition must
approve it before activation. Unknown, downgraded, or mismatched fingerprints
halt the affected domain.

### Cardano-side bootstrap

The Cardano validator tracks this Midnight state:

- source network and genesis identity
- latest finalized block number
- latest accepted MMR root
- current BEEFY validator-set id, authority root, and weight model
- next BEEFY validator-set id and authority root when announced
- latest accepted mandatory block
- finality-adapter and proof-suite ids
- active predicate-registry root
- consumed-message or nullifier root

The verifier rules fix the BEEFY commitment encoding, signature domain, quorum
calculation, authority membership proof, mandatory-block handoff, MMR leaf format,
and event inclusion path. The outgoing set authenticates a mandatory-block handoff
to the incoming set. Set ids are counters, not key commitments, so every transition
binds both the id and authority root.

The proof-of-concept suite accepts equal-weight BEEFY authorities only. The
published initial sizes are 6 on govnet, 7 on devnet, and 10 on mainnet. A
benchmark sets the circuit's maximum authority count. A larger set or a runtime
change to weighted voting is rejected until a new finality adapter and proof suite
are registered.

### Midnight-side bootstrap

The Midnight contract tracks this Cardano state:

- Cardano network magic and genesis identity
- current and previous Mithril certificate hashes
- Mithril era, aggregate-signature type, and certified epoch
- current and next aggregate verification keys
- current and next Mithril protocol parameters
- latest SCLS slot, namespace-set hash, and SCLS root
- anchor-profile and proof-suite ids
- active predicate-registry root
- consumed-message or nullifier root

The verifier rules fix the Mithril certificate-chain algorithm, accepted security
parameter floor, signed-message format, SCLS version, namespace definitions, leaf
hashing, canonical encoding, and result freshness.

The accepted public-testnet claim is "Mithril-certified SCLS artifact" only when an
accepted public Mithril signer population certifies that exact SCLS signed-entity
type. It is not equivalent to replaying Cardano consensus. A project-operated
signer population uses a separate lab anchor profile and can produce only a
degraded-lab result.

CIP-0165 defines a canonical snapshot and root. It does not define this bridge's
membership or nonmembership wire proof. The bridge specification must fix tree
shape, padding, namespace completeness, ordered-neighbor rules, path encoding, and
boundary vectors.

### Checkpoint and genesis modes

The proof of concept uses checkpoint bootstrap. The checkpoint is an explicit
weak-subjectivity decision, not a fact made canonical by repetition. A versioned
manifest contains:

- source network, genesis hash, and chain-spec or era hash
- checkpoint height or slot, block hash, state or MMR root, and finality proof
- current and next authority, AVK, and protocol-parameter commitments
- finality adapter, anchor profile, proof suite, VK, SRS, and registry hashes
- destination network, deployment domain, verifier hash, and recovery-policy hash
- derivation inputs, approval policy, and approval signatures

The configured approval threshold selects the checkpoint. At least two
independently administered full nodes must reproduce its derivable fields before
approval. This cross-check detects operator error but does not remove the
checkpoint trust assumption. The deployed verifier binds the complete manifest
digest.

Each checkpoint profile fixes the approver keys and threshold, node-independence
criteria, exact finalized-point agreement rule, maximum checkpoint age and source
lag, derivation procedure, and manifest-signature algorithm. A stale, mismatched,
or under-approved manifest is ineligible for live-pass and returns blocked.

The production specification also defines genesis bootstrap. In that mode, the
first trusted consensus state is the source genesis identity plus its initial
authority or certification root. Recursive proofs carry every accepted set
transition forward from that state. Cardano genesis does not derive the Mithril
genesis verification key; that key remains a separate Mithril trust root. The
conformance suite verifies at least one authority or AVK rotation from each
genesis base case.

Routine governance cannot skip to an arbitrary checkpoint. Emergency checkpoint
replacement requires a separate, delayed recovery policy and produces a new
deployment domain so old proofs cannot cross the boundary. Recovery credentials,
threshold, delay, asset-migration effect, and old-domain shutdown are part of the
policy root.

All PoC trust roots are immutable within a deployment domain: checkpoint digest,
finality adapter, anchor profile, proof-suite graph, VK/SRS set, predicate
registry, and recovery-policy hash. Changing one deploys a new domain. The
production specification may allow in-place transitions only through a consensus
state machine that fixes authority, threshold, delay, activation, deactivation,
in-flight-proof handling, freeze, rollback prohibition, and domain effects.

A testnet reset changes the deployment domain even if the network name or magic is
reused. Genesis, chain-spec, certification-root, verifier, registry, and nullifier
domains are rebound, and the reset drill proves that an old proof is rejected.

## Proof suite decisions

The Cardano-to-Midnight proof-of-concept suite uses the Midnight Halo2/Plonkish
stack over BLS12-381. A deployed Midnight operation verifies the proof relation
and updates the tracked Cardano state. Sprint 2 must demonstrate that execution
surface before the program treats arbitrary external proof submission as
available.

The Midnight-to-Cardano proof-of-concept suite uses commitment-Groth16 in the
BSB22 form over BLS12-381. Its public commitment binds the canonical claim
transcript reconstructed by the Plutus validator. The wire format, equations,
commitment key, added proof elements, subgroup checks, and setup transcript are
part of the suite id. Vanilla Groth16 is not wire-compatible and cannot be
substituted under the same id.

The Plutus validator reconstructs a domain-separated canonical claim_digest and
supplies it as an explicit Groth16 public input. The wrapper constrains that value
to the exact inner Halo2 public statement and typed output. BSB22 commitment D
commits the suite's designated circuit wires; it is not the verifier-visible
claim digest and cannot replace the public-input equality check. Conformance holds
the proof and D fixed, mutates each proof-bound claim field, and requires
rejection.

The wrapper proves the complete Halo2/KZG decision relation. Preparing or
accumulating a KZG check without enforcing the final decider is insufficient.
Sprint 2 must reject a forged or invalid accumulator and report constraints,
maximum SRS degree, proving memory, proving latency, and Cardano verification
cost. Failure of that gate blocks the requested Groth16 proof-of-concept path; it
does not silently switch the PoC to native ECDSA or direct Halo2 verification.

KZG and Groth16 setup artifacts have independent inventories and ceremonies.
Their hashes, degrees, contribution transcripts, honest-contributor assumptions,
and circuit architecture are explicit registry inputs. The composed soundness
analysis targets at least 128 bits and sets finite recursion and aggregation
bounds.

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
- proof-suite id, circuit-architecture hash, and verifier or program id
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

### Proof composition relation

Each direction defines three relations and their equality constraints:

1. The finality relation outputs a source domain, finalized chain point, finality
   rule, and authenticated anchor.
2. The inclusion relation consumes that exact anchor and outputs the state object
   or namespace root that contains the queried fact.
3. The predicate relation consumes that exact state object and outputs the typed
   result committed by the claim envelope.

The circuit enforces equality of network, deployment domain, height or slot,
anchor digest, state version, predicate id, output schema, destination context,
and replay value across those relations. A valid finality proof for root A cannot
be composed with a valid inclusion or predicate proof for root B.

The recursive base case binds the complete bootstrap-manifest digest and
deployment domain. The step case binds the predecessor light-client state and the
successor state. Negative vectors cover alternate checkpoints, skipped
transitions, mixed roots, sibling certificate chains, and cross-domain replay.

### Public statement encoding

Every suite publishes a field-binding matrix that marks each envelope field as
proof-bound, validator-only, or advisory. Proof-bound fields are encoded into one
domain-separated canonical transcript before hashing or field reduction. The
suite fixes field types, units, byte order, maximum lengths, integer bounds,
inclusive time comparisons, hash-to-field mapping, subgroup checks, and rejection
of aliases or trailing data.

Proof fixtures pin statements, witnesses, suite artifacts, clocks, and test RNG
seeds. Production provers use a CSPRNG. Conformance compares accepted statements
and outputs unless a suite explicitly guarantees byte-stable proofs.

### Atomic destination transition

The destination supports two proof-enforced transitions:

1. **advance-and-consume** requires the exact predecessor light-client state,
   advances height or certificate state monotonically, checks a claim under the
   successor anchor, applies the destination action, and consumes its replay key.
2. **consume-current-anchor** leaves the light-client state unchanged and consumes
   a distinct claim under the already accepted current anchor.

Multiple claims may use one anchor when their message ids or nullifiers differ.
Two submissions built against one predecessor race on the continuing-state
output; the loser refreshes and uses consume-current-anchor or rebuilds against
the successor. The PoC does not consume an older anchor after advancement. A
relayer must refresh the witness under the current anchor. A rejection or
interrupted submission cannot consume replay state. Conflicting finality evidence
halts the affected domain for governance review.

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
- proof-suite id, circuit-architecture hash, and verifier-key graph
- statement-schema, result-schema, and SRS-manifest hashes
- proof-bound template selector and parameter hash
- destination context requirements
- replay behavior
- positive and negative vectors
- example use in a proof-enforced transaction
- primary sources and implementation status

The initial source files for the 42 Cardano and 52 Midnight sibling catalogs are
not present in the current checkout. Sprint 1 must recover them or reconstruct a
source-backed equivalent. Dependent registry work cannot begin until a mechanical
gate reports 42 unique Cardano records and 52 unique Midnight records, with no
duplicate ids and a provenance digest for every row. Reconstruction must preserve
provenance and may not invent an entry to reach a target count.

Template reuse is a circuit property, not a registry shortcut. Each family defines
a constrained selector or a fixed outer aggregation relation that authorizes
dynamic inner keys. The catalog records the number of resulting Halo2
architectures, common K values, Groth16 wrappers, setup ceremonies, and padding
cost. Every predicate receives cross-predicate substitution tests even when only
one live testnet example is run for its family.

## Living design document

The existing file
knowledge_base/bridges/midnight-cardano-recursive-bridge.md remains the canonical
human-readable design. Its body describes only current behavior and evidence. Git
history and OpenSpec review artifacts carry the change record.

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
project-local installation pinned to @fission-ai/openspec 1.5.0 in package.json
and the package lock. The custom proof-bridge schema extends the standard
spec-driven artifact chain:

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

The executable OpenSpec baseline contains:

    openspec/config.yaml
    openspec/schemas/proof-bridge/schema.yaml
    openspec/specs/<capability>/spec.md
    openspec/changes/<sprint-change>/

Each sprint owns one OpenSpec change directory:

    openspec/changes/sprint-01-foundation/
    openspec/changes/sprint-02-feasibility-gates/
    openspec/changes/sprint-03-claim-protocol/
    openspec/changes/sprint-04-cardano-anchor/
    openspec/changes/sprint-05-midnight-anchor/
    openspec/changes/sprint-06-proof-composition/
    openspec/changes/sprint-07-proof-implementation/
    openspec/changes/sprint-08-harness-settlement/
    openspec/changes/sprint-09-predeployment-conformance/
    openspec/changes/sprint-10-testnet-poc/
    openspec/changes/sprint-11-program-closure/

OpenSpec configuration supplies repository context and enforces these rules:

- Requirements use MUST, SHALL, or MAY with testable scenarios.
- Every security-sensitive requirement names its trust assumption.
- Every chain fact cites a primary source or a gated local source pack.
- Every binary format specifies canonical encoding and bounds.
- Every accepted proof has negative scenarios.
- Every change updates the living design and traceability matrix.

CI and local verification use:

    npx openspec validate --all --strict --no-interactive

An active change is archived only after its tasks, council review, verification
evidence, stable-spec deltas, and living-design update agree.

## Implementation layout

The implementation plan assigns work to these repository boundaries:

    predicates/                  machine-readable 42/52 catalog and registry data
    protocol/                    shared schemas, canonical encoders, and vectors
    circuits/cardano-halo2/      Cardano anchor and predicate circuits
    circuits/midnight-halo2/     Midnight recursion and aggregation circuits
    circuits/groth16-wrapper/    full Halo2/KZG decider wrapper
    contracts/cardano/           Plutus verifier and continuing state
    contracts/midnight/          Compact/ledger verifier operation and state
    reference/common/            query, claim, result, and artifact APIs
    reference/cardano/           Cardano source adapter and submission client
    reference/midnight/          Midnight source adapter and submission client
    conformance/                 fixtures, mutation cases, and independent checks
    deploy/testnet/              manifests, scripts, runbooks, and evidence indexes

The reference stack uses Rust for Halo2/Midnight circuits, source adapters, and
the common CLI; Go with gnark for the commitment-Groth16 wrapper and prover;
Plinth compiled to UPLC for the Cardano validator; Compact with TypeScript
bindings for the Midnight contract and submission client; and CDDL plus JSON
Schema for canonical records and diagnostic views. A feasibility result may
replace a language only through a decision record that preserves wire and proof
suite ids.

The detailed plan gives every work package its inputs, outputs, file paths,
dependencies, verification command, and stop condition. Generated proving keys,
raw logs, secrets, and large runtime artifacts are not committed. The repository
tracks their content hashes, public receipts, redacted evidence indexes, and
reproduction commands.

## Sprint model

A sprint is a bounded set of agent-executable work packages with one review and
verification gate. It is not an estimate in human hours. The program has eleven
sprints and 62 work packages.

### Sprint 1: Foundation and catalog recovery

Five work packages:

1. **S01-W01:** Pin and initialize OpenSpec with the proof-bridge review schema.
2. **S01-W02:** Establish stable spec domains, requirement ids, and the
   machine-readable traceability schema.
3. **S01-W03:** Recover or reconstruct the Cardano 42 and Midnight 52 predicate
   catalogs with source digests.
4. **S01-W04:** Normalize and mechanically validate all 94 predicate records.
5. **S01-W05:** Specify checkpoint, genesis, artifact, fixture, and deployment
   manifest schemas.

Exit gate: the catalog validator reports exactly 42 unique Cardano records and 52
unique Midnight records with provenance. An incomplete catalog blocks dependent
registry work.

### Sprint 2: Architecture feasibility gates

Six work packages:

1. **S02-W01:** Prototype the complete Halo2/KZG-to-Groth16 relation, including
   the final accumulator decider and an invalid-accumulator rejection test.
2. **S02-W02:** Prove the Midnight execution surface can accept an untrusted
   Cardano claim, resolve an operation VK, reconstruct public inputs, and update
   light-client state atomically.
3. **S02-W03:** Resolve and prototype the authenticated Midnight
   event-to-header-to-MMR path, including parent-block rules.
4. **S02-W04:** Determine whether a public Mithril signer population can certify
   the required SCLS signed-entity type and define the separate lab profile.
5. **S02-W05:** Fix the checkpoint eligibility profile, then implement manifest
   generation, approval verification, freshness checks, and independent
   reproduction against two source nodes.
6. **S02-W06:** Record go, degraded-lab, or blocked decisions for every gate and
   rebaseline downstream packages without changing claim semantics.

Exit gate: the program does not proceed to implementation on an assumed proof
surface. Each required relation has a rejecting prototype, a measured resource
profile, and a named trust profile.

### Sprint 3: Claim protocol and registry

Five work packages:

1. **S03-W01:** Specify canonical query, envelope, proof-response, result, and
   artifact records with bounded wire types.
2. **S03-W02:** Specify the finality, inclusion, predicate, and envelope
   composition relations with a field-binding matrix.
3. **S03-W03:** Specify registry membership, nested key/SRS authorization,
   immutable PoC roots, production lifecycle transitions, freeze, deprecation,
   and recovery.
4. **S03-W04:** Specify validation order, time semantics, permanent and retryable
   failures, idempotency, and replay behavior.
5. **S03-W05:** Produce cross-language golden transcripts, boundary vectors, and
   cross-anchor negative vectors.

Exit gate: two independent protocol codecs and public-statement reconstructors
produce the same bytes and field elements, then reject mixed anchors, key
substitution, encoding aliases, stale claims, and cross-domain replay.

### Sprint 4: Cardano anchor and Halo2 path

Five work packages:

1. **S04-W01:** Specify the Mithril genesis, checkpoint, base, and step
   certificate relations, including AVK, protocol-parameter, era, signed-entity,
   and source-protocol fingerprint transitions.
2. **S04-W02:** Specify the bridge-owned SCLS membership and nonmembership proof
   format with completeness and padding rules.
3. **S04-W03:** Specify the recursive Cardano Halo2 state tuple, suite id, public
   inputs, base case, and step case.
4. **S04-W04:** Build the minimal Midnight verifier operation and tracked-state
   prototype selected by S02-W02.
5. **S04-W05:** Add genesis-to-rotation, checkpoint, sibling-chain, reset, and
   parameter-substitution vectors.

Exit gate: a Cardano fact is traced from a named Mithril/SCLS trust profile into a
Midnight-verifiable Halo2 statement with no implicit finality upgrade.

### Sprint 5: Midnight anchor and Groth16 path

Five work packages:

1. **S05-W01:** Specify the BEEFY current/next-set state machine, quorum,
   authority membership, mandatory-block handoff, catch-up rules, and authenticated
   runtime/consensus fingerprint.
2. **S05-W02:** Implement the authenticated Midnight event path selected by
   S02-W03 and produce inclusion/noninclusion vectors.
3. **S05-W03:** Specify Midnight predicate anchors for contract, Zswap, DUST, and
   public ledger facts that the event path can actually authenticate.
4. **S05-W04:** Specify the recursive Midnight state and the complete Groth16
   public relation.
5. **S05-W05:** Build the Cardano continuing-state prototype with authority
   bounds, equal-weight enforcement, atomic settlement, and reset handling.

Exit gate: a Midnight fact is traced from authenticated ledger data through the
BEEFY-signed MMR root into the exact statement reconstructed by Cardano.

### Sprint 6: Proof composition, setup, and settlement ABI

Seven work packages:

1. **S06-W01:** Pin versioned Halo2, KZG, aggregation, and Groth16 suite
   identifiers, transcripts, curve rules, and wire formats.
2. **S06-W02:** Define the artifact-binding graph schema and logical slots for
   every inner VK, aggregation VK, wrapper VK, proving key, SRS prefix, and setup
   transcript.
3. **S06-W03:** Map all 94 predicates to formal proof-template relations and
   proof-bound selectors.
4. **S06-W04:** Select shared architectures and K values, then measure padding
   and heterogeneous-aggregation costs.
5. **S06-W05:** Specify setup inventories, independent KZG/Groth16 ceremony
   assumptions, verifier-key equality, and upgrade policy.
6. **S06-W06:** Write the composed soundness argument, recursion bounds, target
   security level, and benchmark pass/fallback thresholds.
7. **S06-W07:** Freeze the verifier/application boundary, settlement ABI, message
   identity, lane, nullifier, retry, refund, asset-identity, and conservation
   semantics consumed by both destination contracts.

Exit gate: an independent implementer can identify every proof relation and trusted
artifact without inferring a protocol choice from a library name.

### Sprint 7: Circuit and verifier implementation

Seven work packages:

1. **S07-W01:** Implement Cardano-anchor and Cardano-predicate Halo2 circuits.
2. **S07-W02:** Implement Midnight finality, event, predicate, and aggregation
   Halo2 circuits.
3. **S07-W03:** Implement the full Groth16 wrapper selected by S02-W01, including
   the final decider.
4. **S07-W04:** Implement the Cardano Plutus verifier and continuing state.
5. **S07-W05:** Implement the Midnight verifier operation and continuing state.
6. **S07-W06:** Implement independent verifier checks and key, accumulator,
   subgroup, transcript, and selector mutation tests.
7. **S07-W07:** Produce reproducible builds, populate the artifact-binding graph
   with content hashes, and publish manifests without committing toxic waste,
   secrets, or generated proving keys.

Exit gate: both proof stacks build from a clean checkout, accept their golden
vectors, reject the mutation suite, and meet the feasibility thresholds.

### Sprint 8: Reference harness and settlement

Seven work packages:

1. **S08-W01:** Implement versioned query, prove, verify, submit, and inspect CLI,
   API, and ABI contracts.
2. **S08-W02:** Implement offline-fixture and live-node adapters for both chains.
3. **S08-W03:** Implement proof orchestration and registry-driven dispatch.
4. **S08-W04:** Implement Cardano and Midnight submission clients with
   idempotency and confirmation tracking.
5. **S08-W05:** Implement the S06-W07 settlement ABI, including
   advance-and-consume, consume-current-anchor, concurrency rebasing, message
   identity, lanes, nullifiers, retries, refunds, asset identity, and conservation.
6. **S08-W06:** Implement relayer persistence, failure classification, data
   availability, correlation ids, health checks, metrics, and redacted logs.
7. **S08-W07:** Run at least one complete local query-to-settlement transaction
   for every proof-template family, covering both directions with deterministic
   statements and controlled fixtures.

Exit gate: a process restart, duplicate relayer, stale proof, malformed witness,
and uncertain submission cannot cause duplicate or unauthorized settlement.

### Sprint 9: Predeployment conformance

Six work packages:

1. **S09-W01:** Complete the 94-row coverage matrix, registry round-trips, and
   per-predicate positive and required negative vectors.
2. **S09-W02:** Run cross-predicate substitution, mixed-anchor, key/SRS
   substitution, canonical-encoding, protocol-upgrade, trust-root mutation, and
   cryptographic mutation suites.
3. **S09-W03:** Run fault injection for RPC loss, prover timeout, rotation races,
   stale anchors, duplicate submission, destination rollback, and restart.
4. **S09-W04:** Measure proof size, proving RAM and latency, verification cost,
   batching, authority bounds, and percentile thresholds on named hardware.
5. **S09-W05:** Finalize deployment manifests, funded roles, secret references,
   preflight, smoke, restart, recovery, and evidence-retention procedures.
6. **S09-W06:** Run the predeployment council and security gate, validate the
   populated artifact graph, then freeze suite ids and deployable artifact hashes.

Exit gate: no blocking or major question remains, every deployable artifact is
content-addressed, and all local conformance and fault tests pass.

### Sprint 10: Testnet proof of concept

Five work packages:

1. **S10-W01:** Generate and approve Cardano and Midnight checkpoint manifests
   from independent public-testnet nodes.
2. **S10-W02:** Deploy registries, destination verifiers, harness services, and
   relayers with recorded transaction ids and artifact hashes.
3. **S10-W03:** Execute a Cardano claim that authorizes a finalized Midnight
   transaction.
4. **S10-W04:** Execute a Midnight claim that authorizes a finalized Cardano
   transaction.
5. **S10-W05:** Record benchmarks and public receipts, then run restart, stale
   proof, duplicate submission, and testnet-reset rejection drills.

Exit gate: the result is labeled live-pass, degraded-lab, or blocked under the
completion-outcome rules. Only live-pass satisfies the proof-of-concept goal.

### Sprint 11: Conformance closure and production path

Four work packages:

1. **S11-W01:** Reconcile every examination-checklist item against requirements,
   code, vectors, deployment evidence, or a named production blocker.
2. **S11-W02:** Run the final reader council, threat-model review, source gates,
   OpenSpec validation, and clean-build verification.
3. **S11-W03:** Archive accepted OpenSpec changes and compile the stable specs.
4. **S11-W04:** Publish the production-gap register, audit scope, ceremony plan,
   genesis-mode evidence, and finality-adapter migration rules.

Exit gate for go or degraded-lab branches: the repository contains one coherent
buildable specification, an executable reference harness, the accurately labeled
PoC result, and a production path that does not hide unresolved trust assumptions.

Exit gate for a blocked branch: the repository contains the coherent specification
completed through the blocking gate, runnable reproducers, skipped-package records,
owners, resume conditions, interface contracts, and the production-gap register.
It does not claim an executable two-direction harness or testnet proof of concept.

### Dependency graph

    S01 -> S02
    S01 + S02 -> S03
    S02 + S03 -> S04 and S05
    S03 + S04 + S05 -> S06
    S06 -> S07
    S03 + S04 + S05 + S07 -> S08
    S07 + S08 -> S09
    S09 -> S10
    S10 -> S11

Sprints 4 and 5 may run concurrently after Sprint 3. No deployment package may
start before Sprint 9 closes.

If Sprint 2 returns go, the full graph continues. A degraded-lab decision may
continue through Sprint 10 under its separate trust profile, but it cannot produce
live-pass. A blocked decision stops affected downstream packages and jumps to the
blocked form of Sprint 11. Unaffected research or a single direction may continue
for evidence, but the overall program result remains blocked.

## Traceability

Every normative claim has a stable requirement id. The canonical record is
traceability/requirements.jsonl under a versioned schema. It maps:

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
evidence and verification command succeed. The validator rejects duplicate ids,
dangling predicates, missing sources, absent vectors, unrecognized status values,
and closure without required evidence.

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

Before council review, the Deep Research Toolkit compiles the current knowledge
base. The retrieval-planner skill searches relevant pages and claims, composes a
verbatim-gated dossier, and lists mechanical contradiction candidates. Only
included dossier claims may support a design decision. Multi-valued relations are
not treated as contradictions without reading their evidence.

The canonical design describes the bridge as a current system. It contains no
revision narration. Git and committed review artifacts preserve the audit trail.

The council gate is:

    technical draft
    -> compiled knowledge index and gated dossier
    -> humanizer pass
    -> independent council review
    -> question resolution
    -> clean rewrite
    -> humanizer preservation check
    -> fresh council reread
    -> OpenSpec and repository verification

A sprint cannot close with an unanswered blocking question or a major ambiguity
that prevents implementation or testing.

Blocking means that the claimed proof relation, trust profile, or deployment
cannot be implemented safely. Major means that two competent implementers could
produce incompatible or untestable systems. Minor means that the design remains
implementable but lacks useful precision. Fresh readers receive the current
document and source dossier, not older drafts or prior council conclusions.

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

## Failure, observability, and evidence

The harness uses one persisted state machine from query receipt through source
finality, witness collection, proof generation, destination submission, and
destination confirmation. Every failure code is classified as permanent,
retryable, or manual-recovery. Retry policy, backoff, dead-letter state,
idempotency key, and nullifier effect are testable requirements.

A correlation id links the query, source anchor, proof job, relayer attempt,
destination transaction, registry version, and consumed-message result. Structured
events expose source-finality lag, queue depth, proving latency, retries,
destination confirmation, registry mismatch, and conservation failures. Health
and readiness checks distinguish unavailable dependencies from an unsafe verifier
state.

Tracked deployment evidence contains manifest digests, artifact hashes, public
transaction ids, redacted configuration, benchmark summaries, and reproduction
commands. Raw logs, endpoint credentials, secrets, and large artifacts remain
outside git under a declared retention policy. The evidence index records their
content hashes and storage locations without exposing secret values.

## Dependencies and hard blockers

The program has six known hard dependencies:

1. The three sibling predicate-catalog files are missing from the recorded local
   path. Full catalog recovery or source-backed reconstruction is a Sprint 1 gate.
2. The full Halo2/KZG decider inside the selected commitment-Groth16 wrapper has
   no measured bridge prototype. Sprint 2 must build and reject an invalid
   accumulator before circuit implementation continues.
3. The exact Midnight execution surface for an externally requested Cardano proof
   must be demonstrated rather than inferred from proof-library availability.
4. No public Cardano BEEFY validator currently consumes Midnight RelayChainProof.
   The reference Groth16 path must supply that verification boundary.
5. The public relay object does not include the event or MMR-leaf inclusion proof.
   Sprint 2 must resolve the path and Sprint 5 must implement it.
6. Mithril does not yet provide a confirmed public SCLS certification module for
   this use. A project-operated signer setup can test mechanics, but the design must
   label its trust profile and cannot produce a live-pass Cardano-testnet result.

Future Midnight finality changes are isolated behind the finality-certificate
interface. A change creates a new finality adapter, proof suite, registry binding,
anchor-profile version, migration rule, and rejection boundary. Predicate
semantics can remain stable, but affected catalog records receive new versions.

Each blocker has an owner, reproducer, resume condition, and affected interface in
the active OpenSpec review artifact. A blocker cannot be converted into program
success by changing its label.

## Verification

Every sprint runs:

- npx openspec validate --all --strict --no-interactive
- knowledge compilation, retrieval-planner dossier composition, and contradiction
  adjudication for the sprint's design claims
- claim/source quote gates for new research packs
- traceability count, uniqueness, link, and requirement-id checks
- canonical encoding, field-boundary, conformance, and mutation tests
- clean-checkout builds for affected circuits, contracts, and harness components
- git diff whitespace checks
- the sprint-specific proof, harness, or deployment verification
- a clean working-tree check after the sprint commit

Benchmark gates name hardware, software revisions, warm/cold method, sample count,
percentiles, authority-set size, target protocol parameters, and pass/fallback
thresholds. Completion claims cite fresh command output and deployment evidence.
