## ADDED Requirements

### Requirement: Concurrent claim consumption
The settlement protocol SHALL support `advance-and-consume`, which advances from the exact predecessor light-client state and consumes a claim under the successor anchor, and `consume-current-anchor`, which leaves the tracked anchor unchanged and consumes a distinct message id or nullifier under the current anchor. Both transitions SHALL verify the registered proof and destination policy and SHALL atomically apply the destination action and replay update. A rejected or interrupted submission SHALL NOT consume replay state, an older anchor SHALL NOT be consumed after advancement, and submissions racing on one predecessor SHALL refresh or rebase without duplicating settlement.

#### Scenario: Distinct claims may consume one current anchor without duplicate settlement
- **WHEN** two valid claims reference the same current authenticated anchor and carry distinct registered message ids or nullifiers
- **THEN** each claim SHALL be independently consumable exactly once through `consume-current-anchor` without advancing the anchor or authorizing a duplicate settlement
