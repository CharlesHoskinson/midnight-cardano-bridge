# bootstrap-trust Specification

## Purpose
TBD - created by archiving change sprint-01-foundation. Update Purpose after archive.
## Requirements
### Requirement: Deployment-bound checkpoint
Checkpoint bootstrap SHALL be an explicit weak-subjectivity trust profile whose deployed verifier binds the complete approved domain-neutral checkpoint-manifest digest, source identity and protocol fingerprint, destination network, and the separately derived `RootContextV1` and deployment domain. The checkpoint profile SHALL define its approver keys and threshold, independent-node reproduction rule, finalized-point agreement rule, maximum age and lag, derivation procedure, and signature algorithm. The body, approvals, and manifest SHALL NOT contain the root-set digest, deployment domain, a value derived from either, a domain-bound activation or authorization, a concrete deployed destination instance, runtime state, or a receipt. A stale, mismatched, under-approved, alternate-checkpoint, or cross-domain proof SHALL be rejected, and replacement of a checkpoint SHALL create a new deployment domain rather than rewrite the active proof-of-concept trust root.

#### Scenario: A proof from another checkpoint or deployment domain is rejected
- **WHEN** a proof is valid relative to a checkpoint-manifest digest or deployment domain other than the values bound by the deployed verifier
- **THEN** verification SHALL reject the proof before any tracked consensus, application, or replay state changes

### Requirement: Distinct Mithril bootstrap terminals
A deployment SHALL select exactly one versioned Mithril genesis or certificate-checkpoint rule profile and one domain-neutral bootstrap template. Genesis mode SHALL terminate at the independently provisioned Mithril genesis verification key and verify the full certificate chain and terminal signature. Checkpoint mode SHALL terminate at the approved terminal certificate hash, epoch, signed-entity type, current and next AVKs, and current and next protocol parameters, and SHALL verify only post-checkpoint linkage. It SHALL NOT report omitted history as genesis-verified unless a separately registered proof establishes that result. The rule profile and bootstrap template SHALL feed the checkpoint body and deployment root set without containing either derived digest. After domain derivation, the recursive base SHALL bind the checkpoint manifest, source fingerprint, registry activation, artifact authorization root, ABI instance, root-set digest, and domain through `RootContextV1`.

#### Scenario: A checkpoint chain cannot claim a genesis terminal
- **WHEN** a certificate sequence begins from an approved certificate checkpoint but reports verification from the Mithril genesis key
- **THEN** proof verification and evidence reporting SHALL reject the result

### Requirement: Recursive base reconstructs complete checkpoint state
`BaseStateEqualityV1` SHALL map every `CardanoSourceState` field outside `RootContextV1` to the approved checkpoint body's Mithril terminal profile/instance, certificate hash, epoch, current/next AVKs and parameters, and SCLS slot, namespace-set hash, root, and artifact digest. It SHALL map every `MidnightSourceState` field outside `RootContextV1` to the approved identity, finalized block number/id, MMR root, current/next BEEFY descriptors, and complete mandatory-handoff state. The recursive base SHALL reconstruct and compare every field before accepting `S0`; binding only the manifest digest or root context SHALL be insufficient. Two independent body decoders SHALL reproduce the positive base state.

#### Scenario: A non-root base field is changed
- **WHEN** the approved manifest, root set, domain, and `RootContextV1` are held fixed while any mapped Cardano or Midnight base field is mutated
- **THEN** the base relation SHALL reject at `recursive-base-manifest-state-equality` before any recursive step

### Requirement: Nonrecursive checkpoint approval
Checkpoint approvals SHALL sign the domain-separated digest of a canonical unsigned body under a preauthorized approval policy. The body SHALL bind source and destination identity templates, bootstrap template, source fingerprint, finalized point, authenticated anchor, complete current and next consensus descriptors, pending handoff state, semantic registry template root, artifact template root, ABI template digest, destination verifier or operation template hash, deployment recipe digest, replay, freshness, recovery and approval policy templates, fresh deployment instance id, derivation evidence, eligibility evidence, and cutoff time. Every value reachable from the body SHALL be domain neutral. The body SHALL exclude its own digest, approvals, approval-set digest, manifest digest, root-set digest, deployment domain, registry activation, artifact authorization, destination ABI instance, concrete deployed destination identity, runtime payload, and receipt. The final manifest digest SHALL derive from the approval-policy digest, body digest, and canonical approval-set digest without self-reference. Duplicate approver keys SHALL be rejected and count at most once. At least two independently administered nodes SHALL reproduce byte-identical derivable body fields before approval, and source-specific eligibility SHALL pass.

#### Scenario: Self-selected approvers cannot authorize a checkpoint
- **WHEN** a checkpoint body names an approval policy or key set other than the deployment's preauthorized policy
- **THEN** checkpoint approval and deployment SHALL reject even if those self-selected signatures satisfy the body

#### Scenario: An approval cannot cover a changed body
- **WHEN** any identity, consensus, anchor, freshness, recovery, artifact-template, semantic-registry-template, ABI-template, destination-code-template, deployment-recipe, or deployment-instance field differs from the signed body
- **THEN** that approval SHALL not count toward threshold

#### Scenario: A post-domain value is inserted into a checkpoint
- **WHEN** a checkpoint body or transitive referenced record contains a root-set digest, deployment domain, registry activation, artifact authorization, ABI instance, concrete runtime identity, or receipt
- **THEN** canonical checkpoint validation SHALL reject it before approval or root-set derivation

### Requirement: Authenticated freshness inputs
Checkpoint and claim freshness SHALL use authenticated source time `S` and a consensus-backed destination execution interval `[D_min,D_max]` under a domain-bound numeric policy. Checked bounded arithmetic SHALL require `D_min <= D_max`, `D_max - D_min <= max_destination_interval_width`, `S <= D_min + max_future_skew`, `D_max <= S + max_anchor_age`, and `D_max <= claim_expiry`. Equality at a boundary SHALL pass and arithmetic overflow, one-unit excess, ambiguous era conversion, missing authenticated time, or a caller timestamp SHALL reject. Unauthenticated endpoint tips and wall clocks SHALL be telemetry only.

Registry resolution SHALL bind the exact source/destination time adapter digests, units, conversion, unsigned width, inclusive-boundary rule, era schedule, and all numeric bounds in `ResolvedProofContextV1`. Final freshness SHALL run after proof verification authenticates `S`; preflight age checks SHALL be advisory only.

#### Scenario: RPC agreement cannot satisfy cryptographic freshness
- **WHEN** endpoints agree on a recent source tip but the proof does not authenticate the source time required by its profile
- **THEN** the destination SHALL reject without treating endpoint agreement as a trust root
