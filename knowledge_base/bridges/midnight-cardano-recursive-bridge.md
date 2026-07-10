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
foundation blockers in section 24 remain open. The Deep Research Toolkit dossier
and independent proof-systems, consensus, and implementer/operator evidence are
recorded in the OpenSpec review artifact. Acceptance requires zero blocking and
zero unresolved major review questions. Git history and the review artifact carry
the process record; the body below describes only the current system and evidence.

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
  architectures, verifier keys, setup material, and schemas, with separate
  domain-bound activation and authorization records;
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
2. A query carries the requested predicate, bounded typed inputs, destination
   context, and optional constraints only. It does not select an anchor, proof
   suite, VK, SRS, setup, architecture, operation, artifact, replay mode, or
   lifecycle state.
3. A proof generator resolves the registered proof suite and proves finality,
   inclusion, and predicate semantics.
4. A relayer transports the claim envelope, proof, public witness, and registry
   evidence.
5. A destination verifier reconstructs the public statement and verifies policy
   and proof authorization.
6. A destination application consumes the typed result and updates replay state in
   the same atomic transition.

Before source collection, the active destination registry resolves the query
against the root-set digest, deployment domain, registry activation,
destination identity, and current policy state. The canonical resolution record fixes the predicate version,
anchor profile, source fingerprint policy, statement and result schemas, proof
suite, artifact graph, destination verifier or operation, replay mode, and
lifecycle status. Optional query constraints must equal the resolved values or
fail permanently. Source adapters, provers, relayers, and transaction builders
consume the same resolution-record digest.

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

A `deployment_domain` is the reproducible digest of one immutable
proof-of-concept root set and a fresh deployment instance id. A
`source_protocol_fingerprint` is the reproducible digest of the rules used to
interpret source evidence, not a relayer label. A `claim` is the typed semantic
statement consumed by an application. A `proof` shows that the registered
relation holds for that claim.

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

### Proof-bound derivation and equality ownership

Every proof suite publishes one versioned, content-addressed suite profile `P`.
Its statement derivation is acyclic and has this common dependency shape:

```text
proof_bound_fields
  -> canonical_claim_bytes := ClaimEncode_P(proof_bound_fields)
  -> claim_digest := ClaimHashToField_P(canonical_claim_bytes)

relation_public_io[role_i]
  -> one_field_statement[role_i] :=
       InnerStatementEncode_P(role_i, relation_public_io[role_i])

(role_i, authorized_vk_digest[role_i], one_field_statement[role_i])
  for every required role
  -> claims_hash := AggregateClaims_P(required_role_sequence, statements,
                                      authorized_vk_digests)

(root_context, terminal role outputs, claims_hash, typed_result_binding,
 destination_context, expiry, replay value)
  -> outer_public_instance := OuterInstanceEncode_P(...)

(canonical_claim_bytes, outer_public_instance, canonical_typed_result)
  -> explicit public or committed equality constraints
```

`claim_digest` is derived, never supplied by the prover. `claims_hash` does not
enter `ClaimEncode_P` unless the profile includes a mechanically checked acyclic
dependency proof. `D` does not enter `ClaimEncode_P` and cannot define claim
semantics. The common envelope has no generic public-input digest. A suite may
introduce a `native_instance_digest` only when its exact producer and preimage
are in the profile and the preimage excludes `claim_digest`, `pub`, and every
value derived from either.

The destination decodes and canonically re-encodes the registered typed result
before digest reconstruction or proof verification. The object bound by the
predicate relation, outer instance, claim digest, policy, and destination action
is that same canonical object. Hashing opaque output bytes and interpreting them
after proof verification is not permitted.

The profile names every relation public input, private witness, output, concrete
wire or instance location, type, bound, encoding, hash or transcript function,
and equality constraint. The minimum equality owners are:

| Boundary | Producer | Consumer | Equality owner |
| --- | --- | --- | --- |
| Root context | Bootstrap or base relation | Every step, terminal role, and final claim | Base and step constraints |
| Resolved proof context | Active registry resolution | Claim, role adapters, aggregation, proof instance, policy, and action | Destination resolution plus suite and wrapper constraints |
| Finalized anchor | Finality role | Inclusion role | Aggregation or composition constraints |
| Included object commitment | Inclusion role | Predicate role | Aggregation or composition constraints |
| Typed result | Predicate role | Claim digest, policy, and action | Wrapper or operation relation plus destination reconstruction |
| Inner VK identity | Registry suite profile | Aggregation verifier | Circuit constant or authenticated profile membership |
| `claims_hash` | Ordered terminal statements | Outer public instance | Aggregation and outer-instance constraints |
| `claim_digest` | Destination canonical encoder | Halo2 instance or BSB22 `pub` | Destination reconstruction and proof relation |
| BSB22 committed wires | Wrapper R1CS and phase 2 | `D` and commitment PoK | Committed-wire manifest and wrapper constraints |

The proof of concept has exactly three terminal semantic roles per direction:

```text
Cardano to Midnight:
  [cardano_finality, scls_inclusion, cardano_predicate]

Midnight to Cardano:
  [midnight_finality, event_inclusion, midnight_predicate]
```

Internal recursion, fusion, or multiple circuits may implement a role, but the
registered architecture must prove exactly one terminal statement for each
required role. No role is optional. A suite rejects omission, duplication,
reordering, unknown roles, and cross-role substitution even when every supplied
proof and VK verifies alone. The aggregation profile fixes the unique role tags,
allowed VK set and statement adapter per role, count binding, maximum recursion
and aggregation depth, empty and padding behavior, and complete Poseidon and VK
hash parameters. The parameters are gate artifacts extracted from a pinned
implementation; this design does not invent them.

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

The suite profile freezes the domain separator, transcript field order,
hash-to-field mapping, and equality that connects the exact outer instance and
typed output to `claim_digest`. `D` is not a semantic claim hash, and
`claims_hash` is not a replacement for the destination-reconstructed digest.
Suite activation requires two independent encoders to agree on fixed claim,
statement, aggregation, typed-result, and field-element vectors.

A multi-architecture vector resolves two predicates in one deployment domain to
different authorized suite and architecture pairs. Both share byte-identical
`RootContextV1` bytes, each has a distinct `ResolvedProofContextV1`, each verifies
under its own authorized VK graph, and swapping either resolved context fails at
resolution or proof-context equality. This proves that deployment identity does
not collapse into one circuit architecture.

### Reproducible fingerprints and acyclic deployment domain

The Cardano protocol descriptor commits to Cardano identity and era history,
the selected Mithril bootstrap rule, certificate and transition rules, AVK and
protocol-parameter rules, the SCLS signed-entity projection, SCLS format and
tree rules, and the finality adapter. The Midnight protocol descriptor commits
to Midnight identity, the AURA/GRANDPA/BEEFY role profile, runtime release,
BEEFY commitment and ECDSA/Keccak rules, quorum and authority-leaf rules,
authority handoff, header/MMR/parent rules, event inclusion adapter, and finality
adapter. Each descriptor uses fixed-order canonical bytes under the accepted
bridge hash profile:

```text
source_protocol_fingerprint =
  Digest("mcb/source-protocol-fingerprint/v1", canonical_protocol_descriptor)
```

An unresolved component is a canonical blocked marker that names its gate. It
cannot authorize a claim that needs that component. The bridge hash algorithm,
length-prefix rule, fixed domain strings, canonical descriptor schemas, and
independent vectors are the versioned `CONS-DOMAIN-01` artifact. The artifact
format owner publishes it, destination registry tooling enforces it during
activation and resolution, and any field mutation or unresolved required
component blocks activation.

Every value reachable from `DeploymentRootSetV1` is domain neutral. A value is
domain neutral only when neither its canonical fields nor any transitive digest
preimage contains `root_set_digest`, `deployment_domain`, a value derived from
either, or a concrete runtime instance produced after domain derivation. The
pre-domain records are:

```text
SemanticRegistryTemplateV1 = (
  predicate semantics, schema templates, anchor and finality templates,
  suite and architecture template ids, artifact template slots,
  ABI template ids, replay and lifecycle policies
)

ArtifactTemplateV1 = (
  artifact kind, logical graph slot, suite and architecture template ids,
  canonical encoding, exact length, content hash, build or setup template,
  owner and enforcement template
)

DestinationAbiTemplateV1 = (
  destination network identity, transition and state schemas,
  verifier or operation template hash, deployment recipe digest,
  construction and validation rules, resource-bound policy,
  receipt and error-schema templates
)
```

Semantic registry leaves do not contain a deployment domain, registry
activation, artifact authorization, concrete destination instance, or runtime
lifecycle state. Artifact templates do not contain a domain, authorization
record, cache authorization, runtime location, or job. ABI templates do not
contain a domain, deployed address, transaction id, runtime state, or receipt.
Checkpoint bodies and approvals use only these templates and other pre-domain
values.

The digest graph has this fixed topological order:

```text
canonical source, catalog, schema, code, setup, and policy bytes
  -> source protocol fingerprints
  -> semantic registry template leaves -> semantic_registry_template_root
  -> artifact template leaves -> artifact_template_root
  -> destination ABI templates -> destination_abi_template_digests
  -> destination verifier or operation template hashes
     + deployment recipe digests

domain-neutral checkpoint body fields
  + semantic_registry_template_root
  + artifact_template_root
  + destination_abi_template_digests
  + verifier or operation template hashes and deployment recipes
  -> checkpoint_body_digest
  -> checkpoint approval messages and canonical approval set
  -> checkpoint_manifest_digest

DeploymentRootSetV1
  -> root_set_digest
  -> deployment_domain

(root_set_digest, deployment_domain, pre-domain template roots)
  -> RegistryActivationV1
  -> ArtifactAuthorizationV1 records and artifact_authorization_root
  -> DeploymentObservationV1
  -> DestinationAbiInstanceV1
  -> RootContextV1
  -> ActivationDecisionV1
  -> initialized destination state
  -> DeploymentReceiptV1

(RootContextV1, registry resolution)
  -> ResolvedProofContextV1
  -> claim authorization, proof instances, runtime payloads,
     replay keys, and settlement receipts
```

`DeploymentRootSetV1` contains exactly the following classes of values:

| Included pre-domain value | Excluded post-domain or self-referential value |
| --- | --- |
| Bridge program id and fresh deployment instance id | `root_set_digest` and `deployment_domain` |
| Source identity templates and protocol fingerprints | Any digest whose producer consumes the root-set digest or domain |
| Destination network identity templates | Concrete contract, verifier, program, or operation instances |
| Approved domain-neutral checkpoint-manifest digests | `RegistryActivationV1` and its digest |
| Anchor, finality, proof-suite, and circuit templates | `ArtifactAuthorizationV1`, its records, and its root |
| Semantic registry template root | `DestinationAbiInstanceV1` and its digest |
| Artifact template root | Runtime lifecycle state, cache authorization, and location results |
| ABI template digests, verifier or operation template hashes, and deployment recipe digests | Claims, proofs, jobs, replay keys, transactions, run intents, evidence manifests, and receipts |
| Replay, freshness, recovery, approval, and bridge-hash policy templates | Any placeholder, fixed-point seed, or iterate-until-stable value |

Derivation is direct and occurs once:

```text
root_set_digest = Digest(
  "mcb/deployment-root-set/v1",
  CanonicalEncode(DeploymentRootSetV1))

deployment_domain = Digest(
  "mcb/deployment-domain/v1",
  root_set_digest)
```

The domain-bound records are separate outputs:

```text
RegistryActivationV1 = (
  version, root_set_digest, deployment_domain,
  semantic_registry_template_root, destination_identity_digests,
  activated_entry_set_digest, lifecycle_state_digest
)

ArtifactAuthorizationV1 = (
  version, root_set_digest, deployment_domain,
  registry_activation_digest, artifact_template_root,
  artifact_template_digest, graph_slot, content_hash, lifecycle_status
)

DeploymentObservationV1 = (
  version, root_set_digest, deployment_domain,
  fresh_deployment_instance_id,
  destination_network_identity_digest,
  destination_abi_template_digest,
  verifier_or_operation_template_hash, deployment_recipe_digest,
  concrete_destination_instance_id, deployed_code_hash,
  deployment_transaction_id, deployment_confirmation_profile_digest,
  independent_observation_set_digest
)

DestinationAbiInstanceV1 = (
  version, root_set_digest, deployment_domain,
  destination_abi_template_digest,
  verifier_or_operation_template_hash, deployment_recipe_digest,
  concrete_destination_instance_id, deployed_code_hash,
  deployment_observation_digest,
  registry_activation_digest, artifact_authorization_root
)

RootContextV1 = (
  root_set_digest, deployment_domain, checkpoint_manifest_digest,
  source_identity_digest, source_protocol_fingerprint,
  registry_activation_digest, artifact_authorization_root,
  destination_network_identity_digest, destination_abi_instance_digest
)

ActivationDecisionV1 = (
  version, intended_profile, root_context_digest,
  checkpoint_manifest_digest, root_set_digest, deployment_domain,
  fresh_deployment_instance_id, registry_activation_digest,
  artifact_authorization_root, destination_abi_instance_digest,
  gate_roster_digest, ordered_gate_record_set_digest,
  activation_policy_digest, decision_time, decision,
  canonical_approval_set_digest
)

DeploymentReceiptV1 = (
  version, activation_decision_digest, root_context_digest,
  checkpoint_manifest_digest, root_set_digest, deployment_domain,
  fresh_deployment_instance_id, destination_network_identity_digest,
  destination_abi_instance_digest, concrete_destination_instance_id,
  deployed_code_hash, initialization_transaction_id,
  initialized_state_digest, independent_observation_set_digest
)
```

`RootContextV1` is deployment and source context only. Predicate, suite,
architecture, role, VK selection, freshness limits, and replay semantics belong
to the per-claim `ResolvedProofContextV1` in section 7. The deployment controller
produces `ActivationDecisionV1` only after it verifies the roster, every required
gate record, and the approval threshold fixed by the pre-domain activation policy.
The chain-specific deployer first deploys the approved template and recipe. Two
chain observers reproduce `DeploymentObservationV1` from the confirmed deployment
transaction, concrete instance id, and deployed code bytes. The ABI instance
constructor accepts concrete fields only from that observation and checks exact
template and recipe equality. The controller then evaluates the resulting root
context. Only `decision = activate` authorizes destination initialization. The
final `DeploymentReceiptV1` authenticates the initialization transaction and
continuing-state bytes under the pre-domain receipt profile. No producer can
change a root or fill a missing gate.

The following equalities are mandatory and use canonical bytes, not display
labels:

| Value | Checkpoint body/manifest | `DeploymentRootSetV1` | `RootContextV1` | activation decision | deployment receipt |
| --- | --- | --- | --- | --- | --- |
| checkpoint manifest digest | producer | exact member | exact equality | exact equality | exact equality |
| fresh deployment instance id | exact field | exact equality | bound through root-set digest | exact equality | exact equality |
| root-set digest and domain | excluded | producer and derivation | exact equality | exact equality | exact equality |
| source identity and fingerprint | exact fields | exact equality | exact equality | bound through root context | bound through root context |
| registry activation, artifact root, ABI instance | excluded | excluded | exact equality | exact equality | exact equality |
| destination network and deployed instance | network template only | network template only | network exact equality | ABI-instance equality | concrete instance exact equality |
| roster digest | policy template reference only | template equality | excluded | exact published digest | bound through activation decision |

`DeploymentObservationV1` is the sole producer of the concrete destination
instance id and deployed code hash. Its template and recipe digests equal the
root-set copies; the ABI instance copies all four values exactly; the root
context binds the ABI-instance digest; and the activation decision and final
receipt bind that same root context. Two direction manifests, their observations,
and the root set also use one byte-identical fresh deployment instance id.

The destination continuing state stores the root context, activation-decision
digest, and deployment-receipt digest. Construction payloads, runtime calls,
proofs, replay keys, and settlement receipts bind the same root context and their
per-claim resolved proof context. None of these domain-bound records or their
digests is reachable from `DeploymentRootSetV1`.

`CONS-DOMAIN-01` includes two independently implemented golden derivations. Each
starts from the same ordered source bytes and compares canonical bytes and
digests for every template leaf, template root, checkpoint body, approval set,
manifest, root set, domain, registry activation, artifact authorization root,
ABI instance, and root context. The conformance tool resolves every schema and
digest reference reachable from `DeploymentRootSetV1`, rejects a forbidden
post-domain field or type, and topologically sorts the complete digest graph. A
cycle, unresolved producer, back edge, or post-domain dependency fails
activation.

Mutation vectors change every included leaf and require a changed root-set digest
and domain. They mutate each post-domain record while holding the root set fixed
and require authorization or runtime equality failure without recomputing the
domain. A reset changes the fresh deployment instance id, derives a different
domain, rebuilds all post-domain records, and rejects every old-domain proof,
replay record, runtime payload, and receipt. Vectors hold one checkpoint copy of
the fresh instance id fixed while mutating the root-set copy, and conversely;
both fail before activation. No derivation uses a placeholder, fixed point, or
iterative hash search.

### Authenticated freshness

Freshness uses authenticated source time `S` and the complete consensus-backed
destination execution interval `[D_min, D_max]`. Deployment governance supplies
the numeric limits through a versioned content-addressed freshness profile.
Registry resolution copies the exact source and destination adapter digests,
units, conversion rule, unsigned width, inclusive-boundary rule, era schedule,
and numeric limits into `ResolvedProofContextV1`. All values use those fixed
bounded unsigned units, and checked arithmetic rejects overflow or underflow.
Acceptance requires:

```text
D_min <= D_max
D_max - D_min <= max_destination_interval_width
S <= D_min + max_future_skew
D_max <= S + max_anchor_age
D_max <= claim_expiry
```

Equality at a boundary passes; one unit beyond fails. Cardano source time derives
from the certified SCLS slot through the fingerprint-bound era schedule.
Midnight source time derives from a time-bearing field authenticated by the
registered finalized header/MMR relation. If that relation cannot authenticate
time, the profile stays blocked. Cardano destination time comes from the
registered transaction-validity-interval rule. Midnight destination time comes
from the smallest consensus-backed execution interval exposed to the operation.
Endpoint tips and wall clocks are telemetry only unless separately authenticated
by the same finality relation. These checks run after proof verification has
authenticated `S`; a preflight age estimate is advisory only. The exact owners
of `CONS-FRESH-01` are the ordered `owners[]` in `GateRosterV1`. The freshness-
profile and artifact-format teams are contributors, and the destination verifier
is an enforcement locus. Activation requires both source adapters, both
destination rules, filled numeric bounds, and independent boundary and era-
transition vectors.

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

Unknown, downgraded, or mismatched fingerprints, unregistered artifacts, stale
claims, replayed messages, and mixed anchors fail closed without changing safety
state. An untrusted mismatch is not freeze evidence. A domain freezes only for a
registered proof of two individually valid conflicting BEEFY commitments, two
individually chain-valid conflicting Mithril certificates, or an authenticated
source upgrade forbidden by the active fingerprint. The verifier computes the
source-specific conflict key before freezing. Recovery approvals, threshold
satisfaction, and elapsed delay cannot cause a freeze. They authorize recovery
only from the matching recorded `Frozen` state. Rejection, freeze, and failed
recovery never roll an accepted anchor backward or consume replay state.

The composed proof target is at least 128 bits of security with explicit finite
recursion and aggregation bounds. The exact argument must account for the
128-bit truncated Fiat-Shamir challenges used by Midnight recursion, KZG and
Groth16 assumptions, all hash-to-field reductions, and every setup ceremony.

## 6. Bootstrap and roots of trust

The proof of concept uses approved checkpoint manifests. This is a
weak-subjectivity choice. Reproducing a checkpoint from independent nodes detects
operator mistakes but does not turn the checkpoint into a consensus-derived root.

Every recursive base, step, terminal role, and outer statement carries the
post-domain context derived in section 4:

```text
RootContextV1 = (
  root_set_digest,
  deployment_domain,
  checkpoint_manifest_digest,
  source_identity_digest,
  source_protocol_fingerprint,
  registry_activation_digest,
  artifact_authorization_root,
  destination_network_identity_digest,
  destination_abi_instance_digest
)
```

The minimum semantic recursive states are:

```text
CardanoSourceState = (
  RootContext,
  mithril_bootstrap_profile_and_instance_digest,
  certificate_hash,
  certified_epoch,
  current_and_next_avk_and_parameter_digests,
  scls_slot,
  scls_namespace_set_hash,
  scls_root,
  scls_artifact_digest
)

MidnightSourceState = (
  RootContext,
  midnight_identity_digest,
  finalized_block_number,
  finalized_block_id,
  beefy_mmr_root,
  current_beefy_descriptor,
  next_beefy_descriptor,
  mandatory_handoff_state
)
```

Each content-addressed profile supplies the exact binary fields. The semantic
relations are fixed:

```text
Base(manifest, root_set, registry_activation,
     artifact_authorizations, abi_instance, S0):
  ManifestDigest_P(manifest) == S0.RootContext.checkpoint_manifest_digest
  and manifest and every transitive field are domain neutral
  and root_set contains the exact approved manifest and template roots
  and DeriveRootSetDigest_P(root_set) == S0.RootContext.root_set_digest
  and DeriveDomain_P(root_set) == S0.RootContext.deployment_domain
  and registry_activation binds the exact semantic registry template root,
      root-set digest, domain, and destination identity
  and artifact_authorizations bind the exact artifact template root,
      registry activation, root-set digest, and domain
  and abi_instance binds the exact ABI template, deployment recipe,
      concrete destination, registry activation, authorization root,
      root-set digest, and domain
  and every RootContextV1 deployment and source field equals those
      validated post-domain records
  and every CardanoSourceState field outside RootContext equals the approved
      Cardano checkpoint body field named by BaseStateEqualityV1
  and every MidnightSourceState field outside RootContext equals the approved
      Midnight checkpoint body field named by BaseStateEqualityV1

Step(S_prev, evidence, S_next):
  S_prev.RootContext == S_next.RootContext
  and evidence authenticates the exact transition from S_prev to S_next

FinalStatement(S_final, claim, destination_state):
  S_final.RootContext == claim.RootContext
  and claim.RootContext == destination_state.RootContext
  and claim.ResolvedProofContext.root_context_digest == Digest(S_final.RootContext)
  and claim.ResolvedProofContext == destination registry resolution
```

A proof rooted in a sibling checkpoint or domain fails even when all later source
data is identical.

`BaseStateEqualityV1` is a manifest-owned matrix, not an implementation note:

| Recursive base field | Approved checkpoint-body source |
| --- | --- |
| Cardano bootstrap profile/instance, certificate hash, and certified epoch | Selected Mithril terminal profile, terminal certificate, and epoch |
| Cardano current/next AVKs and parameters | Complete terminal current/next AVK and protocol-parameter descriptors |
| Cardano SCLS slot, namespace-set hash, root, and artifact digest | Certified SCLS descriptor and artifact commitment |
| Midnight identity digest | Approved `MidnightIdentityDescriptorV1` |
| Midnight finalized block number/id and MMR root | Approved finalized BEEFY commitment and header/MMR projection |
| Midnight current/next BEEFY descriptors | Complete approved current/next descriptor bodies |
| Midnight mandatory handoff state | Approved pending-or-stable handoff body, including activation point and evidence digest |

The base relation reconstructs all fields from the approved body and compares
them before accepting `S0`. Positive vectors require two independent body
decoders to reproduce the same state. Negative vectors hold the manifest,
root-set, domain, and `RootContextV1` fixed while mutating each listed field one
at a time; every mutation must fail at `recursive-base-manifest-state-equality`.

### Cardano validator tracking Midnight

Midnight bootstrap uses a cryptographic identity rather than an RPC name:

```text
MidnightIdentityDescriptorV1 = (
  canonical_genesis_block_hash,
  canonical_genesis_state_or_header_digest,
  chain_spec_artifact_digest,
  chain_spec_derivation_adapter_digest,
  source_native_network_identifiers,
  initial_beefy_descriptor,
  initial_beefy_derivation_mode,
  source_code_release_digest
)
```

`initial_beefy_derivation_mode` is `DerivedFromChainSpec` or
`IndependentAuthorityRoot`. The first mode extracts the ordered BEEFY keys and
native values from the exact chain-spec bytes, proves every weight is one, and
recomputes the descriptor. The second is a separately approved trust root and
cannot be described as genesis-derived. The source profile retains AURA block
production, GRANDPA local finality, and ECDSA BEEFY destination attestation. It
does not assume BABE or claim that Cardano verifies AURA or GRANDPA directly.

Current and announced next BEEFY sets use the same complete descriptor:

```text
BeefyAuthorityDescriptorV1 = (
  set_id,
  authority_commitment_root,
  authority_count,
  weighting_model = EqualUnit,
  authority_leaf_encoding_id,
  commitment_hash_id = Keccak,
  signature_suite_id = ECDSA_secp256k1,
  quorum_rule_id = StrictTwoThirds
)
```

The Cardano continuing state stores `RootContextV1`, the Midnight identity digest,
latest finalized block number and id, BEEFY MMR root, complete current and next
descriptors, mandatory-handoff state, artifact authorization root, Cardano ABI
instance digest, freshness policy, recovery policy, and replay root. The exact source-native genesis values,
chain-spec bytes, network identifiers, initial authority list, ECDSA encoding,
leaf bytes, integer widths, and handoff rule belong to content-addressed
`CONS-MIDNIGHT-ID-01` and `CONS-BEEFY-01` profiles. The consensus profile owner
extracts them from pinned releases; bootstrap and destination validators enforce
them; sibling-chain, reordered-key, changed-weight, root/count, and handoff
vectors are mandatory; the registry cannot activate the profile until both
independent derivation receipts pass.

BEEFY light clients require an initial authority commitment
([BEEFY light client](../consensus/beefy-light-client.md)). A set id is a counter,
not a key commitment. Each handoff authenticates the full successor descriptor
under the outgoing state.

### Midnight operation tracking Cardano

Cardano genesis identity and a Mithril genesis verification key are independent
roots. The deployment selects exactly one tagged bootstrap rule and instance:

```text
MithrilBootstrapRuleProfileV1 =
  GenesisRuleProfileV1 | CertificateCheckpointRuleProfileV1

GenesisBootstrapInstanceV1 = (
  rule_profile_digest,
  cardano_identity_digest,
  mithril_genesis_vk_native_bytes,
  mithril_genesis_vk_digest
)

CertificateCheckpointInstanceV1 = (
  rule_profile_digest,
  cardano_identity_digest,
  terminal_certificate_hash,
  terminal_certificate_epoch,
  terminal_signed_entity_type,
  current_avk_native_bytes,
  next_avk_native_bytes,
  current_protocol_parameters_native_bytes,
  next_protocol_parameters_native_bytes
)
```

Genesis mode terminates at the independently provisioned Mithril genesis key and
verifies the full chain and terminal genesis signature. Checkpoint mode terminates
at the manifest-approved certificate state, verifies only post-checkpoint
linkage, and never reports the omitted history as genesis-verified. Each step
checks the exact previous certificate, epoch and era rule, selected verification
material, signed protocol message, and successor AVK and parameters. Cross-profile
splicing fails.

The Midnight continuing state stores `RootContextV1`, Cardano identity and era
schedule, selected Mithril bootstrap profile and instance digest, current and
previous certificates and epochs, current and next AVKs and protocol parameters,
SCLS descriptor, artifact authorization root, Midnight ABI instance digest,
freshness and recovery policies, and replay root. `CONS-BOOT-01` contains the native Mithril encodings,
transition adapter, rule profiles, base and step vectors, and independent
reproduction receipts. The consensus profile owner publishes it, the recursive
base and Midnight operation enforce it, and activation requires a valid
base-to-step vector for both genesis and checkpoint profiles. This gate does not
close public SCLS availability.

### Nonrecursive checkpoint manifest

Approver authority is a preauthorized root and cannot be selected by the body it
approves. Canonical checkpoint objects have these layers:

```text
CheckpointApprovalPolicyV1 = (
  approval_policy_id, approver_key_set_digest, threshold,
  signature_algorithm_id, node_independence_rule_id, reproduction_rule_id
)

CheckpointBodyV1 = (
  source_bootstrap_template_digest, source_identity_digest,
  destination_identity_digest, source_protocol_fingerprint,
  finalized_point_descriptor, authenticated_anchor_descriptor,
  current_consensus_descriptor, next_consensus_descriptor,
  pending_transition_descriptor_or_none, artifact_template_root,
  semantic_registry_template_root, destination_abi_template_digest,
  destination_verifier_or_operation_template_hash,
  destination_deployment_recipe_digest,
  freshness_policy_template_digest, recovery_policy_template_digest,
  replay_rule_template_digest, approval_policy_digest,
  deployment_instance_id, derivation_inputs_digest,
  eligibility_evidence_digest, cutoff_time
)

CheckpointApprovalV1 = (
  approval_policy_id, approver_key_id, body_digest, signature_native_bytes
)

CheckpointManifestBindingV1 = (
  approval_policy_digest, body_digest, approval_set_digest
)
```

Derivation is nonrecursive:

```text
body_digest = Digest("mcb/checkpoint-body/v1", CheckpointBodyV1)

approval signature covers Digest(
  "mcb/checkpoint-approval/v1",
  (approval_policy_id, approver_key_id, body_digest))

approval_set_digest = Digest(
  "mcb/checkpoint-approval-set/v1",
  approvals sorted by approver_key_id)

checkpoint_manifest_digest = Digest(
  "mcb/checkpoint-manifest/v1",
  (approval_policy_digest, body_digest, approval_set_digest))
```

The body and every value reachable from it are domain neutral. They exclude the
body digest, approvals, approval-set digest, manifest digest, root-set digest,
deployment domain, registry activation, artifact authorization, ABI instance,
concrete deployed destination identity, runtime payload, and receipt. Duplicate
approver keys are a canonical decoding error and count at most once. Only
preauthorized keys count toward threshold.

At least two independently administered source full nodes reproduce byte-identical
derivable body fields before approval. A Cardano checkpoint is eligible only when
the selected Mithril terminal, current and next AVKs and parameters, signed-entity
projection, SCLS equality, slot/root, and freshness checks pass. A Midnight
checkpoint is eligible only when identity, finalized BEEFY commitment,
block/header/MMR equality, complete current and next descriptors, equal-unit
derivation, and pending mandatory-transition status pass. Checkpoint approval
does not close an absent public SCLS or event-to-MMR gate.

`CONS-CHECKPOINT-01` is a content-addressed package owned by deployment governance
and conformance. Destination bootstrap tooling enforces its policy, canonical
bytes, signatures, eligibility, and threshold. Activation requires two-node
reproduction records, source-specific eligibility reports, independent encoding
and signature vectors, threshold boundaries, and reset vectors. An approved
manifest feeds `DeploymentRootSetV1`; it never contains the resulting domain.
Replacement always uses a new deployment instance id and domain.

### Manifest layers

Trust, proof artifacts, runs, and private operations have different owners:

| Layer | Contents | Binding and publication |
| --- | --- | --- |
| Root template manifest | Domain-neutral source and destination identities, checkpoint, finality and anchor templates, fingerprint policy, semantic registry template root, destination code templates, deployment recipes, replay, recovery, and approval templates | Public; feeds `DeploymentRootSetV1` |
| Artifact template manifest | Domain-neutral suite slots, schemas, circuits, VKs, SRS and setup templates, proving-key hashes, build and transcript evidence | Public; its template root feeds `DeploymentRootSetV1` |
| Activation manifest | `RegistryActivationV1`, artifact authorization root, deployment observations, destination ABI instances, `ActivationDecisionV1`, concrete deployed destination ids, and `DeploymentReceiptV1` records | Public, domain-bound, and stored in destination state; never feeds the root set |
| Run intent | Immutable `RunIntentV1`: run id, selected profile, root-set and domain values, activation and deployment-receipt digests, published roster bytes/digest, software revisions, non-secret endpoint discovery intent, funded-role ids, probe/metric and confirmation profiles, evidence-retention profile, declared evidence locations, and preflight policy | Public post-domain intent fixed before preflight; contains no run result, preflight receipt, or run-evidence manifest |
| Preflight receipt | `PreflightReceiptV1`: run-intent digest, observed endpoint identities and revisions, checks performed, funded-role observations, probe discovery, times, results, and evidence digests | Public post-preflight evidence; cannot feed or alter the run intent |
| Run evidence manifest | `RunEvidenceManifestV1`: run-intent digest, ordered preflight-receipt digests, later job/transaction/confirmation/evidence records, and outcome inputs | Append-only public evidence assembled after preflight; never feeds the run intent or root set |
| Operator overlay | Credentials, signing handles, secret-store locations, local sockets, funding sources, and limits | Private and never hashed into the domain |

Canonical generation records the bytes, digest, tool revision, input digests,
approvals, and an independent verification command. `RunIntentV1` contains no
observed result. Every `PreflightReceiptV1` and every later evidence record binds
the immutable run-intent digest; `RunEvidenceManifestV1` references those
receipts without being in their preimage. Funding and collateral observations do
not invent or publish secret values or chain-specific amounts. Concrete
identities, checkpoint values,
freshness limits, approver keys, endpoint values, funding quantities, VK/SRS
inventories, and registry templates do not exist yet. Each remains an inactive
versioned content-addressed gate output under the owner, enforcement point,
vectors, and activation rule named in sections 8, 23, and 24.

## 7. Shared claim protocol

A destination receives a typed query, canonical resolution record, claim
envelope, proof blob, public witness data required outside the circuit, and a
registry membership proof. The [shared envelope](../proof-claims/claim-envelope.md) and
[claim interface](../proof-claims/claim-interface-schema.md) supply the
source-backed starting shapes.

The canonical query shape is:

```text
QueryV1 = (
  schema_version,
  requested_predicate,
  typed_inputs,
  destination_context,
  optional_constraints
)
```

`optional_constraints` may require equality with resolved values but cannot
authorize them. Registry resolution owns the anchor, finality rule, statement
and result schemas, proof suite, every VK, SRS and setup profile, circuit
architecture, destination verifier or operation, artifact graph, replay mode,
and lifecycle state. The resolution record also binds the root-set digest,
domain, registry activation, artifact authorization root, and ABI instance.

Every successful resolution produces this per-claim context:

```text
ResolvedProofContextV1 = (
  version, canonical_query_digest, root_context_digest,
  registry_activation_digest, predicate_id, predicate_version,
  statement_schema_digest, result_schema_digest,
  anchor_profile_digest, finality_profile_digest,
  proof_suite_id, circuit_architecture_hash,
  ordered_terminal_roles, authorized_artifact_graph_digest,
  destination_abi_instance_digest, destination_entry_point,
  source_time_adapter_digest, destination_time_adapter_digest,
  source_time_unit, destination_time_unit, conversion_rule_digest,
  unsigned_integer_width, inclusive_comparison_rule,
  max_destination_interval_width, max_future_skew, max_anchor_age,
  era_schedule_digest, expiry_rule_digest,
  replay_policy_digest, destination_policy_digest,
  canonical_resolution_digest
)
```

The exact adapters, units, conversions, integer width, inclusive comparisons,
and numeric bounds are therefore fixed before source collection and cannot be
chosen by a prover or relayer. A resolution with an unfilled bound or an
unauthenticated source-time adapter is not eligible for proving.

The proof-bound envelope includes:

- schema version, source system, network, era or runtime version, protocol
  fingerprint, and deployment domain;
- predicate id and version, statement schema, result schema, and typed output
  hash;
- anchor type and digest, finality rule and parameters, source height or slot,
  and freshness scope;
- proof-suite id, circuit-architecture hash, verifier or operation id, and
  canonical resolution-record digest;
- destination network, destination application and entry point, action, recipient,
  asset, amount or rights, and context hash;
- expiry, replay scope, lane, message id, and nullifier where applicable.

Every suite publishes a field-binding matrix that labels each field
`proof-bound`, `validator-only`, or `advisory`. Any field that changes acceptance
cannot be advisory. Query copies of a resolved anchor, suite, verifier, SRS,
setup, architecture, operation, or artifact id are non-authoritative constraints.
A mismatch is a named permanent resolution error and never selects caller
semantics.

CDDL owns bounded data shapes. `mcb.common-cbor.rfc8949-deterministic.v1` owns
the bytes and domain separators for `QueryV1`, resolution, resolved proof
context, envelope, proof response, result, verification, submission, receipt,
gate, and vector records. It is RFC 8949 deterministic CBOR with definite
lengths, preferred integer and length forms, and deterministic map-key ordering.
It rejects duplicate keys, indefinite forms, non-preferred aliases, tags,
floating-point values, unknown critical fields, and trailing bytes. Every record
has a bounded schema version; version negotiation occurs outside the hashed
record. JSON is a diagnostic projection only.

This common framing is suite independent and cannot be redefined by a suite.
Each `SuiteNativeProofProfileV1` is the sole owner of its native proof, native
instance, VK, scalar/field, transcript, curve/point, subgroup, and verifier-
equation grammar. Common records carry those native values only inside explicitly
typed byte strings. A destination ABI references the suite-native profile digest
and embeds its bytes without decoding, reordering, normalizing, or redefining
them. The ABI owns only chain datum, redeemer, call, predecessor/successor,
value, transaction, and receipt wrappers. Neither layer can change a common
record field, key, order, domain separator, digest, or typed-result encoding.
`QueryV1` is a
five-element CBOR array in the field order printed above; its version is unsigned
integer `1`. The CDDL and schema digests bound the nested typed inputs,
destination context, and constraints.

Two independently maintained codecs must encode each golden diagnostic value to
identical bytes, decode and re-encode without change, and produce identical
digests and field elements. Boundary vectors cover integer and length limits,
map ordering, duplicate fields, alternate forms, unknown critical fields, and
trailing bytes. Hash-to-field vectors identify the exact domain separator,
canonical bytes, intermediate digest, conversion rule, and field element. The
wire profile remains a source-dependent Sprint 3 gate; no language may choose an
encoding while it is absent.

The golden corpus contains byte-exact `QueryV1`, resolution, and resolved-proof-
context records for both
directions. Each vector names the requested predicate, typed inputs, destination
context, optional constraints, registry activation, resolved semantics, exact
canonical bytes, and record digest. Two independent codecs must reproduce those
bytes. Query fields outside the shape, a constraint mismatch, or caller-selected
authorization data fail at query decode or registry resolution as declared.
Polyglot vectors require Rust, Go, and TypeScript implementations to reproduce
the same common bytes and digests while their suite adapters carry different
native proof encodings. A suite that attempts to redefine `QueryV1` or common
framing fails the `common-codec-no-redefinition` vector.

Validation order is fixed:

```text
bounded common-frame and QueryV1 decode
-> bind the published GateRosterV1 digest and active destination RootContextV1
-> authenticate active RegistryActivationV1 and resolve the query
-> construct and authenticate ResolvedProofContextV1
-> optional source collection and proof production under that resolution
-> registered typed-result decoding
-> typed-result canonical re-encoding and proof-bound field matrix
-> artifact, anchor, VK, SRS, setup, transcript, and ABI authorization
-> public-input reconstruction
-> proof verification
-> authenticate source time S from the verified finality/inclusion statement
-> final destination context, expiry, freshness, and replay checks
-> destination policy over the already-decoded typed result
-> one atomic tracked-state, application, value, and replay transition
```

This is the only authenticated submission order. A transport may make an
advisory cache, age, or replay lookup before proving, but its result cannot accept
or permanently reject a claim and is repeated after proof verification. Final
freshness consumes the proof-authenticated `S` and the resolution-bound adapters,
units, conversion rule, integer width, and bounds. Final replay and policy checks
consume the same resolved predicate and canonical typed result. Registry and
roster binding occur before preflight, source collection, witness construction,
or proving.

Malformed, aliased, out-of-range, duplicate, unknown-critical, or trailing typed
result data fails before public-input reconstruction and consumes no replay state.
The circuit composes the three terminal semantic roles by the equality ownership
in section 4. Independently valid relations for different roots do not compose.
Malformed-result vectors carry a valid prior resolution and name
`typed-result-canonicalization` as the expected stage, the stable failure code,
proof-verifier-not-invoked evidence, and `NO_CHANGE` for tracked, application,
value, and replay state. An earlier decode or resolution failure does not satisfy
these vectors.

## 8. Predicate registry

The registry is part of proof semantics. It has a domain-neutral semantic
template and a separate domain-bound activation. A semantic template entry
binds:

- predicate id and version, source namespace, formal statement, and result type;
- accepted anchor profile, finality rule, freshness rule, and source protocol
  fingerprint policy;
- statement and result schema hashes;
- proof-suite id, circuit-architecture hash, proof-bound selector, and parameter
  hash;
- suite-profile digest, exact three-role sequence, per-role statement adapters and
  authorized VK sets, recursion bound, aggregation parameter digest, and complete
  field-binding matrix;
- every inner VK, aggregation VK, wrapper or operation VK, proving-key hash, KZG
  SRS manifest, Groth16 setup manifest, committed-wire manifest, transcript
  version, destination ABI, and confirmation profile;
- destination context, expiry, replay, lane, and lifecycle policy templates;
- audit and provenance digests.

No semantic template entry or transitive schema, artifact, ABI, or policy
reference contains a concrete deployment domain, root-set digest, registry
activation, artifact authorization, destination instance, runtime lifecycle
state, or receipt. The ordered semantic leaves produce
`semantic_registry_template_root`, which feeds `DeploymentRootSetV1`.
`RegistryActivationV1` is derived only after the domain and binds the template
root, selected destination identities, activated entry set, and lifecycle state.
Destination state stores its digest as the active registry authority.

Authorization follows a nested artifact-binding graph:

```text
semantic_registry_template_root
  -> predicate semantic template and version
     -> anchor and finality templates
     -> statement and result schema templates
     -> proof-suite template
        -> circuit architecture and selector templates
        -> exact terminal-role and statement-adapter templates
     -> artifact template slots
     -> destination ABI and confirmation-profile templates

(root_set_digest, deployment_domain, semantic_registry_template_root)
  -> RegistryActivationV1
  -> active predicate membership and lifecycle authorization
  -> domain-bound ArtifactAuthorizationV1 records
  -> chain-authenticated DeploymentObservationV1
  -> DestinationAbiInstanceV1
  -> claim authorization and runtime verification
```

A missing or inconsistent template, activation, or authorization node rejects
the claim even if its isolated cryptographic proof verifies. The proof of
concept keeps the template roots and their post-domain activation records
immutable within a deployment domain. Production lifecycle states may include
active, frozen, and deprecated only after a transition specification fixes
authority, threshold, delay, activation, in-flight proof behavior, and domain
effects.

Registry population is blocked until the catalog gate proves exactly 42 unique
Cardano records and 52 unique Midnight records, no duplicate ids, all required
fields, and a provenance digest for every record. Template reuse reduces circuit
count; it never substitutes one predicate record for another.

### Artifact enforcement locus

An artifact id carried in a query or claim is only a consistency assertion. The
active registry, continuing state, and authorized profile select the bytes used
for verification.

| Artifact | Authoritative owner | Enforcement time and locus | Required binding |
| --- | --- | --- | --- |
| Checkpoint manifest, root-set digest, and domain | Destination continuing state | Recursive base and every claim | Root-context equality |
| Semantic registry template and activation | Destination continuing state | Before result decoding and public-input reconstruction | Template membership plus exact activation digest |
| Midnight operation VK | Artifact authorization and Midnight ABI instance | Runtime proof verification | Canonical VK bytes, template slot, and deployed code hash |
| BSB22 wrapper VK | Artifact authorization and Cardano ABI instance | Runtime proof verification | Exact 672-byte ABI template, authorization, and deployed digest |
| Inner and aggregation VKs | Activated registry and artifact authorization | Circuit constants or authenticated in-circuit membership | Role-specific template and authorization equality |
| KZG verifier SRS subset | Artifact template and authorization records | Operation verifier and full-decider circuit | Exact points, prefix, and degree; never prover-selected |
| BSB22 commitment key | BSB22 ABI profile | Cardano verification and phase 2 | Exact key bytes and committed-wire manifest |
| Groth16 phase 1 and phase 2 | Deployment governance | Deployment gate | Verified receipts and ceremony/deployed VK byte equality |
| Proving-key hash | Reproducible build record | Build and proving audit | Circuit and setup equality, not per-claim authority |
| Transcript and challenge profile | Verifier source and suite profile | Proof generation and verification | Exact schedule, version, and content digest |
| Destination code and ABI | ABI template and `DestinationAbiInstanceV1` | Deployment and every transition | Template hash, recipe, concrete instance, and byte-level vectors |

If a VK, SRS point, or transcript parameter is a witness rather than a circuit
constant, the relation authenticates it against the artifact authorization root
in `RootContextV1`. Canonical representation alone does not authorize it.
Deployment checks byte equality among ceremony output, artifact template,
domain-bound authorization, ABI instance, and deployed VK before activation.

### Artifact resolution and gate records

An `ArtifactTemplateRefV1` identifies artifact kind and graph slot, suite and
architecture templates, encoding, exact length, content hash, and artifact
template membership proof. It is domain neutral. The post-domain
`ArtifactAuthorizationV1` binds that template reference to the root-set digest,
domain, registry activation, and lifecycle status. `ArtifactFetchHintV1` carries
advisory locations and is neither a root-set input nor an authorization record.

The resolver starts from the registry resolution and exact root context. It
checks registry activation, artifact authorization, template-root membership,
logical graph slot, and ABI-instance expectations before fetching. It then
checks exact length, encoding, and content hash before cache or use. Caches are
keyed by content hash and retain the domain-bound authorization proof. Offline
bundles use the same contract. Missing, malformed, hash-mismatched, and
well-formed but unauthorized artifacts have distinct permanent or retryable
errors. A URI, file path, provider signature, or cache hit never grants
authority.

Every value that is unavailable at foundation time is represented by this
versioned content-addressed record rather than by a placeholder convention:

```text
GateDeliverableV1 = (
  gate_id,
  owners[],
  interfaces[],
  applicability,
  required_evidence[],
  activation_ref,
  artifact_kind,
  canonical_schema_and_encoding,
  content_hash_and_length,
  pinned_sources_or_source_absence_record,
  enforcement_locus_and_time,
  positive_and_negative_vector_bundle,
  independent_reproduction_receipts,
  expected_failure_code,
  supersession_rule
)
```

The first six fields are copied byte-for-byte and in order from the decoded
roster entry. Omission, addition, substitution, or reordering fails
`exact-roster-entry` before outcome evaluation. Other parties are contributors
or enforcement loci, never additional gate owners. Activation requires an
accepted template content hash under the semantic registry and artifact
template roots, roster-owner-signed derivation evidence, both
independent reproductions, all declared vectors, and successful enforcement at
the named locus. The domain-bound activation and authorization records are then
derived and stored without feeding their digests back into either template root
or `DeploymentRootSetV1`. An absent or failed deliverable keeps only its affected
suite or profile unavailable. It does not authorize a fallback, a guessed
constant, or an implementer-selected rule.

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

Mithril certificates form a chain under the selected genesis or certificate
checkpoint profile in section 6. Validation is not one aggregate pairing check.
A verifier must check certificate hashing and previous-certificate linkage,
authenticate the aggregate verification key and protocol-parameter transitions,
verify the signed message under the certificate suite, enforce epoch and era
rules, and terminate at that profile's exact approved terminal
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

Certification and SCLS validity compose only through exact message equality. The
registered Cardano anchor profile defines:

```text
CardanoIdentityDescriptorV1 = (
  network_magic, network_id,
  byron_genesis_configuration_hash,
  shelley_genesis_configuration_hash,
  era_history_digest, protocol_parameter_transition_adapter_digest,
  mithril_network_identifier, identity_derivation_adapter_digest
)

CertifiedSclsDescriptorV1 = (
  cardano_identity_descriptor_digest,
  mithril_bootstrap_profile_digest,
  scls_signed_entity_type,
  scls_signed_entity_format_version,
  scls_version,
  slot_no,
  namespace_set_hash,
  scls_global_root,
  scls_artifact_digest,
  native_projection_adapter_digest
)
```

The identity owner derives `CardanoIdentityDescriptorV1` from pinned genesis and
network configuration bytes. The consensus-profile owner independently derives
the same digest when it validates the Mithril terminal. The finality circuit and
SCLS circuit require byte-identical identity, slot, entity, namespace-set, root,
and artifact digests. Vectors mutate every identity component, reuse a network
name with another genesis, and cross a configured era boundary.

`SclsTreeProfileV1` fixes the complete two-level tree relation: the accepted
namespace manifest and its ordering; canonical namespace, key, and value bytes;
live-entry and tombstone rules; the Blake2b-224 leaf and internal-node domain
bytes; child order; empty-tree root; odd-node and power-of-two padding; maximum
depth and entry count; path direction encoding; namespace-root leaf encoding;
and the global-tree construction. No item is a prover parameter. A profile with
an unfilled field or a namespace set that differs from the certified descriptor
cannot activate.

A membership witness contains one live entry, its canonical index, every sibling
and direction bit to the selected namespace root, then every namespace-root
sibling and direction bit to the certified global root. The circuit recomputes
both paths, bounds every index and depth, and requires the manifest namespace set
to equal the certified `namespace_set_hash`.

A nonmembership witness is one of four tagged forms: `empty-namespace`,
`before-first`, `between-neighbors`, or `after-last`. The latter three authenticate
the boundary or adjacent live entries under the same namespace root and prove
strict canonical-key inequalities; `between-neighbors` also proves consecutive
indices. `empty-namespace` authenticates the profile's empty root. Tombstones,
nonadjacent neighbors, equal keys, a witness from another namespace, omitted
namespace roots, alternate padding, and a path that reaches a sibling global root
all reject. Nonmembership never means merely failing to produce membership.

The proof parses and canonically checks the SCLS artifact, recomputes its digest,
slot, namespace-set commitment, and global root, constructs the descriptor,
projects it through the pinned source-native adapter, constructs the exact
Mithril signed-message bytes, and constrains those bytes equal to the
certificate protocol-message field. The SCLS inclusion role consumes the same
slot, namespace-set commitment, artifact digest, and root. It cannot accept
separate caller copies. The adapter includes every source-native field that can
change the signed message and does not invent a field absent from the selected
source profile.

The exact owners of `CONS-CARDANO-01` are the ordered `owners[]` in
`GateRosterV1`. The Cardano-identity and SCLS-tree-profile teams are
contributors; the Mithril relation and SCLS inclusion adapter are enforcement
loci before predicate evaluation. Activation
requires a source-backed signed-entity projection, both canonical descriptor
schemas, a complete `SclsTreeProfileV1`, membership and all four nonmembership
forms, minimum/maximum key, empty/singleton/odd/padded tree, namespace omission,
padding, direction, depth, index, neighbor, tombstone, identity, and certificate
mutation vectors, plus two independent native message encoders and two
independent tree-witness encoders. The required evidence ids are defined by the
sole machine-readable roster. Public availability remains the separate
`S01-BLOCK-02/public-scls-availability` gate.

[Ouroboros Peras](../cardano/ouroboros-peras-finality.md) is also Proposed. Its
vote certificate and Praos fallback remain a production research path, not the
selected anchor and not a current Cardano finality primitive. The proof of concept
must not describe either Peras or Mithril-certified SCLS as active Cardano
consensus.

`S01-BLOCK-02` closes only when an accepted public Mithril signer population
certifies the exact registered SCLS entity and a complete positive and negative
certificate-chain verification is reproducible.

## 12. Cardano to Midnight proof path

This path uses the registered Midnight Halo2/Plonkish stack over BLS12-381. Its
three terminal semantic roles are exactly
`[cardano_finality, scls_inclusion, cardano_predicate]`:

1. `cardano_finality` verifies the selected Mithril base or step, authenticates
   AVK and protocol-parameter transitions, and constrains the certificate message
   equal to the registered SCLS entity.
2. `scls_inclusion` verifies the registered artifact and membership or
   nonmembership path under the exact certified slot and root.
3. `cardano_predicate` consumes the resulting Cardano ledger object and produces
   the canonical registered typed result.

The architecture may fuse or recursively implement those relations, but its
aggregation boundary exposes exactly one terminal statement per role. The
aggregation relation enforces the ordered roles, their role-specific VKs and
statement adapters, count three, exact Poseidon profile, and equality to the same
claim, fingerprint, domain, destination context, expiry, and replay value.

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

Midnight contracts authenticate the active registry through `RootContextV1` and
resolve an operation VK only in per-claim `ResolvedProofContextV1`; neither
contract state nor a caller selects a proof suite, architecture, or VK. Library
availability does not establish that a
deployed operation can accept this external proof, reconstruct the registered
statement, and update tracked Cardano state, application state, value state, and
replay state atomically. An operation with no value effect commits the explicit
`ValueStateV1 = Absent(reason_code)` representation. That execution-surface
requirement is `S01-BLOCK-05/midnight-execution`.

The content-addressed `HALO2-OP-01` profile is the activation output of that gate.
The circuit and adapter owners supply the exact source commits, proof framing and
bounds, native instance count, order, and field encoding, terminal-role adapters,
transcript and verifier equations, operation and code identity, registry-based VK
resolution, canonical query, claim, and result schemas, predecessor and successor
Cardano-source state, destination action, replay update, resource bounds, and
stable error mapping. The deployed Midnight operation enforces the profile at
decode, authorization, verification, and atomic transition. Vectors include one
registered bridge proof and fixed mutations of each proof-bound field, proof,
instance, VK, root context, typed result, and predecessor state. Activation
requires all positive and no-change mutation receipts. A generic library proof
cannot close the gate.

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
id. The Cardano-side tracked state binds the complete current and next authority
descriptors from section 6. Authority leaves are
`public_key || stake_le`, hashed into a Keccak multiproof. Published initial
BEEFY/session authority counts are 6 on govnet, 7 on devnet, and 10 on mainnet
([validator-set sizing](../consensus/midnight-validator-set-sizing.md)). Those
genesis counts are benchmark inputs, not static runtime limits; live mandatory
block transitions must be verified.

For descriptor count `N`, strict more-than-two-thirds quorum is:

```text
required_signatures = floor((2 * N) / 3) + 1
                    = N - floor((N - 1) / 3)
```

The relation rejects `N = 0`, checked-arithmetic failure, duplicate signer
indices, out-of-range indices, invalid paths, an authority-proof total-leaf count
different from `N`, and fewer than the required number of distinct valid
members. A signer multiproof alone cannot establish the equal-unit model. The
checkpoint and each set transition provide the complete ordered authority list,
recompute root and count, and prove every native authority value is exactly one.
A change to weighting requires a new model, adapter, fingerprint, suite, and
deployment domain.

The finality relation accepts exactly one canonical `MMR_ROOT_ID` payload and
binds these equalities:

```text
signed_commitment.validator_set_id == current.set_id
signed_commitment.block_number     == successor.finalized_block_number
signed_commitment.mmr_root          == successor.mmr_root
header_or_leaf_relation.block_id    == successor.finalized_block_id
header_or_leaf_relation.mmr_root    == successor.mmr_root
```

The successor point is strictly later under the registered ordering. The pinned
MMR profile owns payload ordering, MMR size, leaf index, finalized-header fields,
block-id construction, and parent-block rule.

Authority rotation follows one authenticated handoff state machine:

```text
Stable(current, announced_next)
  -> Pending(current, authenticated_next, activation_point,
             handoff_evidence_digest)
  -> Stable(current = authenticated_next,
            announced_next = newly_authenticated_next)
```

The outgoing set authenticates the mandatory MMR leaf and the full next
descriptor, including count and equal-unit proof. The pinned transition adapter
defines the mandatory-block predicate, signing set, successor-id rule, and
activation point. Skipped ids, root/count substitution, early or late activation,
nonmandatory evidence, the wrong signing set, and a successor different from the
pending descriptor reject with no state change. These source-native rules are
outputs of `CONS-BEEFY-01`; block spacing is not a derivation rule.

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

`S01-BLOCK-03` produces a versioned content-addressed event-inclusion profile
owned by the Midnight consensus and adapter owners. The `event_inclusion`
terminal role and Cardano validator enforce it between the authenticated BEEFY
state and predicate role. Its vector bundle mutates event bytes and position,
containing object, header, parent mapping, leaf encoding and index, MMR size and
path, root, finalized block id and number, fingerprint, and domain. Activation
requires a rejecting prototype, two independent canonical encoders, and
source-backed positive and negative receipts. Until then, the role remains
unavailable rather than accepting the relay object directly.

## 14. Midnight to Cardano proof path

This path uses the registered full-decider BSB22 commitment-Groth16 suite over
BLS12-381. Its terminal semantic roles are exactly
`[midnight_finality, event_inclusion, midnight_predicate]`. Internal recursion or
fusion is permitted only when the architecture exposes one terminal statement
per role and the aggregation relation enforces their order, count three,
role-specific VKs and adapters, Poseidon profile, and root-context equalities.
The outer BSB22 circuit then proves the complete Halo2/KZG decision relation that
Cardano cannot infer from a prepared accumulator.

The wrapper constrains one Boolean acceptance result to one only after it:

1. parses the exact outer proof and public instance and consumes the full
   transcript;
2. authenticates the outer, aggregation, and role-specific inner VKs;
3. recomputes the ordered three-role `claims_hash`;
4. verifies every inner accumulator decision required by the pinned verifier;
5. executes the exact outer PLONK preparation relation;
6. accumulates with the exact outer-instance accumulator;
7. executes the final KZG decision equation with the authorized SRS verifier
   parameters;
8. constrains the final result to one.

Prepared accumulators, pairing inputs, transcript states, verifier parameters,
and accept bits are recomputed or authenticated against `RootContextV1`; none is a
free prover input. The profile classifies the outer IVC VK, every inner and
aggregation VK, all SRS points, and every transcript parameter as either a
circuit constant or an authenticated input with a named registry equality.

The Plutus validator reconstructs `claim_digest` from the registered canonical
typed claim and encodes it as the canonical 32-byte little-endian BLS12-381 Fr
value used for the one explicit BSB22 public scalar. The decoder rejects values
greater than or equal to `r`; it never reduces caller bytes into an alias. The wrapper
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

`S01-BLOCK-04` produces the content-addressed full-decider equivalence profile.
The proof-system owner supplies pinned repository identities and commits, feature
flags, toolchain or container digest, native verifier entry point and source
inventory, proof and instance encodings, transcript schedule, accumulator types
and encodings, all preparation, accumulation, and final equations, exact
Poseidon and VK-hash export, KZG verifier SRS subset, circuit and constraint-system
hashes, committed-wire manifest, native/circuit equivalence vectors, and
independent reproduction receipts. The wrapper circuit enforces the profile and
deployment tooling checks its graph and source hashes. The registry cannot
activate the suite while any item is absent.

The gate has a falsifiable final-decision negative. Its instrumented wrapper
witness is canonical and passes parsing, VK authorization, transcript,
preparation, and accumulation preconditions, but the final authorized KZG
equation is false. The named final-decision constraint must be unsatisfied and no
outer proof may be produced. Separate earlier-stage controls reject at parsing,
VK authorization, transcript, and preparation, and a post-generation BSB22 byte
mutation rejects at the Cardano parser, PoK, or pairing stage. That outer-proof
mutation does not count as the invalid-accumulator result. Every rejection keeps
tracked, application, value, and replay state byte-identical.

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
BLS12-381. A bridge artifact template manifest records:

- suite, curve, transcript, challenge, subgroup, and point-encoding rules;
- circuit source and architecture hashes, K or constraint domain, and selectors;
- all inner, aggregation, wrapper, and destination VK hashes;
- proving-key hashes without committing large or secret material to git;
- KZG SRS catalog entry, degree, prefix, contributions, and transcript;
- Groth16 phase 1 and phase 2 transcripts, contribution receipts, beacon, and
  independent verification;
- build toolchain and reproducibility evidence.

The BSB22 suite also binds one content-addressed committed-wire manifest to the
wrapper R1CS and circuit-specific phase 2:

| Field | Required content |
| --- | --- |
| Constraint-system identity | Circuit source and R1CS or constraint-system digest |
| Commitment group | The single commitment represented by `D` |
| Wire map | Exact wire index, order, bounded type, and semantic label for every committed variable |
| Blinding | Blinding-variable ownership and derivation rule |
| Public equality | Constraint locations proving `pub == claim_digest` |
| Outer binding | Constraint locations connecting outer instance and canonical typed result to the claim preimage |
| Setup binding | Phase-2 transcript and ceremony-output VK digests |

`D` and its PoK establish knowledge of those committed variables. They establish
equality to the destination claim only through the listed R1CS constraints. A
wire-map or R1CS mismatch blocks phase-2 output and deployed VK use. Setup
activation checks byte equality among ceremony output, the ABI profile, the
registry slot, and the deployed destination VK.

The suite profile, aggregation profile, full-decider profile, BSB22 ABI,
committed-wire manifest, SRS subset, and setup receipts are separate immutable
artifacts joined by the artifact graph. Each artifact has its own exact owner,
enforcement locus, vector bundle, and activation rule under `GateDeliverableV1`.
Missing Poseidon parameters, transcript schedules, verifier equations, SRS
points, wire maps, or setup receipts keep the suite inactive; foundation prose
does not supply substitute values.

A single-operator setup using the MPC framework has landed a BSB22 proof on
Cardano Preview, but the deployed key has no multi-party 1-of-N protection. That
is deployment feasibility evidence only, not an accepted bridge setup.

## 16. Reference harness

The reference harness exposes versioned `query`, `prove`, `verify`, `submit`, and
`inspect` flows for both directions. Its records cover the query, claim envelope,
proof response, canonical typed result, artifact references, submission receipt,
and verification diagnostics. Registry resolution occurs before source
collection. A query constrains requested semantics but cannot authorize an
anchor, suite, VK, SRS, setup, operation, architecture, or artifact location.
Every component consumes the same canonical resolution-record digest.

CDDL defines bounded data shapes, while the protocol's deterministic binary
profile defines hashable bytes as specified in section 7. Two independent codecs
must agree on bytes, digests, and field elements and reject every alternate or
trailing representation. JSON Schema remains diagnostic.

Fixtures have two noninterchangeable provenance profiles:

| Kind | Required binding | Comparison and outcome use |
| --- | --- | --- |
| `captured-public` | Raw authenticated source bundle, original root template and activation manifests, domain, source receipts, content hashes, and pinned clock | Must reproduce byte-identical statements under the same manifests and domain; offline replay is not a new live execution |
| `synthetic-lab` | Dedicated lab root template and activation manifests, domain, deterministic witness, clock, and RNG seed | May compare typed semantics, but proof-bound roots and statements must differ; supports `degraded-lab` only after both real destination transitions |

A fixture record binds its kind, source bundle, root template and activation manifests, domain, clock,
source fact, expected canonical statement digest, and provenance. A synthetic
fixture cannot be relabeled as captured public data. Adapters, provers, and
relayers remain untrusted; the destination verifier is the acceptance boundary.

### Executable structural slice

The repository includes a non-activating reference slice under `reference/`.
Rust and Go independently consume the same versioned fixture but share no codec
or classifier library. Both reproduce the published 7,705-byte gate roster,
validate a closed structural root schema and a closed
`SourceEventIdentityV1`, topologically check a 15-node producer graph, encode
typed deterministic CBOR, and compare complete hash preimages before comparing
digests. A cycle, missing producer, non-forward edge, post-domain dependency,
unknown field, malformed typed value, or cross-language disagreement rejects.

The diagnostic profile is `mcb.structural-lab.sha256-cbor.v1`. Its root,
deployment-domain, continuity, and gate-record-set hashes use this framing:

```text
u64_be(domain_byte_length) || UTF8(domain) ||
u64_be(body_byte_length) || body
```

This framing tests ownership and dependency order. It is not the unresolved
production profile owned by `CONS-DOMAIN-01`, and every report fixes
`activation_eligible=false`.

The reset vector is a state-bearing continuity migration. Changing the fresh
deployment instance id changes the root and domain while the same authenticated
source event keeps one continuity key. The imported consumed set rejects that
event and accepts an unrelated event. The base classifier joins 14 ordered
status and evidence records to the exact roster, derives six open activation
gates and eight unresolved consensus gates, and selects row 2. Synthetic vectors
exercise all five classifier rows, but rows 4 and 5 never change the structural
report's actual deployment outcome from `blocked`.

The Go BSB22 component is a native-byte parser, not a verifier. It enforces the
336-byte proof, 672-byte committed VK, every named field offset, and a canonical
32-byte little-endian scalar below the BLS12-381 scalar modulus. Boundary and
endian-trap vectors do not perform point decoding, subgroup checks, pairings,
the full Halo2/KZG decision, or Cardano execution. Its exact affected gate ids
remain `S01-BLOCK-04/full-decider` and `S01-BLOCK-06/cardano-execution`, both
unresolved.

Public reads are isolated in the Python adapter and use Scrapling. Immutable
capture envelopes retain exact request and response bodies, HTTP statuses,
per-exchange digests, endpoint metadata, time, adapter revision, and the fixed
`unsigned-observation` label. Closed normalized schemas reject positive
finality, SCLS, event-inclusion, proof, checkpoint, or execution claims. The
offline verifier performs no live read, stages every candidate outside the
repository, and publishes input-bound golden evidence only after the entire run
passes.

The planned implementation layout uses Rust for common APIs, source adapters, and
Midnight/Halo2 circuits; Go and gnark for the BSB22 wrapper; Plinth compiled to
UPLC for Cardano; and Compact with TypeScript bindings for the Midnight operation.
A language may change only through a decision record that preserves canonical
bytes, suite ids, and verification semantics.

Job and relayer identity is deterministic:

```text
relayer_id = Digest("mcb/relayer-id/v1",
  CanonicalEncode((operator_namespace, canonical_transport_public_key)))
job_id = Digest("mcb/job-id/v1",
  CanonicalEncode((deployment_domain, direction, canonical_query_bytes)))
settlement_id = Digest("mcb/settlement-id/v1",
  CanonicalEncode((ResolvedProofContextV1.replay_policy_digest,
                   canonical_replay_tuple)))
attempt_id = Digest("mcb/attempt-id/v1",
  CanonicalEncode((job_id, relayer_id, u64_attempt)))
submission_id = Digest("mcb/submission-id/v1",
  CanonicalEncode((destination_network_identity_digest,
                   canonical_transaction_body_digest)))
```

Every preimage is a fixed-arity deterministic-CBOR tuple under the common codec;
raw concatenation is forbidden. Boundary-shift vectors such as `("ab", "c")`
versus `("a", "bc")` must produce distinct canonical bytes and ids. The key and
counter encodings come from the same profile. A timestamp, endpoint, local
process id, or secret is not an identity input. Two coordinators observing one
settlement id converge on one durable settlement record.

| Current phase | Legal successor | Required durable evidence before transition | Failure and recovery |
| --- | --- | --- | --- |
| `received` | `roster-bound` | canonical query bytes and job id | malformed common framing -> `permanent-failure` |
| `roster-bound` | `resolved` | exact published roster bytes/digest and active root context, stored before any preflight or source read | mismatch -> `permanent-failure`; unavailable destination state -> `retry-wait` |
| `resolved` | `source-ready` | authenticated registry resolution and `ResolvedProofContextV1` | constraint or authorization mismatch -> `permanent-failure`; transport only -> `retry-wait` |
| `source-ready` | `result-canonical` or `proving` | authenticated source bundle and witness manifest | transport -> `retry-wait`; source conflict -> source-evidence freeze path |
| `proving` | `result-canonical` | attempt id, authorized artifact graph, witness digest, prover lease, produced proof held as unverified bytes | capacity/timeout -> `retry-wait`; deterministic synthesis failure -> `permanent-failure` |
| `result-canonical` | `proof-ready` | canonical typed-result bytes/digest under resolved schema | malformed result -> `permanent-failure`; proof verifier remains uninvoked |
| `proof-ready` | `locally-verified` | proof, native instance, statement, and result digests | missing artifact -> policy-classified retry or permanent failure |
| `locally-verified` | `constructed` | independent verification plus final freshness, replay, and policy-stage evidence | rejection -> `permanent-failure`; consumed replay -> terminal `superseded` |
| `constructed` | `submitting` | canonical transaction body, submission id, funding and predecessor preflight | stale predecessor -> `retry-wait` with rebase; domain change -> `superseded` |
| `submitting` | `submitted` or `submission-unknown` | attempt, endpoint, body, and send-intent record persisted before submission | timeout -> `submission-unknown`; never build a replacement yet |
| `submission-unknown` | `submitted`, `confirmed`, `retry-wait`, or `manual-recovery` | transaction-id/body-digest queries under confirmation profile | replacement only after authoritative absence; ambiguity at deadline -> `manual-recovery` |
| `submitted` | `confirmed` or `submission-unknown` | transport acknowledgement as nonfinal evidence | watcher timeout -> `submission-unknown` |
| `confirmed` | `settled` | registered confirmation proof and independent reads of all four successor owners | observation conflict -> `manual-recovery`; rollback/reset -> profile rule |
| `settled` | none | application, value, and replay receipts plus final job record | terminal success |
| `retry-wait` | one enumerated retry target | failure code, owner, budget, backoff deadline, unchanged replay effect, and target selected from `FailureProfileV1.allowed_retry_targets` | unlisted target rejects; budget exhaustion -> `dead-letter`; resume repeats target preconditions |
| `permanent-failure` | none | stage, code, evidence, and `NO_CHANGE` owner digests | terminal; a new query creates a new job only if semantics change |
| `superseded` | none | winning settlement/domain record and no local state effect | terminal idempotent outcome |
| `dead-letter` or `manual-recovery` | `retry-wait` only through authorized job resume | complete evidence, replay effect, resume condition, and `JobResumeV1` | no automatic retry; compare-and-swap phase and sequence prevents dual resume |

`FailureProfileV1` maps every failure code to its validation stage,
permanent/retryable/manual class, owner, retry budget and backoff, replay effect,
and an ordered, exhaustive `allowed_retry_targets` set. No generic "recorded
target" escape exists. `JobResumeV1` is distinct from gate lifecycle
`GateResumeV1` and binds job id, settlement id, root context, prior job-record
digest and phase, failure code, selected allowed target, complete evidence,
resume policy and approvals, and expected/new job sequence. The client
persists phase and identifiers before every external side effect. After a timeout
or restart in `submission-unknown`, it queries by transaction id or body digest
before building a replacement. On-chain replay protection does not replace job
idempotency. Witness bundles are content-addressed and retained through the
evidence deadline before proving starts.

Resume uses compare-and-swap over the durable job phase and sequence. Restart
vectors cover every failure-profile target. Two-authorizer race vectors require
exactly one `JobResumeV1` to win; the loser observes the new sequence and causes
no proving, submission, replay, application, value, or gate effect.

A correlation id links the query, anchor, proof job, registry version, attempt,
destination transaction, confirmation, and consumed-message result. The artifact
resolver from section 8 preserves authorization across retries and redundant
locations.

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
private source relation may expose a nullifier. Domain-bound message ids and
nullifiers are supplemented by one proof-bound, domain-independent identity:

```text
SourceEventIdentityV1 = (
  version,
  source_chain_identity_digest,
  source_handler_or_namespace,
  source_transaction_or_object_id,
  source_action_or_event_index,
  event_discriminator,
  source_event_commitment
)

continuity_key = Digest(
  "mcb/continuity-key/v1",
  CanonicalEncode(SourceEventIdentityV1))
```

The finality, inclusion, and predicate relations authenticate every field. The
record contains no root-set digest, deployment domain, registry activation,
artifact authorization, destination instance, or destination replay key. A
private predicate may expose a hiding `source_event_commitment`, but its proof
must establish that it uniquely commits to the same source event that produced
the nullifier. Caller-supplied event identities never enter replay state.

The replay owner contains both the active-domain mode-specific tree and
`continuity_replay_root`, the authenticated set of consumed `continuity_key`
values. Each predicate registry record selects exactly one replay mode:

| Mode | Required keys | Atomic effect |
| --- | --- | --- |
| `message-id` | Canonical message id plus `continuity_key` | Check both unused and consume both atomically |
| `nullifier` | Canonical nullifier plus `continuity_key` | Check both unused and consume both atomically |
| `both` | Canonical message id, nullifier, and `continuity_key` | Check all unused and consume all atomically |

The replay scope binds root-set digest, deployment domain, registry activation,
artifact authorization root, destination ABI instance, destination network and
verifier or operation, source network and handler, lane, and predicate replay policy. A
caller nonce changes settlement identity only when registered predicate semantics
authorize that nonce. Reuse of `continuity_key` rejects in every replay mode.
Under `both`, reuse of any one key rejects without changing tracked, application,
value, or replay state. Golden vectors consume one event under each mode, derive
the same continuity key under a new domain, and require rejection; a distinct
source event with every new-domain field valid must pass.

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
follows this proof-binding rebase table:

| Observed change | Required action |
| --- | --- |
| Only replay state changed and the claim anchor remains current | Rebuild replay witness and transaction; reuse proof only if the binding matrix proves the changed state is not proof-bound |
| Source anchor advanced and the claim binds the old anchor | Refresh authenticated source data and regenerate every anchor-bound proof component |
| Exact predecessor was consumed but its successor represents the same anchor | Refresh predecessor and replay witnesses, then rebuild the transaction |
| Deployment domain or registered root changed | Terminate the old job; the proof cannot be rebased |
| Authenticated conflicting finality appeared | Freeze and enter manual recovery; no relayer selects a branch |

A rejected or interrupted attempt changes no tracked, application, value, or
replay state. The protocol fixes lane ordering, idempotency, retry and refund
rules, stuck-message handling, fee treatment, and per-asset conservation.

## 18. Destination validators

### Common ABI contract

Each destination publishes one versioned content-addressed
`DestinationAbiTemplateV1`. It contains the domain-neutral destination network
identity, transition and state schemas, verifier or operation template hash,
deployment recipe digest, references to the common-record and suite-native
schema/profile digests, chain-specific construction and runtime wrappers, size
and resource policy, receipt schema, and stable validation stage and error
mapping. It contains no deployment domain, root-set digest,
concrete deployed destination id, runtime state, transaction, or receipt.

Encoding ownership is disjoint. The common CBOR profile owns query, resolution,
claim, typed-result, submission, and receipt records. `SuiteNativeProofProfileV1`
is the sole owner of native proof, instance, VK, scalar/field, transcript,
curve/point, subgroup, and verifier-equation bytes. The destination ABI owns only
datum, redeemer, call, predecessor/successor, value, transaction, and receipt
wrapper bytes. It references the common and suite-native profile digests and
byte-preservingly embeds their values. Activation runs a schema walk that rejects
an ABI redefinition or normalization of any common or suite-native field. Golden
vectors include the complete nested common-record, native-payload, VK, and chain-
wrapper bytes.

After domain derivation, `DeploymentObservationV1` authenticates the confirmed
deployment transaction, concrete verifier or operation, deployed code hash, ABI
template, and deployment recipe under the destination confirmation profile.
`DestinationAbiInstanceV1` accepts its concrete fields only from that observation
and binds them to the root-set digest, domain, registry activation, and artifact
authorization root. Submission clients
and destination validators require the instance digest in each construction
payload and receipt and consume the same byte-level golden and mutation vectors.
A different template, instance, predecessor, proof, action, result, replay, or
successor rejects with no change to any of the four state owners: tracked source
state, destination application state, value movement, and replay state.

Chain-specific operation names, datum or redeemer shapes, confirmation depths,
fee responsibilities, and resource limits are not inferred. `S01-BLOCK-05` owns
the Midnight ABI and `S01-BLOCK-06` owns the Cardano ABI. The chain adapter and
destination owners publish each profile; submission construction and runtime
validation enforce it; activation requires independent codecs, construction and
execution receipts, all field mutations, resource-bound tests, and exact
predecessor/successor comparisons.

### Cardano validator

The Plutus V3 validator stores the accepted Midnight bootstrap digest, protocol
fingerprint, current and next BEEFY state, `RootContextV1`, and replay state in
its continuing output. It stores no proof-suite, circuit-architecture, VK, SRS,
setup, transcript, or curve-grammar selector. Those values exist only in the
per-claim authenticated `ResolvedProofContextV1`. The validator follows this
global order exactly:

1. strictly decode bounded state and common records, bind the exact roster and
   active `RootContextV1`, authenticate registry activation, resolve the query,
   and construct `ResolvedProofContextV1`;
2. decode and canonically re-encode the typed result under its resolved schema;
3. authorize the complete artifact graph and suite-native profile, parse their
   bounded native bytes, and reconstruct `claim_digest`, `pub`, and every public
   instance from the result, transaction outputs, and resolved claim fields;
4. verify the suite-native BSB22 PoK and Groth16 pairing under the resolved VK,
   rejecting invalid lengths, scalar aliases, identity points, off-curve or non-
   subgroup points, trailing bytes, and wrong endianness;
5. extract authenticated source time only from the verified proof statement;
6. perform final destination-context, expiry, freshness, replay, and policy
   checks over the same canonical result and proof-authenticated time;
7. enforce the exact predecessor and monotonic successor and commit tracked
   source state, destination application state, value state, and replay state in
   one atomic transition.

Freshness uses the transaction validity interval under the registered Cardano
destination-time profile, not an endpoint clock.

The verifier-key binding and public-input reconstruction follow the proven
Cardano pattern in the
[ZK recovery architecture](zk-recovery-architecture.md). The live recovery
validators show that BSB22 verification can fit on Preview; they do not implement
the bridge relation.

### Midnight operation

The Midnight operation stores the Cardano bootstrap digest, certificate state,
SCLS anchor, protocol fingerprint, `RootContextV1`, and replay state. It stores
no proof-suite, circuit-architecture, VK, SRS, setup, transcript, or curve-
grammar selector. For every claim it follows the same global order:

1. bind the roster and active root context, authenticate registry activation,
   resolve the query, and construct `ResolvedProofContextV1`;
2. decode and canonically re-encode the registered typed result;
3. authorize the complete artifact graph and suite-native profile, then
   reconstruct the registered public statement from that result and resolved
   claim fields;
4. verify the complete Halo2/Plonk relation under the resolved operation and VK;
5. extract source time only from the verified Cardano finality and SCLS
   statement;
6. perform final destination-context, expiry, freshness, replay, and policy
   checks over the same canonical result and proof-authenticated time;
7. commit the Cardano-state advance, application action, value movement, and
   replay update together.

The destination-time input is the consensus-backed interval exposed by the
registered operation, not a caller timestamp. Instrumented vectors require an
authorization failure to leave reconstruction and every later stage uninvoked,
and require a stale source time to reject only after successful proof
verification. A malformed external proof, unknown operation, stale certificate,
mixed SCLS root, or failed action records `NO_CHANGE` for all four owners.

The available Compact, ZKIR, and proof libraries do not prove this execution
surface exists on a public Midnight network. The deployed-operation prototype
required by `S01-BLOCK-05` must demonstrate valid and mutated submissions and
all-or-nothing state.

## 19. Relaying and data availability

Relayers have no authorization key. They obtain source data, maintain proof jobs,
transport envelopes and witnesses, submit destination transactions, and report
confirmation. Multiple relayers converge through the durable `settlement_id` and
destination replay state. Replay protection alone does not make job processing
idempotent. A relayer can delay service or withhold data, so liveness requires
redundant data sources, bounded queues, restart-safe persistence, chain query
before resubmission, and a clear replacement policy.

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

Every run binds one `OperationalProbeMetricProfileV1`:

```text
OperationalProbeMetricProfileV1 = (
  schema_version, profile_id, component_role_set,
  probe_discovery_schema_digest,
  health_probe_schema_digest, readiness_probe_schema_digest,
  status_mapping_table, unsafe_latch_and_recovery_rule,
  metrics_schema_digest, metric_definition_set_digest,
  correlation_and_redaction_rule, sampling_clock_rule,
  owner_and_verification_rule
)
```

The profile defines logical probe names and schemas, not concrete endpoints.
`RunIntentV1` binds its digest, the required component-role set, and all timeout,
sampling, staleness, and retry policy values before preflight. Each successful
`PreflightReceiptV1` binds that intent digest and one observed
`ProbeDiscoveryV1` per deployed component. That record supplies the component
instance, logical interface id, deployed transport and locator, access class,
observation time rule, and redacted configuration digest. No observed discovery
or result feeds the intent preimage.

The status mapping is fixed:

| Probe result | Health status | Readiness status | Required behavior |
| --- | --- | --- | --- |
| Valid healthy result and all required dependencies available | `healthy` | `ready` | Work may start or continue |
| Dependency timeout, transport failure, capacity exhaustion, or stale probe | `unavailable` | `not-ready-unavailable` | Stop new work, preserve safety state, and apply the registered retry policy |
| Verifier self-check failure, authenticated conflict, integrity failure, or latched unsafe state | `unsafe` | `not-ready-unsafe` | Stop proving and submission, preserve evidence, and enter manual recovery; authenticated source evidence follows section 20 freeze rules |
| Unknown, malformed, or unauthorized probe status | `unavailable` | `not-ready-unavailable` | Reject the observation and keep the component out of readiness |

An unavailable dependency is a liveness failure and never freezes a domain. An
unsafe result cannot be downgraded to unavailable by a transport failure or a
later process restart. Only the registered recovery rule clears the unsafe
latch. Unauthenticated fingerprint input still rejects without freeze.

Every structured event contains schema version, run and correlation ids, job
and attempt ids, settlement id when known, direction, deployment domain,
selected profile, durable phase, owner, failure code, evidence digest,
wall-clock timestamp, monotonic duration, and redaction status. The metrics
schema links every metric id to its unit, numeric type, bounded label schema,
collection interval, aggregation rule, and correlated event fields. Source lag,
certificate and anchor age, queue depth, proving latency and memory, retries,
confirmation, registry mismatch, replay conflicts, and conservation failures
use only registered metric definitions.

Every run also binds one `EvidenceRetentionProfileV1`:

```text
EvidenceRetentionProfileV1 = (
  schema_version, profile_id, evidence_class_rules,
  outcome_review_retention_rule, unresolved_gate_retention_rule,
  content_addressed_supersession_rule, expiry_evaluation_rule,
  storage_integrity_and_access_rule, owner_and_audit_rule
)
```

Deployment policy supplies the actual durations and deadlines for every evidence
class before the run begins. Credentials, secret handles, signing material, raw
private witnesses, and private transaction data are forbidden in events and
labels. The public evidence index records content hash, byte length, media type,
storage class, access procedure, retention deadline, profile digest, and
independent verification command for every external witness, artifact, raw
receipt, and log bundle.

Evidence required by outcome classification remains available through
classification and independent review. If any required item expires first, the
run classifies as `blocked`. Resume evidence for an unresolved gate remains
available until that gate is resolved or an accepted content-addressed
supersession record points to complete replacement evidence. If unresolved-gate
evidence expires without such supersession, that gate returns to `unresolved`
and dependent work stops.

## 20. Governance and upgrades

Within a proof-of-concept deployment domain, these roots are immutable:

- checkpoint digest and source/destination identities;
- finality adapter, anchor profile, and source-protocol fingerprint policy;
- proof-suite and artifact template graph;
- all VK and SRS template manifests and setup transcript hashes;
- semantic registry template root, registry activation, artifact authorization
  root, destination verifier or operation and ABI templates, deployment recipes,
  and destination ABI instances;
- replay-domain definition and recovery-policy hash.

Replacing any root, resetting a testnet, or changing an incompatible source
fingerprint creates a new deployment domain. Old-domain proofs must fail under
the new verifier. State-bearing cutover uses:

```text
DomainMigrationV1 = (
  version, old_root_context_digest, new_root_context_digest,
  old_activation_decision_digest, new_activation_decision_digest,
  old_final_tracked_state_digest, old_final_replay_state_digest,
  replay_import_root, application_state_import_root, value_state_import_root,
  old_continuity_replay_root, new_continuity_replay_root,
  continuity_leaf_count, continuity_export_manifest_digest,
  continuity_completeness_translation_proof_digest,
  import_proof_profile_digest, in_flight_job_disposition_digest,
  cutover_source_point, cutover_destination_interval,
  old_domain_shutdown_transaction, new_domain_import_transaction,
  migration_policy_digest, migration_sequence,
  proposal_time, delay_amount, delay_unit, delay_bounds_profile_digest,
  earliest_execution_time, execution_time,
  canonical_approval_set_digest
)
```

The old destination authenticates and freezes its final export roots; the new
destination verifies the registered import proofs, governance approval and
delay, both activation decisions, monotonic migration sequence, and one-time
cutover marker before it exposes imported state. The delay profile fixes a
consensus-backed time adapter, unit, unsigned width, and numeric bounds. Checked
arithmetic requires
`earliest_execution_time = proposal_time + delay_amount` and
`execution_time >= earliest_execution_time`; overflow, mixed units, an out-of-
bounds delay, or execution one unit early rejects. Equality passes.

The old domain rejects new settlement after the shutdown transaction. The
continuity proof authenticates `old_continuity_replay_root` as the complete
continuity root inside `old_final_replay_state_digest` and proves that every old
leaf is translated exactly once into `new_continuity_replay_root`, with the
declared count and canonical key encoding. Omission, insertion, duplication, or
substitution fails migration. When the tree and codec versions are unchanged,
translation is byte-preserving and the two roots must be equal. A fresh proof in
the new domain for an old event derives the same domain-independent
`continuity_key` and rejects even though its message id, nullifier, root context,
and other domain-bound values are new. Vectors prove this for `message-id`,
`nullifier`, and `both`; they also prove that an unrelated source event passes.
Other vectors cover a missing continuity leaf, changed application or value
root, duplicate import, overlapping cutovers, one-unit-early and exact-boundary
execution, field mutation after approval, and a race with an in-flight
settlement.

A destructive lab reset is a different record with `continuity_mode = none`.
It imports no replay, application, or value root; claims no asset or state
continuity; cancels every old job; and requires fresh lab funding and state
initialization. It cannot be used as a migration receipt or as evidence that
value survived the reset.

Safety state is explicit:

```text
ConsensusSafetyStateV1 =
  Active(active_root_set_digest)
  | Frozen(active_root_set_digest, freeze_reason_code,
           authenticated_evidence_digest, freeze_transition_id)
```

An untrusted unknown, downgraded, or mismatched fingerprint rejects without
changing this state. Source-evidence freeze requires one registered evidence
class: two threshold-valid BEEFY commitments with the same source-native conflict
key and different finalized results; two chain-valid Mithril certificates with
the same entity/beacon conflict key and different messages or transitions; or a
currently valid finality proof of an unauthorized source upgrade marker. Each
verifier first validates source identity, bootstrap root, fingerprint, domain,
and both objects, then computes the key and conflicting results. Stale, invalid,
normal-progress objects, governance signatures, and a recovery timer are not
source evidence and cannot trigger this transition.

A source-evidence freeze changes only safety state and records the evidence digest. It does not
roll back the anchor, apply an action, move value, consume replay state, replace a
root, or select a branch. While frozen, anchor advance and settlement reject.

Authorized delayed recovery starts only from a recorded frozen state and is a
governance action, not another freeze cause. `RecoveryAuthorizationV1` binds the
root context, freeze transition and source-evidence digest, allowed action,
recovery policy, proposal time, earliest execution time, approval threshold,
ordered approvals, recovery sequence, and any target-domain migration digest.
The destination checks the delay against consensus-backed time and executes it
once. `RecoveryRecordV1` binds the authorization, pre/post safety states, all four
pre/post state-owner digests, transaction, and independent observations. Same-
domain resume cannot change a root, fingerprint, adapter, verifier, registry,
ABI, freshness rule, or replay rule. Root replacement must use
`DomainMigrationV1`. Duplicate recovery sequences and losing same-block races
produce `NO_CHANGE` and cannot consume replay or move value.

Evidence lifecycle uses two canonical records. `EvidenceSupersessionV1` binds
roster digest, gate id, activation reference, old and replacement evidence
digests, reason, old deadline, proposal and effective times, retention-policy
digest, owner-policy digest, ordered approvals, and monotonic evidence sequence.
It preserves the old bytes and audit path. `GateResumeV1` binds the same roster
entry, current root context, prior gate-record digest and status, effective
evidence or supersession digest, dependent-gate snapshot, resume time, owner
policy, approvals, and expected/new gate sequence. The stable owners named in
the published roster and the preauthorized deployment-governance threshold must
both approve. Supersession cannot become effective after the old deadline unless
the gate first returns to `unresolved`. Resume occurs only after all replacement
evidence is authenticated and unexpired. Compare-and-swap on gate and evidence
sequence makes the first authorized destination transition win; stale, duplicate,
and competing records fail without changing gate, safety, or settlement state.

`CONS-FREEZE-01` is owned by the consensus, destination, governance, and
conformance owners. Destination safety-state transitions enforce its exact BEEFY
and Mithril conflict-key profiles. Activation requires arbitrary-mismatch
no-freeze, invalid-conflict, valid-progress, valid-conflict, cross-entity,
authenticated-upgrade, unauthenticated-upgrade, settlement-race, restart,
source-freeze versus governance-recovery separation, delayed authorization,
same-root resume, supersession/resume race, and `DomainMigrationV1` vectors plus
incident-retention receipts. Until the source-native conflict keys and validators
exist, no input may trigger freeze through an inferred rule.

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

`PerformancePolicyV1` fixes the metric ids, units, sample and warmup rules,
hardware disclosure, target-network parameter digest, percentile calculation,
maximum proof and transaction sizes, proving RAM and latency limits, destination
verification limits, fee limit, safety margin, and pass/fail comparison before a
run. `PerformanceThresholdReceiptV1` binds that policy, suite and architecture,
artifact hashes, run and hardware ids, raw-sample-set digest, computed metrics,
threshold decisions, and independent reproduction. The roster requires these
receipts for `S01-BLOCK-04/full-decider`,
`S01-BLOCK-05/midnight-execution`, and
`S01-BLOCK-06/cardano-execution`; an after-the-fact threshold or a verifier-only
measurement cannot satisfy them.

## 22. Conformance and security testing

Conformance uses independent encoders and public-statement reconstructors. They
must produce identical canonical bytes and field elements, then agree on positive
and negative outcomes. Each of the 94 recovered predicates requires a schema
check, provenance digest, registry round trip, positive vector, and all negative
vectors required by its template. Full catalog conformance is distinct from the
smaller live-testnet exercise set.

Every vector uses a machine-readable envelope:

```text
VectorV1 = (
  vector_id, direction, fixture_kind, selected_trust_profile,
  predicate_id_or_structural_test_only,
  deployment_trust_artifact_registry_suite_and_abi_digests,
  root_context,
  canonical_query_resolution_claim_response_and_field_digests,
  artifact_digests,
  predecessor_bridge_application_value_and_replay_state,
  proof_bytes_or_wrapper_witness,
  mutation_target_and_exact_operation,
  required_preconditions,
  expected_validation_stage,
  expected_failure_code,
  expected_successor_states_or_NO_CHANGE,
  required_capability_and_gate_ids,
  generator_and_runner_revisions,
  reproduction_command,
  independent_evidence_digests
)
```

The runner proves every prerequisite before `expected_validation_stage`. An
earlier rejection does not satisfy the vector. Positive vectors identify the
destination action and replay effect. Negative vectors compare all four state
owners. Two independent runners reproduce each applicable vector. Until the
catalog gate passes, no vector invents a predicate id or counts toward 42/52
coverage; non-catalog vectors are labeled `structural-test-only`.

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
tests inspect predecessor and successor tracked, application, value, and replay
state after each failure and require no change. A destination operation with no
value-bearing effect uses `ValueStateV1 = Absent(reason_code)` as an explicit
proof-bound owner; omission of the value owner is not permitted.

Source claims used by security decisions retain verbatim evidence and source
digests. Strict OpenSpec validation, source-pack gates, whitespace checks,
reference scans, clean builds, and reproducible deployment commands are part of
the evidence record. Passing document validation does not close a cryptographic
or public-network gate.

## 23. Testnet deployment

A deployment uses the root template, artifact template, activation, run-intent,
run-evidence, and private operator layers from section 6. The immutable public
`RunIntentV1` selects one Cardano and one Midnight endpoint policy and records
identities, root-set and domain values, registry activation, artifact
authorization, ABI instances, funded-role requirements, probe/metric,
confirmation, and evidence-retention profiles, and declared evidence locations.
It contains no preflight result. Secret references stay in the private overlay.
Preview and Preprod endpoints are available for both systems; a network name
alone is not a manifest.

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

The 2026-07-10 harness host pins PowerShell 7.6.3, Rust/Cargo 1.90.0, Go
1.25.7, Python 3.14.6, Node/npm 24.18.0/11.16.0, OpenSpec 1.5.0, Scrapling
0.4.10, and cbor2 5.7.1. The gnark 0.15.0 BSB22 harness passes its parser-only
Go tests. `midnight-aggregation` compiles, and its IVC example passes with the
exact features and SRS hashes recorded in sections 15 and 21.

A second same-day host capability probe records WSL2 Ubuntu-26.04 running and
Docker Engine 29.6.1 available inside that distribution. Windows PATH does not
require Docker. Midnight Compact, the Midnight proof server, `cardano-node`, and
`cardano-cli` are not found on Windows or in Ubuntu-26.04. Those tools remain
not ready until install, version, configuration, connectivity, and a minimal
functional probe pass. WSL2 and Docker availability are host facts only; they
are not Midnight or Cardano deployment readiness. The machine-readable receipt
is `reference/evidence/host-probes/host-capability-2026-07-10.json`.

At `2026-07-10T11:25:55Z`, a Scrapling capture sent byte-preserved
`chain_getFinalizedHead` and `chain_getHeader` requests to Midnight Preview. The
endpoint reported block 1,544,263, head
`0xf608d7d1fd83209d418e8ae83bd536f1a944230cd6b49fac1faa32e0c30343c2`,
and state root
`0xf68d19871a298531a35f552b50553aa3b0377cfb4484eeb2fac062210d2d6158`.
The record labels finality, event inclusion, and destination execution as
`not-performed` and leaves only `S01-BLOCK-03/event-inclusion` unresolved. The
RPC method name does not turn the response into independently checked finality.

At `2026-07-10T11:26:03Z`, the official Mithril pre-release Preview aggregator
returned 20 certificates whose endpoint-supplied entity type names were
`CardanoDatabase` and `CardanoTransactions`. The adapter does not infer SCLS from
those strings. It records `scls_profile_evaluation=not-performed` and leaves only
`S01-BLOCK-02/public-scls-availability` unresolved. Both captures are unsigned
transport evidence. They are not approved checkpoints, do not establish
independent-node agreement, and cannot authorize a deployment.

### Endpoint and preflight contract

The Cardano `PreflightReceiptV1` records the immutable run-intent digest,
endpoint id, public URL or redacted local socket descriptor, network magic,
cryptographic genesis identity, node or API implementation and revision,
supported query and submission interfaces, chain-sync observation, endpoint
provenance, preflight time, transport profile, non-secret command, checks and
results, and evidence digest. The Midnight receipt uses the same common fields
plus the registered RPC and indexer roles. Credentials and secret handles remain
in the operator overlay.

Exact endpoint values and commands are deployment outputs. The operator owner
publishes them as content-addressed run evidence; preflight tooling enforces them
before source collection or submission; vectors cover wrong network/genesis,
stale or unsynced endpoints, revision mismatch, missing interface, credential
redaction, and restart; a run activates only when both endpoint profiles and
preflight receipts pass. `RunIntentV1` binds
`OperationalProbeMetricProfileV1`, `EvidenceRetentionProfileV1`, required
logical probe roles, and concrete policy durations before preflight.
`PreflightReceiptV1` binds the observed `ProbeDiscoveryV1` records and results;
`RunEvidenceManifestV1` lists the receipts. Preflight rejects missing discovery
values, schema digests, or a receipt whose intent digest differs.

Every preflight, job, proof, transaction, confirmation, and outcome receipt
binds `run_intent_digest`. Mutating any intent field invalidates every receipt.
The schema DAG has only `RunIntentV1 -> PreflightReceiptV1 ->
RunEvidenceManifestV1`; neither receipt nor evidence-manifest digest is reachable
from the intent preimage. A mechanical DAG vector rejects either back edge.

### Transaction construction, confirmation, and receipts

Cardano and Midnight submission clients own chain-specific construction,
submission-unknown recovery, confirmation tracking, and receipt emission. A
transport acknowledgement does not prove inclusion or state change. Every
receipt binds:

| Field group | Required evidence |
| --- | --- |
| Run identity | Schema version, run and correlation ids, direction, selected profile, and deployment domain |
| Root identity | Root-set digest, domain, root template, artifact template, activation, run-intent, and run-evidence-manifest digests plus registry activation and artifact authorization roots |
| Claim identity | Canonical query and claim digests, predicate id, suite id, and replay keys |
| Transaction identity | Destination identity, transaction id, and canonical body digest |
| Confirmation | Profile id and digest, inclusion point, observations, endpoint ids, and times |
| Authorization | Destination ABI instance, verifier or operation instance, registry activation, and artifact authorization digests |
| Atomic result | Predecessor and successor tracked/application/value/replay digests and action result |
| Cost | Fee and measured resource record |
| Reproduction | Raw receipt digest, evidence location, independent query command and revision, and result |

The Cardano extension records network magic and genesis, containing block hash
and slot, consumed and produced bridge-state output references, validator hash,
datum, redeemer, and reference-input artifact digests, declared and measured
execution units, value-conservation result, and every observation required by the
registered Cardano confirmation profile.

The Midnight extension records network, genesis, and chain-spec identity,
transaction id and finalized block number and hash, deployed contract, program,
and operation identifiers exposed by the accepted execution-surface profile,
predecessor and successor public-state or event digests, the proof or receipt
needed for a finalized-state query, and every observation required by the
registered Midnight confirmation profile.

Submitted, accepted by one RPC, present in a mempool, or returned by an indexer is
not confirmed. Confirmation requires the chain-specific profile and independent
reads of successor application and replay state. A timeout after submission enters
`submission-unknown`; the client queries by transaction id or body digest before
replacement. Restart, duplicate submission, Cardano rollback, and Midnight reset
drills must produce deterministic terminal evidence and at most one authorized
state transition.

The exact Cardano stability rule and the exact Midnight finalized-execution query
are unavailable. Each is a `GateDeliverableV1` confirmation-profile slot whose
owners are copied exactly from its roster entry. Chain-adapter and confirmation-
profile teams are contributors; chain clients and evidence verifiers are
enforcement loci. Activation requires source-backed rules,
independent query implementations, boundary, timeout, restart, duplicate, and
rollback/reset vectors, and confirmed golden receipts. No confirmation depth or
operation/query name is inferred.

### Deterministic outcome

The sole authoritative `GateRosterV1` is
[`protocol/gate-roster-v1.json`](../../protocol/gate-roster-v1.json). Its roster
member has RFC 8949 deterministic-CBOR SHA-256
`2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f`;
the byte-exact hexadecimal encoding is published beside it. It contains exactly
the six `S01-BLOCK-*` entries and eight `CONS-*` entries. Stable owner,
interface, evidence, and activation ids in that artifact are protocol values.
This document does not restate or relabel them. `RunIntentV1` binds those
bytes and digest before preflight, endpoint discovery, source collection, witness
construction, or proving. Every listed key must occur exactly once and no
unlisted key is accepted.

`public-only` is the only allowed lab applicability for the public SCLS facet. It
keeps that public dependency in the production-gap record without requiring it
for a lab result. It is not `not-applicable`. All other roster entries are
required in both profiles. In particular, `S01-BLOCK-01` is required for lab,
and a lab root must still pass real certificate-to-SCLS mechanics under
`CONS-CARDANO-01`. A lab run may replace only the named public source root. It
may not mock a proof relation, verifier, transaction, transition, or receipt.

`OutcomeClassifierV1` validates the exact roster before any outcome condition.
It compares roster version and digest, the complete key set, uniqueness, owners,
interfaces, applicability, evidence schemas, activation references, gate status,
evidence digests, retention validity, and selected profile. It then selects the
first matching row and stops:

| First-match row | Condition | Result |
| ---: | --- | --- |
| 1 | Roster or gate record is invalid, missing, duplicate, unknown, or uses unauthorized `not-applicable`; required outcome evidence is missing or expired | `blocked` |
| 2 | Any selected-profile required gate status is not `passed`, including `unresolved`, `failed`, `mocked`, or evidence returned to unresolved after expiry | `blocked` |
| 3 | Either proof direction lacks a real destination transition confirmed under its registered profile and independently read successor state | `blocked` |
| 4 | Selected profile is `lab` | `degraded-lab` |
| 5 | Selected profile is `public` | `live-pass` |

Exactly one row is selected because evaluation stops at the first match. Later
conditions may also be true and are not evaluated. The outcome record binds
classifier version, roster digest, run id, profile, ordered gate records,
evidence-retention profile, both direction receipts, selected row, and label.

Classifier vectors include an overlapping bad-roster plus missing-transition
case that selects row 1, a mocked lab gate that selects row 2, a lab run with
only the named root substitution, real certificate-to-SCLS mechanics, and two
real confirmed transitions that selects row 4, a complete public run that
selects row 5, and missing, duplicate, unknown, and unauthorized
`not-applicable` roster cases that select row 1. Evidence-expiry vectors prove
that required outcome evidence yields `blocked` and expired unresolved-gate
evidence returns the gate to `unresolved` before classification.

No current probe is evidence of `live-pass`.

## 24. Production path and residual risks

Six dependencies define the present implementation boundary:

| Gate | Missing evidence | Effect |
| --- | --- | --- |
| `S01-BLOCK-01/catalog-completeness` | Source-backed 42 Cardano and 52 Midnight catalogs with exact count, uniqueness, schema, and provenance | Blocks registry population and 94-row conformance |
| `S01-BLOCK-02/public-scls-availability` | Accepted public Mithril signer population for the exact SCLS entity and public availability receipts | Blocks only the public Cardano anchor; real certificate-to-SCLS mechanics remain required for lab under `CONS-CARDANO-01` |
| `S01-BLOCK-03/event-inclusion` | Content-addressed event-to-header-to-MMR profile and rejecting prototype | Blocks the `event_inclusion` terminal role |
| `S01-BLOCK-04/full-decider` | Content-addressed native/circuit full-decider profile, complete equations, and final-KZG negative | Blocks selected Midnight-to-Cardano proof path |
| `S01-BLOCK-05/midnight-execution` | Deployed Midnight registered-operation ABI, external bridge proof, mutations, and atomic receipts | Blocks selected Cardano-to-Midnight execution surface |
| `S01-BLOCK-06/cardano-execution` | Versioned Cardano ABI and reference Plutus boundary for the complete wrapped BEEFY/MMR claim | Blocks Cardano settlement and receipt evidence |

### Activation artifact ledger

The activation ledger is the ordered gate-record set whose keys and contract
fields come directly from `protocol/gate-roster-v1.json`. Each
`GateDeliverableV1` uses the roster's exact stable owner ids, affected-interface
ids, evidence ids, applicability, and activation reference; prose cannot add a
label or substitute an owner. `ActivationDecisionV1` binds the published roster
digest and the digest of this ordered record set. Bridge hash and common-CBOR
vectors, aggregation profiles, destination confirmation profiles, and deployment
manifests are required evidence under the roster entry that names their
interface, not extra gates.

An activation record fails closed if the owner, pinned source or recorded source
absence, canonical bytes, enforcement test, vector bundle, or independent receipt
is missing. Concrete Poseidon parameters, Halo2/KZG equations, operation names,
network roots, chain constants, confirmation depths, funding amounts, and
predicate rows are never filled from assumptions.

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

### A. BSB22 suite-native grammar and Cardano embedding

The registered `SuiteNativeProofProfileV1` uses one destination-derived public
scalar `pub`, a 336-byte proof, and a 672-byte committed VK
([commitment Groth16](../proof-systems/commitment-groth16.md)):

```text
proof = A:G1_compressed[48]
     || B:G2_compressed[96]
     || C:G1_compressed[48]
     || D:G1_uncompressed[96]
     || PoK:G1_compressed[48]

pub_bytes = CanonicalLE32(claim_digest)
OS2IP_LE(pub_bytes) < r
pub = OS2IP_LE(pub_bytes)

eCmt = OS2IP_BE(
  expand_message_xmd(SHA-256, D_uncompressed, "bsb22-commitment", 48)
) mod Fr

vkX = IC0 + pub * IC1 + eCmt * K2 + D
```

`pub_bytes` is exactly 32 bytes and is reconstructed by the destination. Any
decoded representation greater than or equal to the BLS12-381 scalar modulus
`r` is rejected; caller aliases are not reduced modulo `r`.

The committed VK uses the evidenced ZCash/IETF compressed-point encoding family
and this exact grammar:

| Offset | Length | Field | Type and role |
| ---: | ---: | --- | --- |
| 0 | 48 | `alpha` | G1, Groth16 alpha |
| 48 | 96 | `beta` | G2, Groth16 beta |
| 144 | 96 | `gamma` | G2, Groth16 gamma |
| 240 | 96 | `delta` | G2, Groth16 delta |
| 336 | 48 | `IC0` | G1, constant public-input term |
| 384 | 48 | `IC1` | G1, `pub` term |
| 432 | 48 | `K2` | G1, committed-wire term |
| 480 | 96 | `CK.G` | G2, Pedersen commitment base |
| 576 | 96 | `CK.GSigmaNeg` | G2, negated sigma key |

The 432-byte vanilla prefix is followed by `K2`, `CK.G`, and
`CK.GSigmaNeg`. The parser consumes all 672 bytes in this order.

Both checks are mandatory:

```text
e(D, CK.GSigmaNeg) * e(PoK, CK.G) == 1
e(A, B) == e(alpha, beta) * e(vkX, gamma) * e(C, delta)
```

The verifier recomputes `eCmt` from the exact 96 uncompressed `D` bytes. It
rejects a caller-supplied challenge, compressed `D`, identity points,
noncanonical points, off-curve or non-subgroup points, wrong lengths, and trailing
bytes.

The content-addressed BSB22 suite-native profile pins the reference source
commit, proof, instance, VK and scalar grammar, exact coordinate endianness and
flag/sign conventions, unique infinity encoding, canonical curve and subgroup
checks, transcripts, equations, and independent golden and malformed vectors.
It also binds the section 15 committed-wire manifest to the wrapper R1CS and
phase-2 transcript. The Cardano ABI references that profile digest and embeds
`pub`, proof, and VK bytes without reinterpretation; it owns only datum,
redeemer, continuing-output, value, transaction, and receipt wrappers. The known
native grammar above is not deferred; activation is deferred only until the
complete parser, wire-map, setup, and vector profile is accepted.

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
