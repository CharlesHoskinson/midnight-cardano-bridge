---
type: Concept
title: Midnight transaction wire format — container serialization + field-aligned
  binary (FAB)
timestamp: '2026-07-09T16:09:42Z'
description: 'Authoritative wire-format spec (Midnight ledger PR #617, base ledger-9):
  the two serialization layers a cross-chain verifier must parse — the serialize-crate
  tagged container format and Field-Aligned Binary (FAB) for embedded ZK values.'
resource: https://github.com/midnightntwrk/midnight-ledger/blob/tna/feature-documentation-zkir_v3/spec/transaction-format.md
tags:
- midnight
- serialization
- field-aligned-binary
- fab
- transaction-format
- ledger-9
- pr-617
- wire-format
source: src-0033
status: researched
okf_version: '1.0'
---

This page specifies the **wire (binary) serialization** of a Midnight
transaction — the exact bytes a cross-chain verifier or parser (e.g. a
Cardano-side verifier in a recursive, trustless bridge) must consume to check a
Midnight transaction or state. It is drawn from the Midnight ledger repository's
`spec/transaction-format.md` as it stands in **PR #617 (open, base ledger-9)**
(`src-0033`), which reconciles the idealised narrative spec with the *actual*
`ledger/src/structure.rs` definitions and adds the wire format. See the
[knowledge base index](/index.md), the [sources index](/sources/index.md), the
companion [Midnight transaction types](/midnight/transaction-types.md) catalogue,
and the [Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md).

> Status note: PR #617 is **open** and based on ledger-9; tags and versions
> below (`transaction[v12]`, `intent[v9]`, …) are the on-wire values as of that
> branch and can move before merge. Treat them as authoritative for this study
> but re-pin on merge.

## The two serialization layers

The single most important structural fact for a parser is that **two distinct
binary formats are involved, and they should not be conflated**:

- **Container format** — serialises the `Transaction` and *all* its
  sub-structures (intents, offers, actions). It is produced by the **`serialize`
  crate**: a `midnight:<tag>:` prefix followed by a **SCALE-style** binary body,
  with `[vN]` **type-version tags**.
- **Field-Aligned Binary (FAB)** — serialises the leaf `AlignedValue`s *inside*
  contract state, transcripts, and keys. FAB has a `Value`/`Alignment` byte form
  plus a **field-element** form used inside proofs.

In short: the transaction envelope is `serialize`-crate tagged binary, and **FAB
appears within it** wherever ledger data values are embedded. A verifier needs
both decoders and must know, at every field, which layer it is in.

## Container format (the `serialize` crate)

A top-level value is written with `tagged_serialize` as:

```text
midnight:<tag>:<Serializable body>
```

Key properties a parser must implement:

- **Global tag + type tag.** `GLOBAL_TAG = "midnight:"` is a fixed prefix; the
  `<tag>` is the type's tag (e.g. `transaction[v12]`). Deserialization checks
  both, so **data tagged as one type cannot be silently read as another** — a
  cheap but load-bearing anti-type-confusion guard.
- **Versioning is in the tag.** Square-bracketed `[vN]` suffixes version a type
  independently of its name. A **struct-layout change must change the tag**
  (enforced by a derive-time `tag_unique_factor` test), which prevents silent
  wire-format drift. A cross-chain verifier can therefore key its decoder on the
  exact tag string and fail closed on any unrecognised version.
- **SCALE-style body.** `u8`/`u16` (and signed integers) are fixed-width
  little-endian, but **`u32`/`u64`/`u128` are SCALE compact varints**, *not*
  fixed-width. `Vec`/`Array`/`HashMap` are length-prefixed by a compact `u32`
  count (maps in sorted-key order); `Option` is a presence byte + payload; enums
  are a discriminant + variant body; `Sp<T>` serialises as its pointed-to `T`.
- **No envelope length.** `tagged_serialize` writes **no length field** after the
  `midnight:<tag>:` prefix — the body follows immediately, so the parser must be
  driven entirely by the type/tag schema, not by a self-describing length.

## Field-Aligned Binary (FAB) for embedded values

Wherever a ledger *data value* is embedded (contract-state cells, transcript
values, map keys), the bytes are **FAB `AlignedValue`s**, not `serialize`-crate
output:

- A **`Value`** is a list of **`ValueAtom`s** (each a `Uint8Array`); an
  `AlignedValue` pairs each `ValueAtom` with its `AlignmentAtom`.
- The byte encoding uses variable-length **integers-with-flags** (`xy`, 1–3
  bytes) whose flag bits select the `Value`/`ValueAtom`/`Alignment`/
  `AlignmentSegment` interpretation.
- A separate **field-element representation** is used *inside proofs*: `field`
  atoms become one field element, `compress` a hash, and `bytes<n>` pack
  **31 bytes per field element, filled from the end** (`ceil(n/31)` elements).
  The **FAB field modulus is the base elliptic curve's scalar field** (the
  native field).

This field-element form is the natural hand-off point to a recursive verifier:
it is already the representation the proof system consumes, on the native field.

## Tagged type / version index (as of PR #617)

The container tags a cross-chain parser must recognise include
`transaction[v12]` (the top-level enum: `Standard` + `ClaimRewards`),
`standard-transaction[v12]`, `claim-rewards-transaction[v2]`, `intent[v9]`,
`intent-hash`, `unshielded-offer[v2]`, `contract-action[v9]`,
`contract-call[v3]`, `contract-deploy[v6]`, and
`contract-maintenance-update[v3]`. One documented wire-level wart: the
`TransactionIdentifier` tag is **misspelled `transcation-id[v1]`** in
`structure.rs`, and because renaming it would break the wire format it must
stay — a parser must match the typo verbatim.

## Bridge implications (Midnight ↔ Cardano)

For the recursive-bridge study, this page fixes the **parsing contract** on the
Cardano side (or any external verifier):

1. Decode the outer envelope as `serialize`-crate tagged binary, pinning on the
   exact `midnight:<tag>[vN]:` strings and SCALE compact-varint integer rules.
2. Recurse into sub-structures (intents, offers, contract actions) by tag,
   with no envelope length to lean on.
3. Switch to the **FAB** decoder for every embedded `AlignedValue`, and use the
   **field-element** FAB form — on the base curve's scalar field — as the input a
   recursive/native verifier checks.

Because the versioning lives in the tag and a layout change *must* bump it, the
verifier can safely fail closed on any unknown `[vN]`, which is the desired
behaviour for a trustless bridge that must never mis-decode a Midnight
transaction. See [Midnight transaction types](/midnight/transaction-types.md)
for the semantics of each variant and
[Midnight↔Cardano recursive bridge](/bridges/midnight-cardano-recursive-bridge.md)
for how this feeds the end-to-end design.

## Open items to confirm

- Whether the `[vN]` tag values above hold at PR #617 **merge** (re-pin on merge).
- The exact FAB `xy` flag-bit table and the `< 2^19` length cap semantics for a
  hardened parser.
- How the FAB field-element form lines up with the bridge's chosen recursive
  verifier (native-field arithmetization).