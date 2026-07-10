---
id: risk.public-chain-gates
type: risk
title: Public-chain gates
status: blocked
updated_at: 2026-07-10T15:02:07Z
sources:
  - knowledge_base/bridges/midnight-cardano-recursive-bridge.md
  - protocol/gate-roster-v1.json
  - knowledge_base/proof-claims/predicate-catalog-status.md
---

# Public-chain gates

## Cardano source root

Current public Mithril evidence does not show a signer population certifying the
required SCLS signed entity. Project signers would create a lab root. Sprint 2
must obtain and verify an exact public SCLS certificate or block public
`live-pass`.

## Midnight event proof

The available relay carries a BEEFY commitment and authority proof but not the
complete event, header, parent-bound MMR leaf, and inclusion proof. Sprint 2 must
demonstrate that complete relation from public data on the unmodified network.

## Predicate catalogs

The three named source catalog files have not been recovered. Counts alone do
not identify the missing statements. Sprint 3 can admit only recovered rows or
one-at-a-time source-backed reconstructions.

## Destination execution

Neither destination has accepted the selected complete proof relation. Sprint 2
must demonstrate both untrusted verification surfaces and their atomic local
state transitions before production circuits begin.

## Tooling and data

The host has not qualified Compact, `cardano-node`, or `cardano-cli`. Public
Midnight genesis and initial BEEFY data also need a reproducible source. These
are feasibility inputs, not tasks to defer until deployment.
