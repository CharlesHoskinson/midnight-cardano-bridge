---
id: source.design-session.2026-07-12-fable-audit-remediation
type: design-session
recorded_at: 2026-07-12T02:20:00Z
status: immutable-on-commit
---

# Fable audit remediation session

## Inputs

- `docs/superpowers/reviews/2026-07-11-fable-5-full-audit.md`
- the public-testnet rebaseline, master register, Sprint 0 plan, canonical bridge design, and program wiki
- fresh Scrapling retrievals recorded in the 2026-07-12 gnark receipt
- local Git-object observations recorded in the 2026-07-12 proof-zk-recovery receipt

## Decisions

- Preserve published package ids and split oversized Sprint 0 work into W13-W18. The program now has 14 sprints, 106 packages, and 18 Sprint 0 packages.
- Make the re-entry table byte-identical in the rebaseline, master register, and Sprint 0 plan.
- Treat model and persona reader output as advisory. Deterministic contracts and externally reproducible receipts authorize closure.
- Require an operator-held `ProgramBaselinePrecommitmentV1` before W01.
- Bootstrap public proofs from official genesis, official rules, and official finality roots. A checkpoint qualifies only as an official-root-derived acceleration artifact.
- Make `ContributorIndependencePolicyV1` a gated pre-enrollment deliverable with numeric thresholds and falsifiable failure conditions. Agents test the policy but never count.
- Hash reference-harness inputs from committed Git blobs and require an LF checkout policy for portability.

## Graph changes

Add package nodes W13-W18 and their Sprint 0 edges. Add the two superseding
source-receipt nodes, this session and the two 2026-07-11 session nodes, the
missing predicate-catalog owner edge, and source edges for the MPC page.

Record contradiction events for the four conflicts already listed in
`wiki/contradictions.md`: Sprint 2 closure state, mixed host observations,
checkpoint-root authority, and reduced public coverage. Subsequent resolution
events must name the correction that actually removes each conflict.
