---
type: Concept
title: Midnight published chain-spec validator-set sizing
timestamp: '2026-07-09T21:35:00Z'
description: Public Midnight resource chain specs pin small initial BEEFY/session
  authority sets for govnet, devnet, and mainnet; bridge budgeting must still track
  live runtime authority-set rotation.
resource: _external/midnight-node/res/{govnet,devnet,mainnet}/chain-spec-abridged.json
tags:
- midnight
- consensus
- validator
- beefy
- d-parameter
- chain-spec
- bridge
source: src-0049
status: researched
okf_version: '1.0'
---

# Midnight published chain-spec validator-set sizing

The public `midnight-node` resource chain specs narrow the validator-count question
for initial public network configurations. The values below are deterministic counts
from `res/{govnet,devnet,mainnet}/chain-spec-abridged.json`, gated in
`research-runs/midnight-validator-set-sizing-20260709/`.

| Network | `dParameter` | BEEFY authorities | session `initialValidators` | committee `initialAuthorities` |
| --- | ---: | ---: | ---: | ---: |
| govnet | 6 permissioned / 0 registered | 6 | 6 | 6 |
| devnet | 7 permissioned / 0 registered | 7 | 7 | 7 |
| mainnet | 10 permissioned / 0 registered | 10 | 10 | 10 |

For the current public BEEFY-ECDSA bridge mode, this means a genesis-mainnet
Mode-0 Cardano verifier budget should model **N = 10** signatures plus the
`AuthoritiesProof`, not the runtime type ceiling (`MaxAuthorities = 10_000`).
That does not make the set static: BEEFY commitments carry `validator_set_id`, and
the bridge still has to track mandatory-block handoffs / session rotation and verify
against the live authority set accepted by the target deployment.

The local sample resource config has five permissioned candidates, but this checkout
does not include a matching `res/local/chain-spec-abridged.json`; treat it as local
environment scaffolding, not a public-network budget source.

## Related

- [Midnight consensus - AURA + GRANDPA](midnight-consensus-aura-grandpa.md)
- [BEEFY implementation notes](beefy-implementation.md)
- [Midnight <-> Cardano recursive bridge](../bridges/midnight-cardano-recursive-bridge.md)
- [Sources index](../sources/index.md)
