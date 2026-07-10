# Midnight ↔ Cardano recursive trustless bridge

A design study, and the citation-backed knowledge base behind it, for a two-way trustless bridge between Midnight and Cardano.

The idea is simple to state and hard to build. Instead of trusting a committee of signers to relay messages between the two chains, each chain verifies the other's finality for itself, inside a proof. Recursion compresses the expensive part (checking a chain's history and its finality certificate) into a single succinct proof that the destination chain can check in one shot.

This repository contains the full design document at [`knowledge_base/bridges/midnight-cardano-recursive-bridge.md`](knowledge_base/bridges/midnight-cardano-recursive-bridge.md), plus the research corpus from which it was synthesized. The corpus keeps source text and mechanically checked verbatim evidence with each admitted claim.

## Program documents

- The [canonical living design](knowledge_base/bridges/midnight-cardano-recursive-bridge.md) is the current, source-linked system description with exactly 25 numbered sections.
- The [council-reviewed program design](docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md) defines the 11-sprint, 62-work-package execution program and its proof-of-concept boundaries.
- The [predicate catalog status](knowledge_base/proof-claims/predicate-catalog-status.md) records the blocked 42 Cardano plus 52 Midnight catalog gate, searched locations, and row-admission rules without inventing entries.
- The [machine-readable gate roster](protocol/gate-roster-v1.json) is the byte-exact source for all six implementation blockers and eight consensus evidence gates.
- The [reference harness](reference/README.md) independently checks structural contracts in Rust and Go, parses the bounded BSB22 layout, and captures unsigned testnet observations through Scrapling.
- The [OpenSpec workflow](openspec/config.yaml) carries normative requirements through proposal, delta-spec, design, task, review, and archive. Sprint 1 is archived under [`openspec/changes/archive/2026-07-10-sprint-01-foundation/`](openspec/changes/archive/2026-07-10-sprint-01-foundation/), its 12 capability specs are published under [`openspec/specs/`](openspec/specs/README.md), and [Sprint 2](openspec/changes/sprint-02-reference-harness-poc/proposal.md) is active.

## Why proofs instead of a committee

Most bridges add a set of signers. If those signers collude, or their keys leak, the bridge can authorize a false transfer.

The public trust profiles in this design add no bridge quorum. They instead pin an authenticated source-chain bootstrap, consensus and finality rules, proof-system setup artifacts, verifier keys and deployment domains. Relayers move bytes but do not authorize state changes. Destination validators reconstruct the public statement, verify the registered proof, and update tracked anchor, application, value and replay state atomically.

## The design in one page

The bridge is asymmetric, because the two chains can cheaply verify different things.

For Midnight to Cardano, the selected path proves the complete Midnight finality, inclusion and predicate relation recursively in Halo2/KZG, then proves the final KZG decision inside BSB22 commitment-Groth16 over BLS12-381. A Plutus V3 validator reconstructs the typed `claim_digest`, checks the registered wrapper key and verifies that Groth16 proof with the [CIP-0381](knowledge_base/standards/cip-0381.md) pairing and [CIP-0133](knowledge_base/standards/cip-0133.md) MSM builtins. Cardano's native ECDSA builtin remains relevant to the current BEEFY source material, but it is not a substitute for the selected wrapped relation.

For Cardano to Midnight, a registered Halo2/Plonkish program verifies the Cardano anchor, inclusion path and predicate and binds the same claim protocol. Midnight's proving stack ([`midnight-zk`](knowledge_base/midnight/proving-system-curves.md)) uses KZG commitments over BLS12-381 and supports recursive composition. The destination operation must still demonstrate that it can accept an untrusted external proof and update tracked Cardano state, the requested action and replay state in one transaction.

The word recursive in the title carries weight. Re-verifying a chain's full header history on every transfer is not viable. Recursion folds "headers 0..N are valid and block N carries a finality certificate" into a single proof, and each step verifies the previous proof plus a small increment. Only the latest proof reaches the destination chain.

## Shared proof substrate

Midnight's KZG stack and Cardano's pairing builtins both use BLS12-381. That common substrate makes the selected wrapper practical and is supported by prior [Halo2-Plutus verifier](knowledge_base/cardano/halo2-plutus-verifier.md) work. It does not mean that the two chains use the same finality signature scheme: the current Midnight BEEFY layer uses ECDSA, while Mithril uses a stake-threshold construction.

The setup obligations also remain distinct. Halo2/KZG uses an authenticated universal, updatable SRS. BSB22 commitment-Groth16 adds a circuit-specific setup and verification key for the exact wrapper relation. Both artifact graphs, their hashes and their accepted deployment domains are validator roots of trust.

The [committee-key / apk-proofs](knowledge_base/proof-systems/apk-proofs-committee-key.md) work remains relevant to future source-backed certificate adapters, but the proof of concept does not assume an unpublished BLS or consensus migration.

## Where the two chains are today, and where this design goes

At launch, Midnight relies on Cardano as a trusted layer. Cardano events are observed by Midnight block producers and written into the ledger as [system transactions](knowledge_base/bridges/cardano-system-transactions.md), with the current cNIGHT bridge approving mainchain transaction hashes in batches. That is federated, not trustless.

In the other direction, Midnight's node ships a `midnight-beefy-relay` that serializes a BEEFY signed commitment and an authorities Merkle proof as Cardano `PlutusData`. The object commits to an MMR root, but the current path does not serialize the event, MMR leaf or inclusion proof needed to authenticate a particular Midnight fact. It is useful source material, not a complete settlement proof.

The design replaces trusted observation with proofs in both directions. Finality adapters are explicitly versioned by suite, protocol fingerprint and deployment domain so a future source-backed consensus change can be added without silently changing an existing claim's meaning.

## Consensus and finality, stated precisely

Midnight runs a Substrate consensus. Block production is AURA today, not BABE, and finality is GRANDPA. Validators are delegated from Cardano stake pool operators, so the two chains' validator sets overlap rather than merely resemble each other. GRANDPA finality messages are signed with Ed25519. The current bridge-oriented BEEFY adapter signs with ECDSA over secp256k1, which Cardano can verify with its native ECDSA builtin.

The current `RelayChainProof` carries a signed commitment containing the MMR-root payload, block number, validator-set id and ECDSA votes, plus a Merkle `AuthoritiesProof` against a `keyset_commitment`. The relay uses stake and authority payloads while constructing that proof, but does not serialize the full stake data or an event-to-MMR inclusion path in the Cardano-facing object. A complete validator must bind the authority-set transition, finalized commitment, MMR inclusion, predicate and typed output before settlement.

No public Cardano validator consumes the raw `RelayChainProof` with native ECDSA. That direct verifier is a separately measured production candidate, not the selected proof-of-concept verifier. The selected PoC boundary remains open: the complete wrapped BEEFY/MMR relation, the full Halo2/KZG decider inside BSB22, and the BSB22 Plutus validator must be implemented and measured together.

## The Cardano-side anchor for the reverse leg

For Cardano to Midnight, [CIP-0165](knowledge_base/standards/cip-0165.md) proposes the Standard Canonical Ledger State: a deterministic CBOR snapshot with a two-level Merkle root pinned to a slot and a UTxO namespace that supports membership and non-membership proofs. The preferred public profile would verify the complete Mithril certificate chain for that exact SCLS signed entity, including the genesis trust anchor, AVK evolution and protocol parameters, before checking a ledger path. CIP-0165 remains Proposed, and the sampled public Preview aggregator did not expose SCLS certificates, so this profile is a hard gate. A project-operated signer profile can exercise the mechanics only as `degraded-lab` evidence.

## How the knowledge base was built

I did not want a design that reads well and cites nothing. Every load-bearing claim in this repository links to a source, and the quotes behind those claims are exact substrings of the source text, checked mechanically. That gate is the reason the corpus under-claims rather than inventing citations: a weaker extraction produces fewer claims, not false ones.

The corpus was assembled with the [deep-research-toolkit](https://github.com/CharlesHoskinson/deep-research-toolkit). The workflow per source is fetch, chunk, extract claims with verbatim quotes, gate the quotes, write a concept page, then compile everything into a DuckDB and LanceDB index that the design synthesis queries.

Sources include the Cardano CIPs (0381, 0133, 0140 Peras, 0165), the Midnight repositories and docs (`midnight-zk`, `midnight-node`, `midnight-ledger`, including the ZKIR v3 documentation from pull request 617), the Polkadot BABE, GRANDPA, and BEEFY material, Mithril, and the Web3 Foundation apk-proofs work. A companion proof-claim taxonomy sits on top, describing the typed claims that applications consume once the bridge has produced a trustworthy anchor.

## How to read this repository

Start with the [canonical 25-section design](knowledge_base/bridges/midnight-cardano-recursive-bridge.md). It is the synthesis, and it links down into everything else. Use the [program design](docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md) for work-package ordering, the [predicate catalog status](knowledge_base/proof-claims/predicate-catalog-status.md) for the 94-record gate, and [OpenSpec](openspec/config.yaml) for normative requirements and review state.

From a clean checkout, first run `pwsh -NoProfile -File scripts/setup-reference-harness.ps1`, then run `pwsh -NoProfile -File scripts/verify-reference-harness.ps1`. Setup fetches lockfile-controlled Node, Rust, and Windows/Python 3.14 dependencies but no public-chain data; verification is offline and read-only. A clean run reports `structural-pass` and deployment outcome `blocked`. The committed reports are input-bound golden evidence rather than last-run status. The result covers reproducible encodings, parser boundaries, and unsigned observation provenance. It does not claim proof verification or testnet settlement.

The knowledge base is organized by domain:

- `knowledge_base/cardano/` covers Cardano-side verification, finality, and Mithril.
- `knowledge_base/midnight/` covers Midnight's proving stack, consensus, ledger, and ZKIR.
- `knowledge_base/consensus/` covers AURA, GRANDPA, BEEFY, and the signature schemes.
- `knowledge_base/proof-systems/` covers Halo2, commitment Groth16, apk-proofs, and trusted setup.
- `knowledge_base/standards/` holds the CIPs.
- `knowledge_base/proof-claims/` holds the application layer that rides on top of the bridge.
- `knowledge_base/sources/index.md` is the source ledger, one row per source with its URL and a one-line note.

`EXAMINATION-CHECKLIST.md` tracks what still needs work to move this from a draft to a buildable spec. `RESEARCH-PLAN.md` records how the corpus was assembled.

## Handoff state

One sprint is complete and archived. Sprint 2 is implemented and under final
review; nine later sprints remain in the 11-sprint program. Commit `4d985a7`
is the last baseline whose complete offline verifier passed with byte-identical
golden evidence. The council reports are recorded under
`openspec/changes/sprint-02-reference-harness-poc/review-evidence/`.

The first remediation wave is committed in `54e8d36` and binds source-event
indices and normalized observations to their preserved bytes. The proof-vector
wave is committed in `cee2bd2` and adds the explicit CBOR type manifest plus
parser-only sentinel coverage.
Do not update the golden reports until the remaining operator and proof review
items are resolved. Then run the full verifier with `-UpdateEvidence`, rerun it
read-only, and mark Sprint 2 task 6 only after a fresh proof, consensus, and
operator reread reports zero Blocking and zero unresolved Major findings.

The current PoC still does not prove a Cardano or Midnight bridge transaction.
The six `S01-BLOCK-*` gates and eight `CONS-*` gates remain open. A continuation
agent should start by reading the active OpenSpec change, all three council
reports, and `git status`, then run the component tests before changing the
canonical design. The full XML handoff prompt is in
[`docs/grok-4.5-handoff.xml`](docs/grok-4.5-handoff.xml). It maps the writable
repository, read-only upstream mirrors, pinned toolchains, current Windows and
WSL2 capabilities, and the continuation order. The project-scoped
[`.grok/config.toml`](.grok/config.toml) exposes the installed Codex CLI to Grok
as the `codex-auditor` MCP server. The handoff requires read-only Codex audits
with preserved request, response, disposition, thread, and hash records. Those
audits supplement the three-reader council and destination-chain evidence; they
do not replace either.

## Status, and the things I do not yet know

This is a buildable foundation with explicit feasibility gates. The shared claim protocol, fixed proof directions, bootstrap manifests, validator behavior and test outcomes are specified; the following dependencies are not yet closed.

The Sprint 2 harness reproduces the 7,705-byte gate roster in Rust and Go, checks the BSB22 byte grammar without performing cryptographic verification, and records dated Midnight and Mithril Preview responses as unsigned observations. Neither destination chain has accepted a bridge-authorized state transition, so the deployment classifier remains `blocked`.

Several items are open and named in the design and the checklist:

- The source-backed catalogs for 42 Cardano and 52 Midnight predicates have not been recovered.
- The selected public Mithril profile has not demonstrated certification of the exact CIP-0165 SCLS entity.
- The Midnight event-to-header-to-MMR inclusion path is missing from the current relay object.
- The full Halo2/KZG decider has not yet been constrained and measured inside the BSB22 wrapper.
- A deployed Midnight operation has not yet accepted the external Cardano proof with atomic state updates.
- No public Cardano validator currently verifies the complete wrapped BEEFY/MMR claim.

I would rather ship a design that says what it does not know than one that hides its gaps behind confident prose.

## Caveats on the corpus

The concept pages carry selective verbatim quotes from their sources, including some engineering material and figures. Where a source is a work in progress, the pages say so. Where a claim is synthesis across sources rather than a single quote, the pages flag it. Treat the design document as the current best reading, not as a specification frozen against any one release.

## License and provenance

The research corpus is a synthesis with per-claim source attribution. Individual upstream sources keep their own licenses; see `knowledge_base/sources/index.md` for the source URLs. The synthesis and prose in this repository are shared for review and discussion.
