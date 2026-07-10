## Context

Sprint 1 published the root, claim, roster, replay, proof-byte, and outcome
contracts but intentionally left six source/proof/execution gates open. The
repository has no implementation directories. The current Windows host has Rust
1.90, Go 1.25.7, Python with Scrapling 0.4.10, and Cardano 11.0.1 tools. Compact
and the Midnight proof server cannot run because the required WSL component and
Docker are unavailable.

This change creates an executable reference layer around contracts that do not
depend on the missing predicate catalogs, proof circuits, or destination ABIs.
It produces reproducible structural evidence and unsigned source observations,
not a bridge deployment.

## Goals / Non-Goals

**Goals:**

- Reproduce the canonical roster, root/domain, continuity, and classifier values
  independently in Rust and Go.
- Exercise the BSB22 byte grammar and scalar boundary without claiming proof
  verification.
- Collect Midnight and Mithril observations only through Scrapling and preserve
  their unsigned provenance.
- Provide one command that fails closed on cross-language disagreement and keeps
  the deployment classifier blocked.

**Non-Goals:**

- Recovering or fabricating the missing 42/52 predicate catalogs.
- Implementing Mithril/SCLS or BEEFY/MMR proof circuits.
- Implementing the Halo2/KZG full decider, BSB22 proving, or pairing verification.
- Deploying a Midnight operation or Cardano validator.
- Closing any `S01-BLOCK-*` gate or assigning `degraded-lab` or `live-pass`.

## Decisions

### 1. Two small implementations share fixtures, not libraries

Rust lives under `reference/rust/` and Go under `reference/go/`. Each implements
the deterministic-CBOR subset needed for JSON objects containing strings,
nonnegative integers, arrays, and maps. They share only files under
`reference/fixtures/`. This makes byte agreement independent enough to catch
ordering, length, and domain-separator mistakes. Using one FFI library was
rejected because it would test one implementation twice.

### 2. Structural domain hashes are explicitly non-activating

`mcb.structural-lab.sha256-cbor.v1` uses deterministic CBOR and SHA-256 with the
canonical design's domain strings. Results always carry
`activation_eligible=false`. This tests the acyclic dependency order and reset
behavior while `CONS-DOMAIN-01` remains the authority for a production profile.
Using an unlabeled provisional hash was rejected because its output could be
mistaken for an approved deployment root.

### 3. One fixture envelope owns cross-language expectations

`reference/fixtures/structural-v1.json` contains roster paths, a bounded
domain-neutral root-set object, a source-event identity, a reset mutation, gate
statuses, and expected digests. Both commands emit one normalized JSON report.
`scripts/verify-reference-harness.ps1` compares the reports as parsed JSON rather
than terminal text.

### 4. Go owns only the executable BSB22 parser in this slice

The Go package exposes proof and VK slices at the accepted offsets and checks a
canonical little-endian scalar against the BLS12-381 Fr modulus. It performs no
curve decoding, subgroup check, pairing, or decider verification. This narrow
boundary matches available evidence and keeps `S01-BLOCK-04` and
`S01-BLOCK-06` unresolved.

### 5. Scrapling is the only public endpoint client

`reference/observers/observe.py` uses `scrapling.fetchers.Fetcher` for GET/POST
requests. Adapter normalization is separate from transport so `unittest` can use
captured raw fixtures without network access. Every record uses
`trust=unsigned-observation`; the parser rejects any other value. Rust and Go do
not fetch public endpoints in this change.

### 6. Structural and deployment outcomes are different fields

The conformance report contains `structural_result` and `deployment_outcome`.
The first may pass. The second is produced by the exact roster classifier and
must remain `blocked` because execution gates and confirmed destination receipts
are absent. No command accepts an override that turns structural evidence into
an outcome label.

### 7. Structural inputs use closed schemas and an explicit producer graph

The fixture carries a closed `StructuralDeploymentRootSetV1`, closed
`SourceEventIdentityV1` values, and a typed producer graph outside the root-set
preimage. Every root member names one graph producer. Validation rejects unknown
root or event fields, unknown graph stages, duplicate nodes, unresolved
dependencies, cycles, non-forward edges, and any reachable post-domain producer.
A field-name blacklist is insufficient because aliases and nested records can
hide a post-domain dependency.

### 8. Structural hash framing is byte-exact and non-production

Every structural digest uses
`u64_be(domain_byte_length) || UTF8(domain) || u64_be(body_byte_length) || body`.
Rust and Go emit the canonical body and full preimage as lowercase hex before
comparing digests. Digest-like fixture members remain lowercase hexadecimal text
inside this diagnostic profile; production typed bytes and the production hash
profile remain owned by `CONS-DOMAIN-01`.

### 9. Captures preserve transport bytes but confer no trust

Observation fixtures are immutable envelopes containing the exact request and
response body bytes, HTTP statuses, endpoint metadata, time, adapter revision,
digests, and fixed unsigned trust label. Normalization starts only after envelope
validation recomputes the digests and parses the preserved bytes. Closed output
schemas reject positive finality, SCLS, inclusion, proof, or execution claims.
The adapters report endpoint-supplied entity names without interpreting them.

### 10. Verification stages evidence and classifies explicit records

The base fixture supplies 14 ordered gate statuses, selected profile,
evidence-retention decisions, and two direction-receipt states. The harness joins
those inputs to the exact roster and applies the five classifier rows in order;
the base vector selects row 2. The combined verifier writes candidates to a
temporary run directory and emits no pass or deployment label until every check
succeeds. Default verification is offline and read-only. An explicit evidence
update atomically publishes reports only after a complete pass, with deterministic
input, verifier, command, and tool-version bindings.

## Risks / Trade-offs

- [The custom CBOR subset diverges from full RFC 8949] -> Reject unsupported JSON
  types and compare against the published roster bytes plus cross-language golden
  vectors.
- [A structural hash is mistaken for an activation root] -> Carry the profile id
  and `activation_eligible=false` in every output and reject activation requests.
- [Public endpoints change or become unavailable] -> Keep transport failures
  explicit and test normalization from dated captured fixtures.
- [A zero-filled BSB22 fixture appears cryptographically valid] -> Name it
  `structural-only`, expose parser checks separately, and keep proof gates open.
- [Rust dependency retrieval is unavailable] -> Limit crates to `serde`,
  `serde_json`, `sha2`, and `hex`; retain `Cargo.lock` after a verified build.
- [A prior pass report survives a later failed run] -> Treat committed reports
  as input-bound golden evidence, stage each current run outside the repository,
  and publish only after all checks pass.
- [An endpoint invents an SCLS-looking entity name] -> Preserve the reported
  string without semantic interpretation and reject all positive trust fields.

## Migration Plan

1. Land the OpenSpec artifacts and implementation plan.
2. Add failing Rust tests, then implement roster, structural root/domain,
   continuity, and classifier commands.
3. Add failing Go tests, then implement an independent encoder and BSB22 parser.
4. Add failing Python `unittest` fixtures, then implement Scrapling transport and
   normalization over byte-preserving capture envelopes.
5. Add negative schema, DAG, replay, classifier, proof-offset, scalar-boundary,
   capture-tamper, and late-verifier-failure vectors.
6. Run the offline combined verifier, atomically preserve input-bound reports,
   and review the implementation.

Rollback removes `reference/`, the verification script, and this active change;
it does not alter the stable Sprint 1 contracts or any chain state.

## Open Questions

- Exact production hash-to-field and destination ABI profiles remain outputs of
  their named gates, not decisions in this change.
- Live transaction submission waits for the Midnight and Cardano execution gates.
