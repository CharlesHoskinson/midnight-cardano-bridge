---
id: source.design-session.2026-07-10-program-rebaseline
type: design-session
recorded_at: 2026-07-10T15:02:07Z
status: immutable-on-commit
---

# Public-testnet program rebaseline session

## Scope selected by the user

The plan covers the full path from the current branch to a bidirectional proof
bridge proof of concept on the Cardano and Midnight public testnets.

## Decisions

- Only public `live-pass` counts as program completion.
- Both chains remain unmodified. Application contracts, operations, provers,
  relayers, and registries may be deployed.
- All 42 Cardano and 52 Midnight predicates require source-backed local
  conformance.
- Public execution covers every proof-template family in both directions.
- Grok works from a program controller and bounded per-sprint packets.
- Agents may create disposable testnet identities outside Git and use official
  faucets. Mainnet is prohibited.
- Setup uses verified public material where compatible and a public
  multi-contributor ceremony where required.
- The MPC framework is imported from `proof-zk-recovery` and hardened locally.
- Agents simulate and attack the ceremony framework, but actual independent
  humans contribute only after the circuits freeze.
- The repository keeps an LLM-Wiki-style design memory with immutable sources,
  maintained synthesis, an append-only graph event log, and linting.

## Alternatives rejected

- A degraded lab bridge does not satisfy the proof-of-concept goal.
- Executing all 94 predicates individually on public chains would duplicate
  proof-template work. Local conformance remains per predicate; public execution
  is per direction and template family.
- One continuous Grok session is too difficult to resume and audit.
- Custom chain forks cannot establish public-testnet `live-pass`.
- Copying a single-operator Preview setup or treating agent processes as MPC
  contributors would preserve a hidden setup root.
- Patching the old 11-sprint schedule would retain the mismatch between its
  stated feasibility sprint and the work closed under Sprint 2.

## Council result

Three reviewer personas covered proof and MPC, consensus and roots of trust, and
program operations. The 13-sprint, 91-package draft was rejected. The approved
consensus has 14 sprints and 100 packages. It adds a resumable event-sourced
controller, official public-root gates, a direction-by-family roster, a
human-only ceremony wait, and a separate closure sprint.

## Known hard gates

- No recovered source catalogs currently establish the 42 and 52 predicate
  meanings.
- Public Mithril evidence does not currently show the required SCLS signed
  entity.
- The available Midnight relay does not currently carry the complete
  event-to-header-to-MMR proof relation.
- The current host has not qualified the required Cardano and Midnight chain
  tools.
- No complete destination verifier or public bridge transaction exists.

This record contains decisions and evidence summaries, not private model
reasoning.
