---
type: Concept
title: Midnight <-> Cardano recursive proof bridge design
timestamp: '2026-07-10T06:51:53Z'
description: Canonical living design for a bidirectional proof-enforced bridge between Cardano and Midnight.
aliases:
- recursive proof bridge
- midnight cardano bridge design
tags:
- bridge
- design
- groth16
- halo2
- plonk
- recursion
- cardano
- midnight
status: draft
okf_version: '1.0'
---

# Midnight <-> Cardano recursive proof bridge design

## 1. Document control

This page is the canonical readable design for the bridge program. The active
[Sprint 1 OpenSpec change](../../openspec/changes/sprint-01-foundation/design.md)
contains the normative foundation, negative scenarios, implementation tasks, and
review record. The
[program design](../../docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md)
sets the approved proof paths and program boundaries. Neither record is deployment
evidence.

| Field | Value |
| --- | --- |
| Design state | Foundation design; no bridge deployment outcome has been assigned |
| Evidence cutoff | 2026-07-10 |
| Selected Cardano to Midnight path | Midnight Halo2/Plonkish verification over BLS12-381 |
| Selected Midnight to Cardano path | Full-decider BSB22 commitment-Groth16 over BLS12-381 |
| Bootstrap mode for the proof of concept | Approved checkpoint manifest |
| Production bootstrap target | Verification from source genesis and independent certification roots |
| Normative change | `openspec/changes/sprint-01-foundation/` |
| Source register | [Knowledge-base source records](../sources/index.md) |

Direct Halo2/KZG verification on Cardano, native BEEFY-ECDSA verification, and a
future BLS finality adapter are production candidates. They are not substitutes
for either selected proof-of-concept path under the same suite id. The six named
foundation blockers in section 24 remain open. The active Sprint 1 review is
initialized; its Deep Research Toolkit dossier and independent proof-systems,
consensus, and implementer/operator council have not run. Git history and the
OpenSpec review record carry change history; the body below describes the system
and its evidence without revision narration.

## 2. Purpose and scope

The bridge lets an application on either destination chain ask a typed question
about the other chain and authorize a local transition only after verifying the
answer. An untrusted service may collect source data, build a witness, generate a
proof, and relay the result. It cannot select proof semantics or make the
destination accept a false claim.

The program covers:

- a shared query, claim, proof-response, and typed-result protocol;
- checkpoint and genesis bootstrap profiles for both source chains;
- exactly 42 Cardano predicate records and 52 Midnight predicate records once the
  missing source catalogs are recovered;
- a registry that binds predicates to anchors, proof suites, circuit
  architectures, verifier keys, setup material, schemas, and deployment domains;
- recursive source-finality, inclusion, and predicate relations;
- Cardano and Midnight destination validators with atomic replay-safe settlement;
- a reference harness, conformance vectors, benchmarks, deployment manifests, and
  operating evidence.

Only Midnight public state can support a claim visible to Cardano. Private client
state is not a foreign-chain anchor; it must first produce a proof-bound public
effect under the [Midnight dual-state model](../midnight/overview.md). On Cardano,
transaction inclusion alone is not a ledger-state or finality proof.

The design uses `proof-enforced` for authorization that depends on verified
consensus, proof, setup, registry, and policy assumptions. `Trustless` names a
specific trust profile; it does not mean those assumptions disappear. The program
does not claim production readiness, public SCLS certification, a complete
Midnight event path, a deployed external-proof operation on Midnight, or a
completed two-way testnet bridge.

## 3. System model

Six components take a claim from source data to destination authorization:

1. A source adapter reads a node, certificate service, or deterministic fixture and
   constructs an authenticated witness.
2. A query selects the predicate, source scope, accepted anchor, destination
   context, result schema, expiry, and replay behavior.
3. A proof generator resolves the registered proof suite and proves finality,
   inclusion, and predicate semantics.
4. A relayer transports the claim envelope, proof, public witness, and registry
   evidence.
5. A destination verifier reconstructs the public statement and verifies policy
   and proof authorization.
6. A destination application consumes the typed result and updates replay state in
   the same atomic transition.

The selected flows are:

```text
Cardano source
  -> Mithril certificate chain and proposed SCLS anchor
  -> Cardano finality, inclusion, and predicate relations
  -> Halo2/Plonk recursion or aggregation
  -> registered Midnight operation
  -> tracked Cardano state + application action + replay update

Midnight source
  -> BEEFY-ECDSA commitment over an MMR root
  -> Midnight finality, event inclusion, and predicate relations
  -> Midnight Halo2/KZG recursion and aggregation
  -> full Halo2/KZG decider inside BSB22 commitment-Groth16
  -> Plutus V3 validator
  -> tracked Midnight state + application action + replay update
```

The current Cardano-to-Midnight plumbing is not this endpoint. Cardano-based
Midnight System Transactions trust the producer's chosen Cardano range even though
validators reconstruct the body for completeness
([CMST](cardano-system-transactions.md)). The current `c2m-bridge` runtime path also
uses governance-approved Cardano transaction hashes (`src-0041`). In the other
direction, `midnight-beefy-relay` serializes a useful finality input but does not
provide event inclusion or a Cardano settlement validator (`src-0039`). These
interfaces inform adapters; they are not accepted as proof-enforced settlement.

## 4. Terminology and invariants

An `anchor` is an authenticated source commitment together with the rule under
which the destination accepts it. `Finalized` means accepted by the named source
finality rule. `Certified` means that a named certification system signed a
specific message or artifact. `Historical` describes source time and does not
imply finality. `Fresh` means both source age and destination submission time fall
within the predicate policy. The [anchor taxonomy](../proof-claims/anchor-trust-models.md)
provides the broader source-linked vocabulary.

A `deployment_domain` identifies one immutable proof-of-concept root set. A
`source_protocol_fingerprint` identifies the consensus, runtime or era, state
encoding, certificate suite, and commitment formats used to interpret source
evidence. A `claim` is the typed semantic statement consumed by an application.
A `proof` shows that the registered relation holds for that claim.

The following invariants apply in both directions:

- Finality, inclusion, and predicate relations use the same source network,
  deployment domain, chain point, anchor digest, state version, protocol
  fingerprint, predicate version, output schema, destination context, and replay
  value.
- The recursive base case binds the complete bootstrap-manifest digest and
  deployment domain. A step binds its exact predecessor and successor
  light-client states.
- Tracked height, slot, certificate epoch, and set id advance monotonically. The
  proof of concept does not consume an older anchor after an advance.
- An accepted local action and its replay update commit together or neither
  commits.
- A caller cannot select a verifier key, circuit architecture, SRS, setup
  transcript, anchor profile, or predicate meaning.
- A valid proof under another checkpoint, sibling chain, protocol fingerprint,
  or deployment domain is invalid here.

Three values with different roles must not be collapsed:

```text
claims_hash
  = the Midnight aggregation stack's ordered Poseidon chain over
    (hash(inner_vk_i), one_field_statement_i) claims

claim_digest
  = HashToField(domain_separator || CanonicalTranscript(proof_bound_claim_fields))
    reconstructed by the destination and used as the explicit BSB22 public scalar

D
  = the BSB22 Pedersen commitment to the wrapper's designated committed wires,
    carried inside the proof
```

The proof suite still has to freeze the domain separator, transcript field order,
hash-to-field mapping, and equality that connects the exact outer instance and
typed output to `claim_digest`. `D` is not a semantic claim hash, and
`claims_hash` is not a replacement for the destination-reconstructed digest.

## 5. Security and trust model

Proof verification is necessary but not sufficient. Each destination relies on
consensus roots, proof roots, and policy roots:

| Destination | Foreign consensus and bootstrap roots | Proof roots | Policy roots |
| --- | --- | --- | --- |
| Cardano | Midnight genesis or checkpoint, current and next BEEFY authority commitments, finality-adapter version | Authorized inner and aggregation VKs, wrapper VK, trusted KZG SRS, Groth16 setup and transcript | Predicate registry, verifier hash, deployment policy, recovery policy |
| Midnight | Cardano identity, Mithril genesis verification key or certificate checkpoint, current and next AVKs and protocol parameters, anchor-profile version | Halo2 operation and aggregation VKs, trusted Midnight KZG SRS | Predicate registry, operation hash, deployment policy, recovery policy |

The trust roots therefore extend beyond source consensus and abstract proof
soundness. They include checkpoint approval, the independent Mithril genesis key,
both setup systems, verifier-key authorization, source-protocol fingerprints,
registry contents, destination code, and recovery policy.

Relayers, RPC servers, indexers, Mithril aggregators, and proof services are data
providers. A dishonest provider can censor, delay, equivocate at the transport
layer, or waste proving resources. It cannot authorize a local transition unless
the provider also breaks a named source threshold, proof soundness, setup
integrity, destination code, or policy root. Availability remains an operational
assumption.

Unknown or downgraded protocol fingerprints, conflicting finality evidence,
unregistered artifacts, stale claims, replayed messages, and mixed anchors fail
closed. Conflicting consensus evidence freezes the affected domain for review.
The verifier never rolls an accepted anchor backward and never consumes replay
state on rejection.

The composed proof target is at least 128 bits of security with explicit finite
recursion and aggregation bounds. The exact argument must account for the
128-bit truncated Fiat-Shamir challenges used by Midnight recursion, KZG and
Groth16 assumptions, all hash-to-field reductions, and every setup ceremony.

## 6. Bootstrap and roots of trust

The proof of concept uses approved checkpoint manifests. This is a
weak-subjectivity choice. Reproducing a checkpoint from independent nodes detects
operator mistakes but does not turn the checkpoint into a consensus-derived root.

### Cardano validator tracking Midnight

The Cardano continuing state contains:

- deployment domain, Midnight network, genesis identity, and chain-spec identity;
- latest accepted finalized block number, block identifier, and BEEFY MMR root;
- current BEEFY set id, authority root, authority count, and equal-weight model;
- announced next set id and authority root;
- latest mandatory-block handoff and approval metadata;
- a Midnight protocol fingerprint covering runtime/spec version, commitment
  encoding, signing domain, ECDSA and Keccak rules, quorum, authority-leaf
  encoding, and MMR format;
- wrapper VK, every authorized inner and aggregation VK, KZG SRS hashes and
  degrees, Groth16 setup transcript, predicate-registry root, verifier hash, and
  recovery-policy hash;
- freshness limits, claim expiry rules, and replay root.

BEEFY light clients require an initial authority commitment
([BEEFY light client](../consensus/beefy-light-client.md)). A set id is a counter,
not a key commitment. Each handoff binds both the id and the authority root and is
authenticated under the outgoing set.

### Midnight operation tracking Cardano

The Midnight continuing state contains:

- Cardano network magic, genesis identity, and ledger era;
- a separately trusted Mithril genesis verification key or an approved certificate
  checkpoint;
- current and previous certificate hashes and certified epochs;
- current and next aggregate verification keys and Mithril protocol parameters;
- certificate suite, signed-message format, previous-certificate rule, and Cardano
  protocol fingerprint;
- SCLS version, namespace-set hash, encoding, tree and hash rules, slot, root, and
  exact signed-entity type;
- operation and aggregation VKs, KZG SRS hashes and degrees, registry root,
  operation hash, and recovery-policy hash;
- certificate and slot freshness limits, claim expiry rules, and replay root.

Cardano genesis does not derive the Mithril genesis verification key. That key is
an independent trust root. Mithril verification must authenticate the full
certificate chain, including previous-certificate linkage, AVK and
protocol-parameter transitions, the signed message, and the terminal genesis
signature.

### Manifest and genesis modes

A checkpoint manifest binds source and destination identities, finalized point,
state or MMR root, finality proof, current and next authority or AVK commitments,
protocol parameters, source fingerprint, proof artifacts, registry, verifier,
recovery policy, deployment domain, derivation inputs, approver keys, threshold,
and signatures. At least two independently administered full nodes reproduce all
derivable fields. The profile also fixes maximum age and source lag, exact
agreement rules, node-independence criteria, and the manifest-signature algorithm.

Genesis mode starts from source genesis plus the initial authority or
certification root and proves every accepted rotation. Conformance must cover one
BEEFY authority transition and one Mithril AVK transition from their base cases.
Emergency checkpoint replacement creates a new deployment domain under the
registered delayed recovery policy; routine governance cannot skip to an
arbitrary checkpoint.

No deployable manifest, accepted bridge VK/SRS inventory, registry root, numeric
freshness profile, or approved domain id exists in this repository yet. These are
deployment inputs, not values to infer from a live endpoint.

## 7. Shared claim protocol

A destination receives a typed query and claim envelope, a proof blob, public
witness data required outside the circuit, and a registry entry or membership
proof. The [shared envelope](../proof-claims/claim-envelope.md) and
[claim interface](../proof-claims/claim-interface-schema.md) supply the
source-backed starting shapes.

The proof-bound envelope includes:

- schema version, source system, network, era or runtime version, protocol
  fingerprint, and deployment domain;
- predicate id and version, statement schema, result schema, and typed output
  hash;
- anchor type and digest, finality rule and parameters, source height or slot,
  and freshness scope;
- proof-suite id, circuit-architecture hash, verifier or operation id, and
  public-input hash;
- destination network, destination application and entry point, action, recipient,
  asset, amount or rights, and context hash;
- expiry, replay scope, lane, message id, and nullifier where applicable.

Every suite publishes a field-binding matrix that labels each field
`proof-bound`, `validator-only`, or `advisory`. Any field that changes acceptance
cannot be advisory. The canonical binary transcript fixes integer bounds, units,
byte order, field order, maximum lengths, inclusive time comparisons, subgroup
rules, hash-to-field reduction, and rejection of aliases, duplicates, unknown
critical fields, and trailing bytes. The exact bridge wire schema remains Sprint 3
work.

Validation order is fixed:

```text
decode
-> canonical schema and version
-> destination context
-> expiry and freshness
-> replay state
-> predicate registry
-> anchor, verifier, key, and setup authorization
-> public-input reconstruction
-> proof verification
-> typed-output decoding
-> destination policy
-> replay consumption
```

The circuit composes three relations by equality. The finality relation produces
the authenticated anchor. The inclusion relation consumes that exact anchor and
produces the state object or namespace root. The predicate relation consumes that
exact object and produces the typed result. Independently valid relations for
different roots do not compose.

## 8. Predicate registry

The registry is part of proof semantics. An accepted entry binds:

- predicate id and version, source namespace, formal statement, and result type;
- accepted anchor profile, finality rule, freshness rule, and source protocol
  fingerprint policy;
- statement and result schema hashes;
- proof-suite id, circuit-architecture hash, proof-bound selector, and parameter
  hash;
- every inner VK, aggregation VK, wrapper or operation VK, proving-key hash, KZG
  SRS manifest, Groth16 setup manifest, and transcript version;
- destination context, expiry, replay, lane, and lifecycle policy;
- deployment domain, audit digest, and provenance digest.

Authorization follows a nested artifact-binding graph:

```text
deployment domain
  -> active predicate-registry root
     -> predicate record and version
        -> anchor profile and finality adapter
        -> statement and result schemas
        -> proof suite
           -> circuit architecture and selector
              -> authorized inner VKs
              -> aggregation VK
              -> wrapper or operation VK
           -> KZG SRS manifest
           -> Groth16 setup and transcript manifest
```

A missing or inconsistent node rejects the claim even if its isolated
cryptographic proof verifies. The proof of concept keeps the entire graph
immutable within a deployment domain. Production lifecycle states may include
active, frozen, and deprecated only after a transition specification fixes
authority, threshold, delay, activation, in-flight proof behavior, and domain
effects.

Registry population is blocked until the catalog gate proves exactly 42 unique
Cardano records and 52 unique Midnight records, no duplicate ids, all required
fields, and a provenance digest for every record. Template reuse reduces circuit
count; it never substitutes one predicate record for another.

## 9. Cardano predicate catalog

The Cardano catalog contract requires 42 source-backed predicate records. The
record source is absent. Searches under `C:\Users\charl`,
`C:\proofcategories`, and `C:\proof-zk-recovery` found no
`verified-claim-catalog-42.md`,
`cardano-prior-epoch-zk-proof-categories.md`, or equivalent source file.
Authenticated GitHub code searches on 2026-07-10 for those filenames and
distinctive phrases returned zero results before the search API rate limit.
This is evidence of the search performed, not proof that the files do not exist.

Each recovered Cardano row must name its id and version, ledger era and namespace,
natural-language and formal statement, public inputs and typed outputs, private
witness, accepted anchor, finality and freshness rule, proof-template family,
suite and architecture, complete VK/SRS graph, selector and parameter hash,
destination context, replay behavior, positive and negative vectors, transaction
use, primary sources, and implementation status.

Known Cardano namespaces, UTxO semantics, governance facts, or examples in the
derived claim-interface report do not identify the missing 42 statements. No row
is listed or inferred here. `S01-BLOCK-01` remains open, and Cardano registry
population, 42-row round trips, and catalog conformance cannot begin until
recovery or source-backed per-row reconstruction passes the mechanical gate.

## 10. Midnight predicate catalog

The Midnight catalog contract requires 52 source-backed predicate records. The
record source is absent. Searches found no
`midnight-proof-claim-catalog-52.md`, and the authenticated GitHub searches on
2026-07-10 returned no exact filename or distinctive phrase match before rate
limiting. The number 52 does not encode predicate semantics.

Each recovered Midnight row has the same registry fields as a Cardano row and
must also identify the public ledger source it can authenticate. Candidate anchor
families include contract state, Zswap commitment and nullifier roots, DUST roots,
public transaction data, and consensus-authorized system effects
([Midnight transaction types](../midnight/transaction-types.md)). A family name is
not a predicate record, and private client state is not a public anchor.

No Midnight row is invented to reach the expected count. `S01-BLOCK-01` blocks
the 52-row registry, cross-predicate substitution vectors, and the claim that
every predicate is covered. Once recovered, every record must pass count,
uniqueness, schema, source-digest, registry round-trip, positive-vector, and
required negative-vector checks. The set exercised on live testnets is recorded
separately from full catalog conformance.

## 11. Cardano state anchoring

The selected proof-of-concept anchor is a Mithril-certified Standard Canonical
Ledger State artifact. It is a hard gate, not a deployed public-testnet fact.

Mithril certificates form a chain rooted in a separately trusted genesis
verification key. Validation is not one aggregate pairing check. A verifier must
check certificate hashing and previous-certificate linkage, authenticate the
aggregate verification key and protocol-parameter transitions, verify the signed
message under the certificate suite, enforce epoch and era rules, and terminate
at the trusted genesis key
([Mithril certificates](../cardano/mithril-bls-certificates.md), `src-0042`).
The aggregator transports and combines signatures; it is not itself trusted.

[CIP-0165](../standards/cip-0165.md) is Proposed. It specifies a deterministic
SCLS artifact with a `slot_no`, namespace roots, a global `root_hash`, canonical
CBOR, and a two-level Blake2b-224 Merkle construction. It does not define this
bridge's membership and nonmembership wire proofs. The bridge must freeze tree
shape, namespace completeness, padding, leaf and internal-node encoding,
ordered-neighbor nonmembership, path direction bits, bounds, and boundary
vectors.

Mithril does not currently expose a confirmed public SCLS signed-entity profile.
A 2026-07-10 query of the official `pre-release-preview` aggregator returned 20
certificates: 18 `CardanoTransactions` and 2 `CardanoDatabase`, with no SCLS
entity. That sample supports the open gate but does not prove that every
aggregator profile lacks an extension. A project-operated SCLS signer population
uses a distinct lab anchor profile and caps the program outcome at
`degraded-lab`.

[Ouroboros Peras](../cardano/ouroboros-peras-finality.md) is also Proposed. Its
vote certificate and Praos fallback remain a production research path, not the
selected anchor and not a current Cardano finality primitive. The proof of concept
must not describe either Peras or Mithril-certified SCLS as active Cardano
consensus.

`S01-BLOCK-02` closes only when an accepted public Mithril signer population
certifies the exact registered SCLS entity and a complete positive and negative
certificate-chain verification is reproducible.

## 12. Cardano to Midnight proof path

This path uses the registered Midnight Halo2/Plonkish stack over BLS12-381. The
proof relation contains:

1. A Mithril base or step relation that verifies the complete certificate chain
   from the bound checkpoint or genesis key, authenticates AVK and
   protocol-parameter transitions, and outputs the exact certified SCLS message.
2. An SCLS relation that verifies the registered artifact and membership or
   nonmembership path under the certified slot and root.
3. A predicate relation that consumes the resulting Cardano ledger object and
   produces the registered typed output.
4. An aggregation relation that binds all three results to the same claim,
   protocol fingerprint, deployment domain, destination context, and replay
   value.

The recursive base case binds the checkpoint manifest and tracked Cardano state.
Each step consumes the exact previous certificate hash, AVK, protocol parameters,
era, SCLS slot, and root and produces the next state. A certificate from a sibling
aggregator chain, another signed-entity type, or another bootstrap root cannot be
spliced into the sequence.

The experimental Mithril Halo2 code exposes native public inputs
`(MerkleRoot, SignedMessageWithoutPrefix)`. Midnight multi-circuit aggregation
expects one field element per inner statement and computes the ordered
`claims_hash`. No canonical adapter currently connects those Mithril inputs, the
typed claim envelope, and the one-field aggregation statement. The suite must
define and test that adapter rather than hash fields independently by convention.

Midnight contracts resolve an operation VK from contract state rather than
accepting a caller-selected VK. Library availability does not establish that a
deployed operation can accept this external proof, reconstruct the registered
statement, and update tracked Cardano state, destination action, and replay state
atomically. That execution-surface requirement is `S01-BLOCK-05`.

The current CMST interface can inform source-range and completeness semantics, but
its trusted producer range cannot serve as the proof relation. `S01-BLOCK-02` and
`S01-BLOCK-05` keep this direction from a public `live-pass`. Gate failure does
not silently replace Halo2/Plonk with a different proof path.

## 13. Midnight state anchoring

Midnight uses AURA for block production and GRANDPA for finality
([Midnight consensus](../consensus/midnight-consensus-aura-grandpa.md)). The
current bridge-oriented commitment is BEEFY over GRANDPA-finalized blocks.
Vendored runtime evidence shows ECDSA BEEFY signatures and Keccak MMR and
authority commitments (`src-0039`, `src-0040`). No local primary source supports
a future BABE pivot. Any later finality change requires a new adapter, suite,
fingerprint, registry binding, and deployment domain.

A BEEFY commitment signs the MMR-root payload, block number, and validator-set
id. The Cardano-side tracked state binds the current and next authority roots and
the equal-weight proof-of-concept quorum. Authority leaves are
`public_key || stake_le`, hashed into a Keccak multiproof. Published initial
BEEFY/session authority counts are 6 on govnet, 7 on devnet, and 10 on mainnet
([validator-set sizing](../consensus/midnight-validator-set-sizing.md)). Those
genesis counts are benchmark inputs, not static runtime limits; live mandatory
block transitions must be verified.

The current serialized `RelayChainProof` carries a signed commitment and an
`AuthoritiesProof`. Although the runtime payload contains current and next
authority and stake data, the Cardano serialization includes only
`MMR_ROOT_ID` from the signed payload. The relay uses the other payloads to build
the authority proof. Its MMR proof helper is unused, and no event or MMR-leaf
proof is serialized.

An accepted claim therefore needs a specified path:

```text
public Midnight fact or event
-> canonical event position and containing ledger object
-> block header or state commitment
-> registered MMR leaf with the exact parent-block rule
-> MMR membership proof
-> BEEFY-signed MMR root and finalized block
```

The exact MMR leaf/header fields, event binding, parent-block rule, and positive
and negative vectors are not present. A relay object or event payload without
this chain is insufficient. `S01-BLOCK-03` remains open, and the relay is an
encoder and input format rather than a complete settlement path.

## 14. Midnight to Cardano proof path

This path uses the registered full-decider BSB22 commitment-Groth16 suite over
BLS12-381. Midnight finality, authenticated event inclusion, and predicate
proofs are processed in the Midnight Halo2/KZG stack. The outer BSB22 circuit
then proves the complete decision relation that Cardano cannot infer from a
prepared accumulator.

The wrapper enforces:

1. canonical representation of its own outer IVC verification key;
2. the complete and exact outer public instance;
3. ordered Poseidon recomputation of `claims_hash`;
4. authorization of every inner VK used by the claim sequence;
5. the final inner-accumulator pairing;
6. the outer PLONK preparation relation;
7. transcript exhaustion with no unread challenge or proof bytes;
8. accumulation with the outer instance accumulator;
9. the final KZG pairing decision.

The Plutus validator reconstructs `claim_digest` from the registered canonical
typed claim and supplies it as the one explicit BSB22 public scalar. The wrapper
constrains that scalar to the exact outer instance and typed result. The
aggregation `claims_hash` is an internal ordered binding that must be connected
to that instance. BSB22 `D` commits designated circuit wires and enters the
verifier equation, but it cannot replace the public-input equality. Holding the
proof and `D` fixed while mutating any proof-bound claim field must fail.

Cardano Plutus exposes `verifyEd25519Signature` (`src-0045`). The objection to
native GRANDPA signature verification is linear cost and proof size across the
authority set, not absence of an Ed25519 builtin. The current BEEFY relay uses
ECDSA rather than GRANDPA Ed25519, and Cardano also has an ECDSA secp256k1
builtin. Native signature verification remains a separately measured production
alternative; the selected proof of concept lands one BSB22 proof.

No full Halo2/KZG-to-BSB22 decider wrapper exists locally. No public Cardano
BEEFY validator supplies the missing finality and event boundary. The wrapper
gate must reject a forged accumulator and report constraint count, maximum KZG
degree, proving memory and latency, and Cardano verification cost.
`S01-BLOCK-03`, `S01-BLOCK-04`, and `S01-BLOCK-06` keep this direction open.
Failure blocks this path without relabeling vanilla Groth16, native ECDSA, or
direct Halo2 verification as the same suite.

## 15. Proof systems and setup

Midnight proves with Plonk and KZG over BLS12-381, with JubJub used as an
embedded curve
([proving system](../midnight/proving-system-curves.md)). Recursion uses
in-circuit KZG verification, 128-bit truncated challenges, aPLONK-style
committed instances, and the aggregation toolkit
([recursion](../midnight/midnight-proofs-recursion.md)). It does not use a curve
cycle.

The KZG SRS is universal and updatable, but it is still trusted setup. Its
contributors, transcript, maximum degree, accepted prefix, download source, and
content hash belong in the registry. On 2026-07-10, two files obtained from the
official Midnight trusted-setup catalog were verified:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `midnight-srs-2p17` | 25,166,212 | `4a9ef6c7c0619aab74eede44b13e753e3ba54508a02dd3b7106a949aabb73b74` |
| `midnight-srs-2p19` | 100,663,684 | `8e8dc15c4362f05c912f1e770559a3945db3e58a374def416ed5d3e65ad5b10e` |

These hashes authenticate the files used by the local probe. They are not yet an
approved bridge SRS manifest.

BSB22 commitment-Groth16 requires a separate two-phase setup: reusable Powers of
Tau followed by circuit-specific phase 2. Its soundness depends on at least one
honest contributor in each phase deleting the toxic waste, public transcript
verification, and byte equality between the ceremony output VK and the deployed
VK
([Groth16 ceremony](../proof-systems/groth16-trusted-setup-ceremony.md)).
Every circuit architecture change requires a new phase 2 and a new suite or
domain according to policy.

The KZG and Groth16 inventories remain independent even though both use
BLS12-381. A bridge artifact manifest records:

- suite, curve, transcript, challenge, subgroup, and point-encoding rules;
- circuit source and architecture hashes, K or constraint domain, and selectors;
- all inner, aggregation, wrapper, and destination VK hashes;
- proving-key hashes without committing large or secret material to git;
- KZG SRS catalog entry, degree, prefix, contributions, and transcript;
- Groth16 phase 1 and phase 2 transcripts, contribution receipts, beacon, and
  independent verification;
- build toolchain and reproducibility evidence.

A single-operator setup using the MPC framework has landed a BSB22 proof on
Cardano Preview, but the deployed key has no multi-party 1-of-N protection. That
is deployment feasibility evidence only, not an accepted bridge setup.

## 16. Reference harness

The reference harness exposes versioned `query`, `prove`, `verify`, `submit`, and
`inspect` flows for both directions. Its records cover the query, claim envelope,
proof response, typed result, artifact references, submission receipt, and
verification diagnostics. CDDL defines canonical binary records; JSON Schema is
diagnostic and does not define the hashable form.

Offline-fixture and live-node adapters must emit byte-identical canonical
statement inputs and field elements for equivalent authenticated source data.
Fixture anchors use a named fixture or lab profile and can never be reported as
public source consensus. Adapters, provers, and relayers are untrusted; the
destination verifier remains the acceptance boundary.

The planned implementation layout uses Rust for common APIs, source adapters, and
Midnight/Halo2 circuits; Go and gnark for the BSB22 wrapper; Plinth compiled to
UPLC for Cardano; and Compact with TypeScript bindings for the Midnight operation.
A language may change only through a decision record that preserves canonical
bytes, suite ids, and verification semantics.

One persisted job state machine covers query receipt, source finality, witness
collection, proving, local verification, destination submission, and destination
confirmation. Each failure code is permanent, retryable, or manual-recovery and
specifies retry, backoff, idempotency, dead-letter behavior, and replay effect. A
correlation id links the query, anchor, proof job, registry version, relayer
attempt, destination transaction, and consumed-message result.

Proof fixtures pin statements, witnesses, artifact hashes, clocks, and test RNG
seeds. Production proving uses a CSPRNG. Conformance compares accepted canonical
statements and results unless a suite explicitly guarantees byte-stable proofs.

## 17. Trustless transaction protocol

A bridge message id is a deterministic hash over both source and destination
meaning. Source fields include network, deployment domain, height or slot,
transaction id, output or action index, event discriminator, source handler, and
payload hash. Destination fields include network, bridge contract, handler,
recipient, canonical asset id, amount or rights, action, nonce, lane, replay
scope, and context hash
([bridge claim requirements](../proof-claims/bridge-claim-requirements.md)).

A ZK nullifier and a consumed-message record are different replay controls. A
private source relation may expose a nullifier. The destination separately records
that a cross-domain message id was consumed under its domain, contract, source,
and lane. A transaction may require both.

Cardano assets use the canonical tuple `(cardano, network_id, policy_id,
raw_asset_name)`, with ADA represented by an explicit tag. Midnight assets bind
their registered ledger token type and source. DUST is a local fee capability and
is not a normal bridgeable asset. Display names never define identity. The
message binds amount and action so lock, burn, mint, release, shield, and unshield
cannot be substituted.

Two atomic destination transitions are supported:

- `advance-and-consume` checks the exact predecessor light-client state, verifies
  and advances to a successor anchor, applies one destination action, and consumes
  the replay key.
- `consume-current-anchor` leaves the tracked anchor unchanged, applies the action
  under the current anchor, and consumes a distinct message id or nullifier.

Two submissions built on one predecessor race for the continuing state. The loser
refreshes and uses the current anchor or rebuilds against the successor. A rejected
or interrupted attempt changes no tracked, application, or replay state. The
protocol fixes lane ordering, idempotency, retry and refund rules, stuck-message
handling, fee treatment, and per-asset conservation. Conflicting finality evidence
halts the affected domain rather than selecting a winner at the relayer layer.

## 18. Destination validators

### Cardano validator

The Plutus V3 validator stores the accepted Midnight bootstrap digest, protocol
fingerprint, current and next BEEFY state, registry root, proof suite, verifier
hash, and replay state in its continuing output. It:

1. strictly decodes bounded claim, proof, and state records;
2. performs context, freshness, replay, and registry checks;
3. reconstructs `claim_digest` from datum, transaction outputs, and registered
   claim fields rather than accepting a prover-supplied scalar;
4. resolves the exact 672-byte BSB22 VK and artifact graph;
5. rejects invalid lengths, aliases, identity points, off-curve or
   non-subgroup points, trailing bytes, and wrong endianness;
6. verifies the BSB22 commitment PoK and final Groth16 pairing;
7. enforces the exact predecessor and monotonic successor state;
8. applies value conservation, destination action, and replay consumption
   atomically.

The verifier-key binding and public-input reconstruction follow the proven
Cardano pattern in the
[ZK recovery architecture](zk-recovery-architecture.md). The live recovery
validators show that BSB22 verification can fit on Preview; they do not implement
the bridge relation.

### Midnight operation

The Midnight operation stores the Cardano bootstrap digest, certificate state,
SCLS anchor, protocol fingerprint, registry root, accepted KZG/VK graph, and
replay state. It selects the operation VK from contract state, reconstructs the
registered public statement, verifies the complete Halo2/Plonk relation, decodes
the typed result, and commits the Cardano-state advance, application action, and
replay update together. A malformed external proof, unknown operation, stale
certificate, mixed SCLS root, or failed action commits nothing.

The available Compact, ZKIR, and proof libraries do not prove this execution
surface exists on a public Midnight network. The deployed-operation prototype
required by `S01-BLOCK-05` must demonstrate valid and mutated submissions and
all-or-nothing state.

## 19. Relaying and data availability

Relayers have no authorization key. They obtain source data, maintain proof jobs,
transport envelopes and witnesses, submit destination transactions, and report
confirmation. Multiple relayers may submit the same claim; replay state makes
settlement idempotent. A relayer can delay service or withhold data, so liveness
requires redundant data sources, bounded queues, restart-safe persistence, and a
clear replacement policy.

The Cardano-to-Midnight witness may need the full Mithril certificate chain,
genesis or checkpoint material, AVKs, protocol parameters, signed entity, SCLS
artifact, and bridge-owned inclusion proof. The Midnight-to-Cardano witness needs
the BEEFY signed commitment, authority multiproof, current and next set data,
registered MMR leaf and path, containing header or state commitment, event
position, predicate witness, recursive proof, and BSB22 wrapper proof.

Mithril aggregators and Midnight indexers are discovery and delivery services.
Their output becomes authoritative only through the registered certificate,
finality, and inclusion relations. The current Midnight relay omits the event/MMR
path and therefore cannot be submitted as a complete claim.

Checkpoint derivation uses at least two independently administered full nodes.
Routine source witnesses should also be cross-checked for availability and
operator fault, but agreement between endpoints is not a new trust root. Proof
fixtures and deployment evidence retain content hashes, public receipts, redacted
configuration, and reproduction commands. Raw logs, credentials, secrets, SRS
files, proving keys, and large artifacts remain outside git under a named
retention policy.

Health and readiness separate unavailable RPC, certificate, proof, and
destination services from unsafe verifier state. Metrics include source lag,
certificate and anchor age, queue depth, proving latency and memory, retries,
destination confirmation, registry mismatch, replay conflicts, and conservation
failures.

## 20. Governance and upgrades

Within a proof-of-concept deployment domain, these roots are immutable:

- checkpoint digest and source/destination identities;
- finality adapter, anchor profile, and source-protocol fingerprint policy;
- proof-suite and artifact-binding graph;
- all VK and SRS manifests and setup transcript hashes;
- predicate-registry root and destination verifier or operation hash;
- replay-domain definition and recovery-policy hash.

Replacing any root, resetting a testnet, or changing an incompatible source
fingerprint creates a new deployment domain. Old-domain proofs must fail under
the new verifier. The migration record states asset handling, in-flight proof
disposition, replay-state isolation, old-domain shutdown, and public notice.

An unknown, downgraded, or mismatched fingerprint or conflicting finality evidence
freezes the affected domain. Governance cannot roll back an accepted anchor,
ignore an unregistered artifact, or consume replay state while frozen. Emergency
checkpoint replacement follows a separate delayed recovery policy with named
credentials, threshold, activation time, and domain change.

Production may permit in-place transitions only through a specified consensus
state machine that fixes proposal authority, threshold, delay, activation and
deactivation, simultaneous key windows, in-flight proofs, freeze, rollback
prohibition, and domain effects. ZKIR, Midnight runtime, Cardano era, Mithril
suite, SCLS format, BEEFY encoding, or finality changes each require a compatible
registered fingerprint and proof adapter. No BABE migration is assumed.

## 21. Economics and performance

Measured Cardano costs show that Plutus V3 BLS12-381 builtins make Groth16
verification feasible, while circuit and application details still determine the
real transaction budget
([cost analysis](../cardano/groth16-onchain-cost.md)).

| Measurement | ExCPU | ExMem or note |
| --- | ---: | --- |
| Pure Plutus V2 full Groth16 | 1,334,647,992,336 | 1,663,887,424; infeasible for L1 |
| Plutus V3 vanilla Groth16 | 1.36 to 1.61 billion | Verifier-only range |
| Plutus V3 single-claim BSB22 estimate | 2.4 to 2.8 billion | Verifier-only range |
| 2026-06-29 Preview custody claim | 5,504,101,369 | 9,206,533; application plus proof |
| 2026-07 single-operator-VK Preview claim | 3,914,957,868 | 2,826,629 off-chain CEK measurement |

The last deployment declared 6,000,000,000 ExCPU and 4,000,000 ExMem, locked in
transaction `af00155008b74408c34f81722f3f7cbc935a8c0474d93f2ad2de89e362f93e2e`,
and claimed in
`92738a5d5b7603f056c822bd15b309c29c967dc91ef3325137d236966910f896`.
It proves the BSB22 landing pattern under a single-operator setup. It does not
prove the bridge wrapper, event relation, artifact graph, or multi-party setup.

A BSB22 proof is 336 bytes and its committed VK is 672 bytes. The verifier has
one explicit scalar public input. A CPU-only batch model suggests about eight
commitment claims per transaction, but the 16.5 million memory-unit and
16,384-byte transaction-size limits may bind first. Production measurements
must include all context, registry, replay, state, and value-conservation work and
declare ex-units per script input with margin.

On 2026-07-10 the native Midnight IVC example passed with
`truncated-challenges,fewer-point-sets,single-h-commitment`. Setup took 10.14
seconds; three 1,000-Poseidon steps proved in 12.20, 12.34, and 12.56 seconds and
verified in 15.04, 16.11, and 17.81 milliseconds. A run with only
`truncated-challenges` failed during VK synthesis. This is a local toolchain and
SRS probe, not a benchmark of either bridge relation or the missing full decider.

Every bridge benchmark names hardware, software commits, SRS and VK hashes,
authority count, circuit size, warm or cold method, sample count, percentiles,
target network parameters, proof size, proving RAM and latency, verification
cost, fees, and pass or fallback threshold.

## 22. Conformance and security testing

Conformance uses independent encoders and public-statement reconstructors. They
must produce identical canonical bytes and field elements, then agree on positive
and negative outcomes. Each of the 94 recovered predicates requires a schema
check, provenance digest, registry round trip, positive vector, and all negative
vectors required by its template. Full catalog conformance is distinct from the
smaller live-testnet exercise set.

Required mutation classes include:

- wrong bootstrap manifest, checkpoint, genesis key, network, or deployment
  domain;
- unknown, downgraded, or mismatched source protocol fingerprint;
- skipped, reordered, sibling-chain, or forged BEEFY and Mithril transitions;
- wrong current or next authority root, AVK, protocol parameters, quorum, or
  signed-entity type;
- wrong MMR leaf, parent rule, event position, header, SCLS namespace, tree path,
  padding, boundary neighbor, or anchor root;
- wrong self-VK, unauthorized inner VK, architecture, selector, wrapper VK, KZG
  SRS, or Groth16 transcript;
- changed claim order or `claims_hash`, invalid inner or outer accumulator,
  nonempty transcript remainder, or failed final KZG pairing;
- fixed-proof mutation of every proof-bound claim field and `claim_digest`;
- `D`, PoK, commitment challenge, pairing element, and proof-byte mutation;
- little-endian versus big-endian and hash-to-field confusion;
- wrong lengths, noncanonical encodings, aliases, unknown critical fields,
  trailing bytes, identity points, and subgroup failures;
- stale anchors, boundary-time errors, replay, lane reordering, duplicate
  submission, destination-context substitution, and cross-domain replay;
- interrupted submission, process restart, RPC loss, prover timeout, rotation
  race, destination rollback, testnet reset, and conservation failure.

The full-decider test holds other inputs well formed and supplies a forged or
invalid accumulator; rejection must occur at the final decision relation. Atomic
tests inspect predecessor, successor, application, and replay state after each
failure and require no change.

Source claims used by security decisions retain verbatim evidence and source
digests. Strict OpenSpec validation, source-pack gates, whitespace checks,
reference scans, clean builds, and reproducible deployment commands are part of
the evidence record. Passing document validation does not close a cryptographic
or public-network gate.

## 23. Testnet deployment

A deployment manifest selects one Cardano and one Midnight network and binds all
endpoints, identities, genesis values, checkpoint approvals, artifacts, funded
roles, secret references, freshness limits, and evidence locations. Preview and
Preprod endpoints are available for both systems; a network name alone is not a
manifest.

### Official environment snapshot

The official Midnight support matrix retrieved on 2026-07-10 lists:

| Component | Supported version |
| --- | --- |
| Preview and Preprod node | 1.0.0 |
| Compact devtools | 0.5.1 |
| Compact compiler | 0.31.1 |
| Compact runtime | 0.16.0 |
| Compact JS | 2.5.1 |
| Platform JS | 2.2.4 |
| On-chain runtime | 3.0.0 |
| Wallet SDK | 1.2.0 |
| Midnight.js and testkit-js | 4.1.1 |
| Indexer | 4.3.3 |
| Proof server | 8.1.0 |

Official network endpoints are:

| Network | RPC | Indexer |
| --- | --- | --- |
| Midnight Preview | `https://rpc.preview.midnight.network` | `https://indexer.preview.midnight.network/api/v4/graphql` |
| Midnight Preprod | `https://rpc.preprod.midnight.network` | `https://indexer.preprod.midnight.network/api/v4/graphql` |

Midnight's official installation guide supports native development on Linux and
macOS. Windows requires WSL, and the proof server requires Docker. The official
Cardano testnet guide assigns magic 2 to Preview and magic 1 to Preprod. The
current documented `cardano-node` release on 2026-07-10 is 11.0.1, released
2026-05-05, with an official Windows AMD64 asset. Sources:
[Midnight installation](https://docs.midnight.network/getting-started/installation),
[Midnight support matrix](https://docs.midnight.network/relnotes/support-matrix),
[Midnight networks](https://docs.midnight.network/relnotes/network),
[Cardano testnets](https://docs.cardano.org/cardano-testnets/getting-started), and
[Cardano releases](https://docs.cardano.org/developer-resources/release-notes/release-notes).

### Dated local probes

The 2026-07-10 host has Rust 1.90.0, Go 1.25.7, and verified
`cardano-node` 11.0.1 and `cardano-cli` binaries. The gnark 0.15.0 BSB22 harness
passed its Go tests. `midnight-aggregation` compiled, and its IVC example passed
with the exact features and SRS hashes recorded in sections 15 and 21. Docker is
absent. WSL reports Ubuntu 26.04 but the required Windows optional component is
disabled, so Compact and the proof server cannot run on this host without an
environment change.

A single unsigned Preview RPC observation returned chain identity
`Midnight Preview`, genesis hash
`0x801d3fc306115a3b538ea9498881c176376f8e3213464fe620fc1f359d13b880`,
runtime `midnight` spec version 1000000, transaction version 3, and finalized
block 1,541,269 with head
`0xab8df223d93aab56256c985fee7df80b465e3774595084932d27487fdd17738f`
and state root
`0xa241bd9de9ee559b790c8f0963d7a87c91a827ca1cac3ae0994c0d6e85e2e8dc`.
The endpoint reported 12 peers and was not syncing. These are candidate manifest
inputs from one endpoint. They are not an approved checkpoint, do not establish
independent-node agreement, and cannot authorize a deployment.

Testnet execution records registry and verifier deployment transactions, manifest
digests, artifact hashes, source checkpoints, one claim-authorized transaction in
each direction, costs, restart and duplicate-submission drills, and reset
rejection. The outcome is exactly one of:

- `live-pass` when both selected public networks accept claim-authorized
  transactions under their named public consensus, proof, setup, and policy
  profiles;
- `degraded-lab` when both directions execute but at least one uses a fixture,
  project certifier, mock transition, or other lab root;
- `blocked` when a proof relation, authenticated path, execution surface, catalog
  gate, or public-network dependency cannot be completed.

No current probe is evidence of `live-pass`.

## 24. Production path and residual risks

Six dependencies define the present implementation boundary:

| Gate | Missing evidence | Effect |
| --- | --- | --- |
| `S01-BLOCK-01` | Source-backed 42 Cardano and 52 Midnight catalogs with exact count, uniqueness, schema, and provenance | Blocks registry population and 94-row conformance |
| `S01-BLOCK-02` | Accepted public Mithril signer population certifying the exact SCLS entity | Blocks public Cardano anchor; lab profile caps result at `degraded-lab` |
| `S01-BLOCK-03` | Authenticated Midnight event-to-header-to-MMR relation and rejecting prototype | Blocks Midnight fact inclusion |
| `S01-BLOCK-04` | Measured full Halo2/KZG decider inside BSB22 with invalid-accumulator rejection | Blocks selected Midnight-to-Cardano proof path |
| `S01-BLOCK-05` | Deployed Midnight operation accepting an external registered proof and updating state atomically | Blocks selected Cardano-to-Midnight execution surface |
| `S01-BLOCK-06` | Reference Plutus boundary for the complete wrapped BEEFY/MMR claim | Blocks Cardano settlement |

Production also requires independent audits of circuits, encoders, validators,
state machines, and operations; a public multi-party Groth16 ceremony and
deployment VK equality check; an accepted KZG SRS manifest and contribution
review; genesis-mode evidence for authority and AVK rotation; stable source wire
formats; numeric freshness and resource limits; incident and recovery drills;
asset conservation review; and governance that cannot replace roots silently.

Alternative landings remain valid research topics. Direct Halo2/KZG verification
on Cardano may reduce Groth16 ceremony exposure. Native BEEFY-ECDSA may be useful
for a bounded authority set. A later BLS finality adapter may reduce signature
cost. Each changes performance, setup, statement, or trust semantics and therefore
needs target-network measurements, a versioned decision record, a new suite and
registry binding, and any required deployment-domain migration.

The repository has no deployment outcome. The unresolved gates prevent a
`live-pass` claim. A blocked result must retain its reproducer, owner, affected
interface, and resume evidence; relabeling a missing relation or public dependency
does not close it.

## 25. Appendices

### A. BSB22 Cardano ABI

The registered ABI uses one explicit public scalar `pub`, a 336-byte proof, and a
672-byte committed VK
([commitment Groth16](../proof-systems/commitment-groth16.md)):

```text
proof = A:G1_compressed[48]
     || B:G2_compressed[96]
     || C:G1_compressed[48]
     || D:G1_uncompressed[96]
     || PoK:G1_compressed[48]

pub = little-endian bytes reduced modulo BLS12-381 Fr

eCmt = OS2IP_BE(
  expand_message_xmd(SHA-256, D_uncompressed, "bsb22-commitment", 48)
) mod Fr

vkX = IC0 + pub * IC1 + eCmt * K2 + D
```

Both checks are mandatory:

```text
e(D, CK.GSigmaNeg) * e(PoK, CK.G) == 1
e(A, B) == e(alpha, beta) * e(vkX, gamma) * e(C, delta)
```

The verifier recomputes `eCmt` from the exact 96 uncompressed `D` bytes. It
rejects a caller-supplied challenge, compressed `D`, identity points,
noncanonical points, off-curve or non-subgroup points, wrong lengths, and trailing
bytes.

### B. Current Midnight relay object

The current Cardano-facing shape uses tag-121 PlutusData:

```text
RelayChainProof {
  signed_commitment: {
    commitment: {
      payloads: [ MMR_ROOT_ID ],
      block_number,
      validator_set_id
    },
    votes: [
      { ecdsa_signature, authority_index, public_key }
    ]
  },
  proof: AuthoritiesProof {
    root,
    total_leaves,
    proof
  }
}
```

The authority proof uses Keccak leaves over `public_key || stake_le`. The object
does not carry the event-to-header-to-MMR proof required by section 13.

### C. Midnight transaction parsing boundary

Midnight transaction parsing has two layers
([transaction format](../midnight/transaction-format.md)):

1. A `midnight:<tag>:` container with versioned tags and a SCALE-style body.
2. Field-Aligned Binary for embedded ledger values and their proof-field form.

A bridge parser pins every accepted tag and version, compact integer rule, map
ordering rule, FAB alignment, length bound, and field packing rule. ZKIR v3 and
the ledger-9 transaction documentation remain version-sensitive and must be
re-pinned against released code.

### D. Foundation traceability

Stable requirement ids and `traceability/requirements.jsonl` are planned program
artifacts and are not present yet. The current foundation is traceable through
named OpenSpec requirements and work-package ids:

| Design sections | OpenSpec capability or work package |
| --- | --- |
| 2 to 5 | `bridge-system`: Bidirectional typed claims |
| 6 | `bootstrap-trust`: Deployment-bound checkpoint |
| 7 | `claim-protocol`: Canonical claim digest |
| 8 to 10 | `predicate-registry`: Authorized proof semantics; `S01-T03-W01` |
| 11 | `cardano-anchor`: Named Cardano trust profile; `S01-BLOCK-02` |
| 12 | `halo2-proof-path`: Cardano proof on Midnight; `S01-BLOCK-05` |
| 13 | `midnight-anchor`: Authenticated Midnight event path; `S01-BLOCK-03` |
| 14 and 15 | `groth16-proof-path`: Full-decider BSB22 landing; `S01-BLOCK-04`, `S01-BLOCK-06` |
| 16 and 19 | `reference-harness`: Symmetric query and proof flow |
| 17 and 18 | `settlement-protocol`: Concurrent claim consumption |
| 20 | `operations-governance`: Immutable PoC roots |
| 21 to 24 | `conformance-testnet`: Honest outcome labels |
| 1 to 25 | `S01-T03-W01` through `S01-T03-W07` |

### E. Provenance

The [source register](../sources/index.md) preserves `src-0001` through
`src-0049`. Cardano pairing and MSM support comes from `src-0001` through
`src-0004`; measured BSB22 and Preview evidence from `src-0011` through
`src-0015`; GRANDPA and BEEFY structure from `src-0017` through `src-0021`;
Midnight proving, consensus, and circuit sources from `src-0023` and
`src-0026` through `src-0029`; CMST, ZKIR, and transaction formats from
`src-0030` through `src-0033`; typed claims from `src-0035` through
`src-0038`; and the vendored relay, runtime, Mithril, aggregation, ledger,
Plutus builtin, and validator-selection evidence from `src-0039` through
`src-0046`.

The gated source sweep is `src-0048`, and the published initial Midnight
authority counts are `src-0049`. The 2026-07-10 network, catalog-search, host,
SRS, and proof probes are dated deployment and feasibility evidence. They do not
create a trust root or close any gate without the manifest, proof, and
conformance evidence named above.
