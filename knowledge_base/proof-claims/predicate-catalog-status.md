---
type: Status
title: Predicate catalog status
timestamp: '2026-07-11T04:03:12Z'
status: blocked
okf_version: '1.0'
---

# Predicate catalog status

The predicate registry requires exactly 42 Cardano records and 52 Midnight
records. The three recorded source files are missing, so registry population and
94-record conformance are blocked. The counts define the catalog contract; they
do not reveal predicate meanings and cannot be used to reconstruct rows.

This status applies to the [canonical 25-section bridge design](../bridges/midnight-cardano-recursive-bridge.md),
the [public-testnet program design](../../docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md),
and the [106-package execution plan](../../docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md).

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

## Recovery row contract

PBT-S03-W01 through W05 recover source semantics and provenance. A recovered or
source-backed reconstructed row contains only information attributable to its
source. The machine-readable schema may refine field spelling and types, but it
may not omit these fields or add an admission decision to the canonical row.

| Field group | Required content |
| --- | --- |
| Identity | Predicate id and version; source chain; source namespace; applicable ledger era, runtime, or state version |
| Statement | Natural-language statement; formal statement; bounded public inputs; typed outputs; private witness |
| Source semantics | Source-described anchor or ledger object, relation bounds, and, for a Midnight row, the public ledger source described by the statement |
| Raw vectors | Source examples or exact source-derived vectors, with no claim that they satisfy a selected public profile |
| Provenance | Primary-source locators and digests; source byte ranges or upstream object ids; per-row reconstruction and provenance digest |

Proof-template family, suite, circuit architecture, VK/SRS/setup graph,
demonstrated finality and freshness profile, selector, destination policy,
deployment domain, conformance vectors, transaction use, and implementation
status are not recovery fields. PBT-S03-W06 through W08 record them in separate
admission artifacts after PBT-S02 closes. Admission never rewrites the recovered
catalog bytes.

## Mechanical recovery gates

One recovery validator run applies all four gates to the same canonical catalog
bytes:

1. **Count:** exactly 42 Cardano records, exactly 52 Midnight records, and
   exactly 94 records in the combined catalog.
2. **Uniqueness:** no duplicate predicate id or predicate id and version key in
   either source catalog or the combined registry input.
3. **Schema:** every row has all recovery fields, valid bounded types, recognized
   source enums, and internally consistent statement, witness, source-semantic,
   raw-vector, and provenance references.
4. **Provenance:** every row has a provenance digest that resolves to recovered
   source bytes or a source-backed reconstruction record with primary or
   verbatim-gated evidence.

A failure in any recovery gate stops W05. After public feasibility closes, W06
assigns each row to one justified proof-template family, W07 supplies
destination-use and conformance-vector matrices, and W08 binds the same recovered
catalog digest and demonstrated public profiles in an admission receipt. A
passing recovery validator is necessary but does not admit a circuit or
deployment.

## No filler rows

No row may be invented, duplicated, renamed, or split to satisfy a count. The
numbers 42 and 52, a list of namespaces, a proof-template family, or a plausible
application claim is not row-level source evidence. Source-backed reconstruction
is allowed only one record at a time, with the complete recovery contract and
provenance needed to reproduce that record.

## Predicate records, template families, and live tests

A recovered predicate record defines source-backed application semantics. A
separate admitted proof-template family defines a reusable circuit shape.
Several predicate records may use one constrained template selector or one
authorized aggregation relation, but every predicate keeps its own source
statement and provenance while its admission record keeps its schemas, public
anchor policy, destination use, and vectors. Template reuse can reduce the
number of circuits and setup ceremonies; it cannot reduce the required record
count.

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
uniqueness, schema, and provenance gates pass together, no canonical catalog
exists. Even after recovery, the registry stays empty until the separate public
admission records pass. No claim of complete predicate coverage is valid before
both stages close.
