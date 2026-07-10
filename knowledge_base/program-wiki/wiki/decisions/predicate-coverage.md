---
id: decision.predicate-coverage
type: decision
title: Predicate and public execution coverage
status: active
updated_at: 2026-07-10T15:02:07Z
sources:
  - source.design-session.2026-07-10-program-rebaseline
  - knowledge_base/proof-claims/predicate-catalog-status.md
---

# Predicate and public execution coverage

The local conformance corpus contains exactly 42 source-backed Cardano records
and 52 source-backed Midnight records. Every record needs canonical registry
bytes, a proof-template mapping, a positive vector, its required negative
vectors, and cross-predicate substitution coverage.

Public tests operate at the proof-template boundary. For each direction, every
authorized proof-template family must produce a confirmed state-changing
destination receipt. The registry, gate roster, and classifier derive this
matrix mechanically. A hand-written list or one transaction in each direction
is insufficient.
