# Program wiki graph event V2 transition

Source id: `source.design-session.2026-07-10-graph-event-v2-transition`
Record type: immutable design session
Recorded at: 2026-07-10T23:58:00Z

## Immutable V1 prefix

- Commit: `3db35fa9a7e7257359f5def4bb216c60356643b8`
- Path: `knowledge_base/program-wiki/graph/events.jsonl`
- Git blob: `c79bae81f4bdb87c5c7eef1baeeef190f8be5f65`
- Bytes: 12,144
- SHA-256: `401d2fc42de6d52fc0b52633364c9a428ec364a2fa8daf8d3c4b6226b1e51e50`
- Event range: `kge-0001` through `kge-0029`
- Schema version: 1

Those 29 lines remain byte-for-byte equal to the committed blob. V1 resolves
each source against the validator's explicit snapshot argument because the event
does not carry `source_snapshot`.

## V2 rule

Events from `kge-0030` onward use schema version 2 and require
`source_snapshot: self`. For V2, `self` resolves to the explicit index or commit
being validated and must contain both the event and its source blob. The
validator rejects V1 after sequence 29 and V2 at or before sequence 29.

This transition adds provenance to new events without rewriting the committed
V1 history.
