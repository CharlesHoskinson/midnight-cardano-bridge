# proof-zk-recovery MPC source receipt

Source id: `source.external.proof-zk-recovery-mpc.2026-07-10`
Record type: external Git source receipt
Retrieved at: 2026-07-10T22:33:54Z

Authority: upstream Git objects from
`https://github.com/CharlesHoskinson/proof-zk-recovery`

Acquisition: existing local Git object database at `C:/proof-zk-recovery`.
No working-tree file is an authority for this receipt.

## Ceremony source snapshot

- Observed remote ref: `origin/feat/mpc-ceremony-framework`
- Commit: `6c5dc257a9804b6b88bad20541b5bac46fff8dbd`
- Parent: `adf4e9ae661220255f70a55f162a883f26c9a924`
- Commit date: 2026-06-30
- Path: `proto/ceremony`
- Git tree object: `fbd85ba8a229878d93f546559466b183779cb931`
- Canonical archive command: `git archive --format=tar <commit> proto/ceremony`
- Archive bytes with Git 2.55.0.windows.1: 133120
- Archive SHA-256: `8ad53431636903342d4ca53175d75755a01c0eda2be3b5aa83ce53f1371ea92c`

The full commit and tree object define the source identity. The archive hash is
a transport check under the named Git version and command.

## Assurance review snapshot

- Observed remote ref: `origin/proto/preprod-experiments`
- Commit: `6212744a1ce60f328f92cbe95d90b6d94baa7b04`
- Parent: `b287c9d747d038dcd46e73be84e96a5c323c3a01`
- Commit date: 2026-07-01
- Path: `audit/26-mpc-ceremony-assurance-review.md`
- Git blob object: `976c995e1fedfb9849aa5d7733b529d87099d237`
- Blob bytes: 13865
- Blob SHA-256: `9fad651573e3680d4486fd4328213376a54d98dec29a4e09d97338db3453cb8a`

## License snapshot

- Path: `LICENSE`
- Git blob object: `71fe98a3f5dd6ad99733ca2c24af28b3716eb9ba`
- Blob bytes: 11348
- Blob SHA-256: `564375305a412a292d2e12024b657786ced6b4688b7b7c4b0bdb218f650a4367`
- Declared license: Apache License 2.0

Git object ids use the repository's SHA-1 object format. SHA-256 values above
cover exact blob or archive bytes. Sprint 7 must fetch the named commits from
the upstream remote, verify object and content identities, record license
disposition, and import only the reviewed subset. This receipt does not approve
the source for ceremony use.
