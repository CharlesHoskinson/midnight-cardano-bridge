---
id: decision.predicate-coverage
type: decision
title: Predicate and public execution coverage
status: active
updated_at: 2026-07-11T04:35:12Z
sources:
  - source.design-session.2026-07-10-program-rebaseline
  - source.design-session.2026-07-10-implementation-planning
  - knowledge_base/proof-claims/predicate-catalog-status.md
---

# Predicate and public execution coverage

The local conformance corpus is a blocked admission target. Sprint 3 must recover
exactly 42 source-backed Cardano records and 52 source-backed Midnight records.
The current repository does not contain those rows. W01 through W05 preserve
source semantics, witnesses, bounds, raw vectors, and provenance in immutable
catalog bytes. They do not assign proof families, public profiles, destination
policy, or artifacts.

After Sprint 2 demonstrates the public profiles, W06 through W08 add separate
admission records keyed to the recovered catalog digest. Every admitted record
needs a proof-template mapping, destination use, a positive vector, its required
negative vectors, and cross-predicate substitution coverage. A correctly
recovered relation that the public profiles cannot support remains unchanged and
blocks admission.

Public tests operate at the proof-template boundary. For each direction, every
authorized proof-template family must produce a confirmed state-changing
destination receipt. The registry, gate roster, and classifier derive this
matrix mechanically. A hand-written list or one transaction in each direction
is insufficient.
