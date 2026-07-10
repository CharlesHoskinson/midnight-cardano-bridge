# Program wiki maintenance rules

## Authority

Files under `raw/` are immutable after their first commit. Correct an error by
adding a new receipt that names and supersedes the old one. Do not edit the old
bytes.

For repository sources, `source_sha256` is SHA-256 over the canonical staged or
committed Git blob bytes. Do not hash a platform-specific working-tree text
representation. Validate committed sources with the named snapshot and Git
object database. External receipts state their own byte and hashing profile.

Files under `wiki/` are maintained synthesis. They may change when evidence or
decisions change. A page must never present synthesis as a primary source.

`graph/events.jsonl` is append-only. `graph/nodes.json` and `graph/edges.json`
are materialized views and must reproduce exactly from the event stream.

## Required page metadata

Every maintained wiki page begins with YAML frontmatter containing:

```yaml
id: stable.dotted.identifier
type: overview|decision|component|predicate|root-of-trust|risk|sprint|question|log
title: Plain title
status: active|blocked|superseded|resolved
updated_at: UTC timestamp
sources:
  - repository path or source receipt id
```

Use stable ids in graph events. Renaming a file does not rename its id.

## Ingest

1. Add or identify an immutable source receipt.
2. Verify its byte hash and authority label.
3. Search the index and graph for affected pages before creating a page.
4. Update existing pages when the fact belongs to an existing concept.
5. Add contradiction or supersession events instead of silently replacing a
   prior assertion.
6. Update the index, materialized graph, and chronological log in the same
   commit.

Do not ingest private reasoning, model thought streams, credentials, secret
values, raw process environments, or transient debugging guesses.

## Query

Read `wiki/index.md`, then the smallest relevant set of pages and their cited
sources. Answers distinguish source facts, repository observations, decisions,
inferences, and unresolved questions. File durable new synthesis only when it
will be reused.

## Lint

Check required metadata, unique ids, source existence and hashes, broken links,
orphans, duplicates, contradictions, stale claims, missing supersession links,
event sequence, and materialized graph equality. A sprint cannot close while a
Blocking or Major wiki lint result remains.

## Writing

Use plain technical prose. State what is known, how it is known, and what would
change the conclusion. Do not narrate drafting iterations inside current-state
pages. Keep history in raw receipts, graph events, the log, and Git.
