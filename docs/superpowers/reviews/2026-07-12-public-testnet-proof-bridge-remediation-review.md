# Public testnet proof bridge remediation review

Date: 2026-07-12 UTC

Classification: advisory, snapshot-bound remediation review

Candidate commit: `1b885e68ab902fd8af0a99bbb7955b98f9967543`

Candidate tree: `5d5dfd8c9277471573a619be0bc356c533ebf7cd`

Audit baseline commit: `38628c9`

This review was written after the candidate commit. It does not review or bind
its own bytes. It cannot close a package, gate, sprint, activation decision, or
deployment classifier. Its purpose is to make the reviewed snapshot and the
mechanical checks independently reproducible.

## Scope manifest

The following Git blob ids are the normative review scope. Each path exists at
the candidate commit, and each id is the result of
`git rev-parse 1b885e6:<path>`.

| Git blob | Path |
| --- | --- |
| `6313b56c57848efce05faa7aa7e901ccfc2886ea` | `.gitattributes` |
| `6e8ba0039f3c56d86441858148c9de0ca8103260` | `README.md` |
| `ba276faf68edd0923e791003ddfd5a9fc9bbe739` | `EXAMINATION-CHECKLIST.md` |
| `454c8b40239e413b9b73a83e9c9ffa0a1e5cded1` | `RESEARCH-PLAN.md` |
| `bbe9c2af2e31f68d5df45273fe413af9a7ecf207` | `docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md` |
| `3941874a2a86d348c7df118b6e9edfecfec9d03d` | `docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md` |
| `d9b2ae812e78c1309b63a123c6841d4b4c559823` | `docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md` |
| `3c6b5d9dbc456ab5fb31544509743a87c8d38430` | `docs/superpowers/reviews/2026-07-10-public-testnet-proof-bridge-implementation-plan-review.md` |
| `097de8c6b30e3041fac46beabcb466b7781bdbb0` | `knowledge_base/bridges/midnight-cardano-recursive-bridge.md` |
| `f9d3a34ca6f739dd54a48a5aaee4820c288974be` | `knowledge_base/proof-systems/groth16-trusted-setup-ceremony.md` |
| `859f8895962969fffe74f4a40e23b9c0c15fdcb3` | `knowledge_base/program-wiki/graph/events.jsonl` |
| `2df6db022a21fbd89aec74666ebd2710e3f3b42f` | `knowledge_base/program-wiki/graph/nodes.json` |
| `07cd05f449566369d3ae0a8d984d866b7a2d4e61` | `knowledge_base/program-wiki/graph/edges.json` |
| `7caaa6bdc866108f33f3f67fa04023af5911fe05` | `knowledge_base/program-wiki/raw/source-receipts/gnark-bsb22-mpc-2026-07-12.md` |
| `12b79e86d10949ced578aba49c227b537088df63` | `knowledge_base/program-wiki/raw/source-receipts/proof-zk-recovery-mpc-2026-07-12.md` |
| `b44227f2f6ceda7ad878291ffc49a02ccbcaa032` | `scripts/CommittedInputManifest.psm1` |
| `1633056c81822d004d352f434e3d57d7dfe162ce` | `scripts/CanonicalJson.psm1` |
| `5caee10600c5ab2ad79ddd4aef2fdda0fbc35052` | `scripts/compare-reference-harness.ps1` |
| `bc9b6fff55cb5c247ae7718bc9b56f66b5ee1047` | `scripts/verify-reference-harness.ps1` |
| `f3f82995642f005c4473674183ae5db70cd0e23c` | `scripts/tests/verify-reference-harness.integration.ps1` |
| `009ee4891ae235c3aecfa7c299a535d6033ed241` | `scripts/tests/public-testnet-program-docs.contract.ps1` |
| `404789b1d6ae4ba5f3f483ed04df1a2d47a3a310` | `scripts/tests/committed-input-manifest.contract.ps1` |
| `3d354e5dc182894570407da90d080c9f93ad4173` | `scripts/tests/canonical-json.contract.ps1` |
| `533f569c1a3a615cbdf77ea3bbc137d9a0b6738c` | `reference/evidence/current-generation.json` |
| `8d1b6a47d5d7171e43a335d03e56180635ca7499` | `reference/evidence/generations/3bf6982d5fcb4a2d8bea0ddc4bc00fd5/generation-manifest.json` |
| `c1e42437c23bbecf6badbaf98a94c6d33be7b49e` | `reference/evidence/generations/3bf6982d5fcb4a2d8bea0ddc4bc00fd5/structural-report-v1.json` |
| `7d0e4e34c4ad5b4ce8cc038dd97db9667f0df972` | `reference/evidence/generations/3bf6982d5fcb4a2d8bea0ddc4bc00fd5/conformance-report-v1.json` |
| `ac3a8674e82ccab423f593c876d6a6e5a8f01634` | `docs/superpowers/reviews/2026-07-11-fable-5-full-audit.md` |

## Review result

The candidate resolves the eight Major and fourteen Minor Fable findings. It
also resolves eight Notes and assigns the two remaining Notes to the packages
that can define their missing future artifacts without inventing evidence now.
The complete finding-by-finding record is in
`docs/superpowers/reviews/2026-07-12-fable-5-remediation-disposition.md`.

A separate read-only review of the remediation raised six Important issues:
ignored untracked inputs bypassed the manifest, Sprint 0 splits were not fully
propagated, old re-entry prose remained, reader counts still appeared as
authority, canonical trust text still admitted approval-selected roots, and the
golden generation had not yet been committed. Each issue received a regression
assertion or direct mechanical check before correction. Reader findings and
counts did not determine this result.

A follow-up review found one remaining count requirement in `PBT-S13-W02`.
The package now completes on immutable audit integrity and scope, sends every
finding to W04, and ignores counts and verdict for state transitions. The
follow-up reviewer reported no remaining Critical or Important issue.

Two early fresh-clone attempts failed in the nested late-failure control. A
direct replay exposed Git error 128, `Filename too long`, while the fixture
staged its copied OpenSpec tree. The disposable fixture repository now sets
`core.longpaths=true`. The same integration passes under a deliberately deep
TEMP root, and the full update run below used that long-path environment.

## Verification record

| Check | Candidate or environment | Result |
| --- | --- | --- |
| `pwsh -NoProfile -File scripts/tests/public-testnet-program-docs.contract.ps1` | `1b885e6` | pass: 106 packages, 18 Sprint 0 packages, 231 dependency edges, byte-identical re-entry blocks, current authority text, source hashes, and graph materialization |
| `pwsh -NoProfile -File scripts/tests/committed-input-manifest.contract.ps1` | `1b885e6` | pass: committed LF blob identity, tracked drift rejection, ordinary untracked rejection, and ignored `.pyd` rejection |
| `pwsh -NoProfile -File scripts/tests/canonical-json.contract.ps1` | `1b885e6` | pass: UTF-8 without BOM, LF-only JSON, one trailing LF, and parse round trip |
| PowerShell `Test-Json` over `graph/schema.json` | `1b885e6` | pass: all 298 graph events |
| `npm --offline run openspec:validate` | candidate inputs | pass: 13 of 13 strict OpenSpec items |
| `pwsh -NoProfile -File scripts/verify-reference-harness.ps1 -UpdateEvidence` | input commit `521cbf2` with deep TEMP | pass: generation `3bf6982d5fcb4a2d8bea0ddc4bc00fd5` published |
| `pwsh -NoProfile -File scripts/verify-reference-harness.ps1` | repository at `1b885e6` | pass: all control, Rust, Go, observer, cross-language, roster, CBOR, OpenSpec, stability, and evidence-publication checks |
| same read-only verifier | fresh detached clone of `1b885e6`, `core.autocrlf=true` | pass: evidence-publication and every preceding check |

The fresh checkout was
`C:\Users\charl\mcbf-37fa774b`.
Its `HEAD` was
`1b885e68ab902fd8af0a99bbb7955b98f9967543`, and Git reported
`core.autocrlf=true`. Temporary, Go, Cargo, and Python cache roots were writable
directories under the short external root `C:\Users\charl\mcbt-37fa774b`.
`node_modules` and `.venv-scrapling` were junctions to the prepared host
dependencies. Neither is an evidence input, and this run makes no immutability
claim about them.

## Boundary

This is a remediation pass for the design, workflow, evidence publication, and
knowledge records. It is not a bridge deployment pass. The generation reports:

- `structural_result=structural-pass`
- `deployment_outcome=blocked`
- `activation_eligible=false`
- six open `S01-BLOCK-*` gates
- eight unresolved `CONS-*` gates

No chain receipt, proof generation result, cryptographic verification, ceremony
contribution, or destination state transition was fabricated or inferred.
