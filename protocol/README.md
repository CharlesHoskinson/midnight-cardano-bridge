# Bridge protocol artifacts

`gate-roster-v1.json` is the sole `GateRosterV1` publication. Its `roster`
member is encoded with RFC 8949 deterministic CBOR under
`mcb.common-cbor.rfc8949-deterministic.v1`. The lowercase SHA-256 of those bytes
is recorded in `canonical_cbor_sha256`; `gate-roster-v1.cbor.hex` is the
lowercase hexadecimal rendering of the same bytes. The digest does not cover the
publication wrapper, so it has no self-reference.

The entry order is significant. Gate ids, owner ids, interface ids, evidence
ids, and activation references are protocol identifiers, not display labels.
Prose may summarize the roster but cannot add an entry or redefine one of these
fields.
