---
id: program.sprints
type: sprint
title: Sprint map
status: active
updated_at: 2026-07-10T15:02:07Z
sources:
  - docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md
---

# Sprint map

| Sprint | Packages | Scope |
| --- | ---: | --- |
| PBT-S00 | 12 | Controller, runlogs, command supervisor, snapshots, Git safety, agent lanes, program wiki, GateRosterV2 |
| PBT-S01 | 6 | Current structural harness closure |
| PBT-S02 | 9 | Official roots, chain tools, SCLS, BEEFY/MMR event proof, verifier surfaces, full decider |
| PBT-S03 | 8 | All-94 predicate recovery and admission |
| PBT-S04 | 6 | Shared claim and registry protocol |
| PBT-S05 | 6 | Cardano to Midnight proof path |
| PBT-S06 | 7 | Midnight to Cardano proof path |
| PBT-S07 | 8 | Production circuits, verifiers, MPC framework hardening, circuit freeze |
| PBT-S08 | 6 | Human ceremonies and artifact freeze |
| PBT-S09 | 7 | Harness, relayers, and destination-local settlement |
| PBT-S10 | 7 | Conformance, faults, security, and performance |
| PBT-S11 | 6 | Public-testnet readiness |
| PBT-S12 | 7 | Public deployment and all-family execution |
| PBT-S13 | 5 | Independent public closure |
| Total | 100 | |

Dependency summary:

```text
PBT-S00 -> PBT-S01
PBT-S01 -> PBT-S02
PBT-S01 -> PBT-S03 research
PBT-S02[demonstrated] + PBT-S03 -> PBT-S04
PBT-S04 -> (PBT-S05 || PBT-S06)
PBT-S05 + PBT-S06 -> PBT-S07 -> PBT-S08 -> PBT-S09 -> PBT-S10 -> PBT-S11 -> PBT-S12 -> PBT-S13
```
