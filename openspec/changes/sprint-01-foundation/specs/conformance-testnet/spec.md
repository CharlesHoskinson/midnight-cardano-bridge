## ADDED Requirements

### Requirement: Honest outcome labels
The testnet program SHALL report exactly one evidence-backed outcome: `live-pass` only when both selected public testnets accept claim-authorized transactions under their named public source-consensus, proof, setup, and policy assumptions; `degraded-lab` when both directions execute but either uses a project-operated certifier, fixture anchor, mock transition, or other non-public trust root; or `blocked` when a required proof relation, authenticated state path, execution surface, catalog gate, or public-testnet dependency cannot be completed. A blocked result SHALL record its reproducer, owner, affected interface, and resume evidence, and no label change SHALL conceal an unresolved hard gate.

#### Scenario: Lab or blocked paths cannot be reported as live-pass
- **WHEN** deployment evidence contains a lab-only trust root or any unresolved hard gate in either proof direction
- **THEN** the program SHALL report `degraded-lab` or `blocked` as applicable and SHALL NOT report `live-pass`
