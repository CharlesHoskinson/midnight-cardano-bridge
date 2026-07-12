# proof-zk-recovery MPC local-source receipt addendum

Source id: `source.external.proof-zk-recovery-mpc.2026-07-12`
Record type: local Git-object observation receipt
Observed at: 2026-07-12T02:12:00Z
Supersedes: `source.external.proof-zk-recovery-mpc.2026-07-10` for authority wording and path observations

## Authority and acquisition

The evidence was acquired from the existing local clone at
`C:/proof-zk-recovery`, whose configured project identity is
`https://github.com/CharlesHoskinson/proof-zk-recovery`. Commit
`6c5dc257a9804b6b88bad20541b5bac46fff8dbd` and its recorded objects reproduce
inside that local object database. Equality with a freshly fetched upstream ref
is deferred to `PBT-S07-W01`; this receipt does not claim that confirmation.

The earlier receipt's commit, parent, subtree, archive, license, `go.mod`, and
assurance-review hashes remain unchanged.

## Pinned path observations

| Path at the pinned commit | Git blob | Observation |
| --- | --- | --- |
| `proto/ceremony/cmd/contributor/main.go` | `abcc988c8a62f7e336abb99e0388b81c3c442df4` | The contributor flow seals Phase 1 with a supplied beacon and calls `core.CompileMiniCircuit()`. |
| `proto/ceremony/core/transcript.go` | `1aec9ab8fce0a9272b9a19e2241c89b344233531` | Transcript records carry a previous hash; the content address is BLAKE2b-256 over domain-separated TLV fields including that predecessor. `ReadTranscript` takes `maxPayload` and bounds declared payload and attestation lengths before allocation. |
| `proto/ceremony/spec/drift_canary_test.go` | `68bf44376daef7921ba167ec48d81b13ead4401a` | The drift canary regenerates a deterministic verifying key and compares it with `testdata/golden_vk_c.bin`. |
| `proto/ceremony/go.mod` | `c82a4dc17dc47270dfa0d1e2ab4aec1568bb321f` | The module replaces upstream gnark with the CharlesHoskinson fork at pseudo-version commit `0dc3be8cad8a`. |
| `proto/ceremony/core/bgm17.go` | `91af8bcada7c2b5c37838d6c6b6c3937cf17658c` | Wrapper functions use checked reads, delegate phase-step verification to the pinned gnark verifier, accept caller-supplied beacons for sealing, and compile the mini circuit in the full replay path. |

These observations support evaluation of the candidate source. They do not make
the local clone upstream-authoritative, approve the implementation, or prove a
bridge ceremony has run.
