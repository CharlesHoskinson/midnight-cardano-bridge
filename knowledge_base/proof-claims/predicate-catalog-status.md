---
type: Status
title: Predicate catalog status
timestamp: '2026-07-10T07:15:32Z'
status: blocked
okf_version: '1.0'
---

# Predicate catalog status

The predicate registry requires exactly 42 Cardano records and 52 Midnight
records. The three recorded source files are missing, so registry population and
94-record conformance are blocked. The counts define the catalog contract; they
do not reveal predicate meanings and cannot be used to reconstruct rows.

This status applies to the [canonical 25-section bridge design](../bridges/midnight-cardano-recursive-bridge.md),
the [council-reviewed program design](../../docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md),
and the active OpenSpec
[predicate-registry requirement](../../openspec/changes/sprint-01-foundation/specs/predicate-registry/spec.md).

## Required catalog

| Source chain | Required unique records | Current source status |
| --- | ---: | --- |
| Cardano | 42 | Source catalog not recovered; no rows accepted |
| Midnight | 52 | Source catalog not recovered; no rows accepted |
| Total | 94 | Hard gate blocked |

The missing filenames are exact:

- `verified-claim-catalog-42.md`
- `midnight-proof-claim-catalog-52.md`
- `cardano-prior-epoch-zk-proof-categories.md`

The repository contains derived claim-interface material, including
[`claim-interface-schema.md`](claim-interface-schema.md), but it does not contain
the source catalogs. Derived examples, known namespaces, or candidate anchor
families do not identify the missing predicate statements.

## Search record

Exhaustive filename and distinctive-phrase searches covered these local roots:

- `C:\Users\charl`
- `C:\proofcategories`
- `C:\proof-zk-recovery`

None of the three filenames was found. On 2026-07-10, authenticated GitHub code
search also covered public and private repositories visible to the active
`CharlesHoskinson` account. It used the three exact filename queries, the phrases
`"verified claim catalog" Cardano` and `"Midnight proof claim catalog"`, and
account-scoped combinations of `predicate_id`, `bridge_message_finalized`,
`proof claim` plus Midnight, and `prior epoch` plus Cardano. No result appeared
before the GitHub search API reached its short-window rate limit.

This search record establishes where and how recovery was attempted. It does not
prove that the files do not exist elsewhere.

## Required row fields

Every recovered or source-backed reconstructed row must contain the following
information. The machine-readable schema may refine field spelling and types,
but it may not omit any item in this contract.

| Field group | Required content |
| --- | --- |
| Identity | Predicate id and version; source chain; source namespace; applicable ledger era, runtime, or state version |
| Statement | Natural-language statement; formal statement; bounded public inputs; typed outputs; private witness |
| Source anchor | Accepted anchor type; finality rule and parameters; freshness rule; source protocol fingerprint policy; the public ledger source authenticated by a Midnight row |
| Proof artifacts | Proof-template family; proof-suite id; circuit-architecture hash; complete inner, aggregation, wrapper, or operation VK graph; KZG SRS and Groth16 setup manifests where applicable |
| Schemas and selectors | Statement-schema hash; result-schema hash; proof-bound selector; parameter hash |
| Destination policy | Destination context requirements; expiry behavior; replay scope and consumption behavior; deployment-domain constraints |
| Tests and use | Positive vector; every negative vector required by the template; cross-predicate substitution coverage; example proof-enforced transaction use |
| Provenance and state | Primary-source locators and digests; per-row provenance digest; implementation status |

## Mechanical admission gates

One validator run must apply all four gates to the same canonical catalog bytes:

1. **Count:** exactly 42 Cardano records, exactly 52 Midnight records, and
   exactly 94 records in the combined catalog.
2. **Uniqueness:** no duplicate predicate id or predicate id and version key in
   either source catalog or the combined registry input.
3. **Schema:** every row has all required fields, valid bounded types, recognized
   enum values, and internally consistent schema, suite, architecture, selector,
   anchor, and destination references.
4. **Provenance:** every row has a provenance digest that resolves to recovered
   source bytes or a source-backed reconstruction record with primary or
   verbatim-gated evidence.

A failure in any gate stops registry population. After admission, each of the 94
records must also pass registry round-trip, a positive vector, its required
negative vectors, and cross-predicate substitution checks. A passing catalog
validator is necessary but does not by itself prove a circuit or deployment.

## No filler rows

No row may be invented, duplicated, renamed, or split to satisfy a count. The
numbers 42 and 52, a list of namespaces, a proof-template family, or a plausible
application claim is not row-level source evidence. Source-backed reconstruction
is allowed only one record at a time, with the complete field contract and
provenance needed to reproduce that record.

## Predicate records, template families, and live tests

A predicate record defines application semantics. A proof-template family defines
a reusable circuit shape. Several predicate records may use one constrained
template selector or one authorized aggregation relation, but every predicate
still keeps its own statement, schemas, anchor policy, provenance, registry
entry, and vectors. Template reuse can reduce the number of circuits and setup
ceremonies; it cannot reduce the required record count.

Full catalog conformance covers all 94 records. The reference harness must run a
complete local query-to-settlement flow for every proof-template family. The
live-testnet subset is recorded separately by predicate id and version, template
family, network, trust profile, deployment domain, and public receipt. It may be
smaller than the full catalog, but it cannot replace catalog admission,
per-predicate conformance, or local per-family execution. Fixture or
project-operated roots belong to the lab subset and cannot be reported as public
`live-pass` evidence.

## Current disposition

`S01-BLOCK-01` remains open. Recovery can resume from an original catalog file or
from a per-row, source-backed reconstruction procedure. Until the count,
uniqueness, schema, and provenance gates pass together, the registry stays empty
and no claim of complete predicate coverage is valid.
