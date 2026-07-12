# Fable 5 remediation disposition

Date: 2026-07-12 UTC

Audit: `docs/superpowers/reviews/2026-07-11-fable-5-full-audit.md`

Audit target: `9f5445659d1927510c6c29f0285a405ecda30767`

Remediation candidate: `1b885e68ab902fd8af0a99bbb7955b98f9967543`

Candidate tree: `5d5dfd8c9277471573a619be0bc356c533ebf7cd`

Classification: technical disposition, not a deployment or closure authority

## Result

The candidate and the post-candidate review records resolve all eight Major and
fourteen Minor findings. Eight Notes are also resolved. Two Notes remain
explicit future-package work:
the conditional Sprint 0 OpenSpec path belongs to `PBT-S00-W01`, and graph-backed
wiki status materialization belongs to `PBT-S00-W11`. Neither deferred Note can
authorize deployment or hide an open chain gate.

Reader reports remain advisory. The result below rests on committed artifacts,
deterministic contracts, exact source receipts, and two read-only harness runs,
one of them in a fresh Windows checkout with `core.autocrlf=true`.

## Major findings

| Finding | State | Disposition and evidence |
| --- | --- | --- |
| `F5-MAJOR-001` | resolved | The old report is labeled a pre-control-plane bootstrap review and states that it cannot authorize Sprint 0. The new remediation review binds candidate commit `1b885e68`, its tree, and each reviewed blob, and is committed after the candidate. |
| `F5-MAJOR-002` | resolved | Sections 1, 5, 6, and 11 now use official genesis, official chain rules, and official finality roots. A checkpoint is only official-root-derived acceleration or lab-only and classifier-ineligible. |
| `F5-MAJOR-003` | resolved | The master plan, rebaseline, and Sprint 0 plan carry a byte-identical `re-entry-contract:v2` block. The document contract compares the blocks and the full drift taxonomy. |
| `F5-MAJOR-004` | resolved | Model and persona readers are advisory quality controls. They do not enter a roster, closure decision, activation decision, classifier-readiness receipt, or classifier input. Deterministic checks and reproducible receipts decide state. |
| `F5-MAJOR-005` | resolved | Sprint 0 is split into W01 through W18. W13 owns privileged repository and credential methods, W14 build qualification, W15 quarantine, W16 bootstrap replay, W17 CI and smoke, and W18 closure and publication. The complete program now has 106 packages and 231 ordered dependency edges. |
| `F5-MAJOR-006` | resolved | `ContributorIndependencePolicyV1` defines identity anchors, separate control domains, environment evidence, numeric thresholds, two cross-domain adjudicators, appeal, and falsifiable failure conditions. Agent simulations never count as people. |
| `F5-MAJOR-007` | resolved | The verifier hashes committed Git blobs and rejects tracked drift plus ordinary or ignored untracked inputs. Canonical JSON is LF-only, and the disposable fixture enables Git long-path support. Generation `3bf6982d5fcb4a2d8bea0ddc4bc00fd5` passes in place and in a fresh `core.autocrlf=true` checkout. |
| `F5-MAJOR-008` | resolved | README, checklist, research plan, wiki, and package counts use `OutcomeClassifierV2`, 14 sprints, 106 packages, and the 25-section design. Superseded `degraded-lab`, 11-sprint, and section 31 authority is removed from current top-level documents. |

## Minor findings

| Finding | State | Disposition and evidence |
| --- | --- | --- |
| `F5-MINOR-001` | resolved | The proof-system title is a quoted YAML scalar and the document contract checks it. |
| `F5-MINOR-002` | resolved | The claim wire profile is owned by `PBT-S04-W01`; the stale Sprint 3 reference is gone. |
| `F5-MINOR-003` | resolved | The ceremony page states that no bridge ceremony has run and separates observed source behavior from future bridge requirements and ceremony modes. |
| `F5-MINOR-004` | resolved | The 2026-07-12 gnark receipt records the delta proof across G1 delta, G2 delta, `Z`, and `PKK`; the fork is described as pinned and not yet reviewed. |
| `F5-MINOR-005` | resolved | The documents distinguish Groth16 Phase 1 (Powers of Tau) from per-circuit commitment-aware (BSB22) Phase 2. |
| `F5-MINOR-006` | resolved | New-or-update mode requires a publicly verifiable, independently operated beacon class with a frozen close point, unpredictability horizon, authenticated resolution, domain, and replay rule. |
| `F5-MINOR-007` | resolved | The proof-zk-recovery addendum says the evidence came from a local clone and defers upstream equality to `PBT-S07-W01`. |
| `F5-MINOR-008` | resolved | W01 requires an operator-held `ProgramBaselinePrecommitmentV1` supplied before repository work and rejects a missing, stale, self-authored, or mismatched record. |
| `F5-MINOR-009` | resolved | The rebaseline distinguishes the historical `3db35fa9` design session from the exact candidate blob named by the later review. |
| `F5-MINOR-010` | resolved | W12 creates `program/schemas/classifier-readiness-v1.schema.json` and binds it as the accepted evidence schema. |
| `F5-MINOR-011` | resolved | Master, rebaseline, and Sprint 0 closure-envelope descriptions all permit declared redaction receipts. |
| `F5-MINOR-012` | resolved | The proof-zk-recovery addendum records the exact pinned paths and blob ids for transcript linkage, payload caps, mini-circuit use, golden VK drift checks, and the gnark pin. |
| `F5-MINOR-013` | resolved | Events `kge-0295` through `kge-0298` record the four active contradictions. The event stream now contains 298 schema-valid events. |
| `F5-MINOR-014` | resolved | Open questions cite primary repository sources, the predicate risk has an owner edge, and both 2026-07-11 log entries have immutable raw session records. |

## Notes

| Finding | State | Disposition and owner |
| --- | --- | --- |
| `F5-NOTE-001` | resolved | The old raw receipt remains immutable. A superseding receipt says the source does not define bridge beacon policy, while maintained design and wiki pages own the normative requirement. |
| `F5-NOTE-002` | resolved | Historical qualification now requires the original contributor policy as well as chronology, beacon, algebra, anchors, and exact bytes. |
| `F5-NOTE-003` | resolved | Ceremony frontmatter has a current timestamp and both 2026-07-12 source receipts. |
| `F5-NOTE-004` | resolved | The Midnight ZK page narrows `trustless` to an explicit profile and correctly distinguishes what the high-level source and pinned implementation sources establish. |
| `F5-NOTE-005` | resolved | `ArtifactAuthorizationV1` includes `approval_policy_digest`. |
| `F5-NOTE-006` | resolved | The control-plane wiki says the 18 Sprint 0 packages will implement the machinery. |
| `F5-NOTE-007` | resolved | W09 fixes the detached audit-runner path; W10 validates its behavior. |
| `F5-NOTE-008` | tracked | The conditional `openspec/changes/pbt-s00-program-control-plane/` path remains correctly absent until `PBT-S00-W01` creates it. W01 owns the update. |
| `F5-NOTE-009` | resolved | Open questions now cover Compact, `cardano-node`, `cardano-cli`, Midnight genesis, and BEEFY data. |
| `F5-NOTE-010` | tracked | Wiki frontmatter status is still synthesis metadata. `PBT-S00-W11` owns a graph event and materialization rule before status can become machine-queryable authority. |

## Residual boundary

The remediation does not close the six `S01-BLOCK-*` gates or eight `CONS-*`
gates. No Cardano or Midnight destination has accepted a bridge-authorized state
transition. The evidence therefore remains `structural-pass`, deployment
`blocked`, and `activation_eligible=false`.
