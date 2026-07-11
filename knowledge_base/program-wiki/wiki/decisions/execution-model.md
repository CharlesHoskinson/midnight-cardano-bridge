---
id: decision.execution-model
type: decision
title: Program controller and bounded sprint packets
status: active
updated_at: 2026-07-11T04:35:12Z
sources:
  - source.design-session.2026-07-10-program-rebaseline
  - docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md
---

# Program controller and bounded sprint packets

One event-sourced native broker under a dedicated service SID owns dependencies,
attempts, leases, retries, external waits, artifacts, invalidation, and closure.
Package processes run under restricted tokens in full independent clones. They
cannot mutate controller or canonical Git storage and receive only a private
attempt capability channel. Grok receives a fresh XML packet for each bounded packet. Discovery
packets state unresolved external-input requirements; resolved implementation
packets bind the receipts produced by discovery. Grok does not carry the
complete program through one unbounded session.

Every command uses the same supervised execution path. Every review binds a
complete `ProgramSnapshotV1`. The append-only event stream is historical truth;
manifests and graph views are derived artifacts.

Read-only research and the two directional proof paths may use independent
agents where the dependency graph permits. Repository integration, evidence
publication, setup transitions, deployments, and pushes are serialized.
