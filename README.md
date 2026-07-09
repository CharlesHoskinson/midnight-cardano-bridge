# Midnight ↔ Cardano recursive trustless bridge

A design study, and the citation-backed knowledge base behind it, for a two-way trustless bridge between Midnight and Cardano.

The idea is simple to state and hard to build. Instead of trusting a committee of signers to relay messages between the two chains, each chain verifies the other's finality for itself, inside a proof. Recursion compresses the expensive part (checking a chain's history and its finality certificate) into a single succinct proof that the destination chain can check in one shot.

This repository contains the full design document at [`knowledge_base/bridges/midnight-cardano-recursive-bridge.md`](knowledge_base/bridges/midnight-cardano-recursive-bridge.md), plus the research corpus it was synthesized from: 41 pages and about 534 verbatim-cited claims drawn from 38 primary sources.

## Why proofs instead of a committee

Most bridges trust a set of signers. If those signers collude, or their keys leak, the bridge is gone. The public record of nine-figure bridge failures is long enough to make the point.

A trustless bridge removes that party. Security then rests on two things and nothing else: each source chain's own consensus and finality, and the soundness of the proof systems used to check it. There is no new quorum of bridge validators, no multisig, no price oracle sitting in the trust path. A relayer still moves bytes around, but it is untrusted. The on-chain validator reconstructs what it needs and checks a proof.

## The design in one page

The bridge is asymmetric, because the two chains can cheaply verify different things.

For the Midnight to Cardano direction, the natural proof system is Groth16, or more precisely a signature-quorum check that Cardano can run natively. Cardano gained BLS12-381 pairing builtins in [CIP-0381](knowledge_base/standards/cip-0381.md) and a multi-scalar-multiplication builtin in [CIP-0133](knowledge_base/standards/cip-0133.md), so a Plutus validator can verify pairing-based proofs and BLS aggregate signatures on chain. Cardano also has a native ECDSA builtin, which matters because the current relay uses ECDSA (more on that below).

For the Cardano to Midnight direction, the proof system is Plonk or Halo2. Midnight's proving stack ([`midnight-zk`](knowledge_base/midnight/proving-system-curves.md)) is a Plonk system with KZG commitments over BLS12-381, forked from the PSE line of Halo2. It has a universal setup and supports recursion by verifying one proof inside another circuit. A Midnight-side verifier can afford the heavier work of checking a Cardano finality certificate.

The word recursive in the title carries weight. Re-verifying a chain's full header history on every transfer is not viable. Recursion folds "headers 0..N are valid and block N carries a finality certificate" into a single proof, and each step verifies the previous proof plus a small increment. Only the latest proof reaches the destination chain.

## The part that surprised me: both chains already share one curve

The cleanest result in this study is that Midnight and Cardano sit on the same pairing curve, BLS12-381. Midnight proves with KZG over BLS12-381. Cardano verifies BLS12-381 pairings natively through CIP-0381, and IOG has already built a [Halo2-Plutus verifier](knowledge_base/cardano/halo2-plutus-verifier.md) that checks Halo2 and KZG proofs on chain.

Because both sides speak the same curve, each chain can verify the other's finality certificate as a native pairing check rather than emulating a foreign curve inside a circuit. Both finality certificates are BLS aggregate signatures under this design: Midnight can run a [BEEFY](knowledge_base/consensus/beefy.md)-style layer, and Cardano has [Mithril](knowledge_base/cardano/mithril-bls-certificates.md), a stake-threshold BLS multisignature. The shared "at least two thirds signed" argument is the [committee-key / apk-proofs](knowledge_base/proof-systems/apk-proofs-committee-key.md) construction, which Web3 Foundation built for exactly this job: accountable light clients between proof-of-stake chains.

One consequence is that Groth16's per-circuit trusted setup becomes optional. Both chains rely on a universal KZG setup already, so the bridge's residual trust reduces to BLS and pairing soundness plus each chain's honest-stake majority.

## Where the two chains are today, and where this design goes

At launch, Midnight relies on Cardano as a trusted layer. Cardano events are observed by Midnight block producers and written into the ledger as [system transactions](knowledge_base/bridges/cardano-system-transactions.md), with the current cNIGHT bridge approving mainchain transaction hashes in batches. That is federated, not trustless.

In the other direction, Midnight's node ships a `midnight-beefy-relay` that reads a BEEFY signed commitment, an authorities Merkle proof, and an MMR proof, and encodes them as Cardano `PlutusData` for on-chain verification. That is real and running, and it is the closest thing to a trustless leg today. It is also explicitly temporary: a future Midnight release pivots the consensus toward a BABE-based design.

So this document describes the endpoint, not a greenfield rebuild. It replaces the trusted observation with proofs in both directions, and it treats the finality certificate abstractly so the on-chain validator survives the coming consensus change. The certificate's signature scheme and payload can change under it without changing the validator's shape: verify a signature quorum, verify set membership, verify state inclusion, then settle.

## Consensus and finality, stated precisely

Midnight runs a Substrate consensus. Block production is AURA today, not BABE, and finality is GRANDPA. Validators are delegated from Cardano stake pool operators, so the two chains' validator sets overlap rather than merely resemble each other. GRANDPA finality messages are signed with Ed25519. The temporary BEEFY bridge layer signs with ECDSA over secp256k1, which Cardano can verify with its native ECDSA builtin.

The concrete Direction A artifact is fully specified in the relay. A `RelayChainProof` carries a signed commitment (payloads, block number, validator set id, and ECDSA votes) plus a Merkle `AuthoritiesProof` against a `keyset_commitment`. The commitment payload carries the MMR root and the current and next stakes and authority sets, so the validator-set handoff travels inside the signed payload. A Cardano validator that consumes this parses the PlutusData, verifies each ECDSA vote, verifies the Merkle proof, checks that the signing stake clears two thirds, and reads the MMR root for state inclusion.

There is one honest gap worth stating plainly. The Cardano-side on-chain validator that consumes that PlutusData is not in the public `midnight-node` repository (the Aiken file there is an unrelated vesting skeleton). Locating or specifying it is the top open item.

## The Cardano-side anchor for the reverse leg

For Cardano to Midnight, the clean anchor is a canonical ledger-state root. [CIP-0165](knowledge_base/standards/cip-0165.md) defines the Standard Canonical Ledger State: a deterministic CBOR snapshot with a two-level Merkle root pinned to a slot, whose UTxO namespace supports both membership and non-membership proofs. Because every honest node recomputes the same root, that root is what a Mithril BLS certificate can sign. The pipeline becomes: Midnight verifies a Mithril certificate over the SCLS root with one pairing check, then verifies a Merkle path that the Cardano lock UTxO is in that root. No header replay, no trusted indexer.

## How the knowledge base was built

I did not want a design that reads well and cites nothing. Every load-bearing claim in this repository links to a source, and the quotes behind those claims are exact substrings of the source text, checked mechanically. That gate is the reason the corpus under-claims rather than inventing citations: a weaker extraction produces fewer claims, not false ones.

The corpus was assembled with the [deep-research-toolkit](https://github.com/CharlesHoskinson/deep-research-toolkit). The workflow per source is fetch, chunk, extract claims with verbatim quotes, gate the quotes, write a concept page, then compile everything into a DuckDB and LanceDB index that the design synthesis queries. The current state is 38 sources, about 534 gated claims, 41 pages, and a clean link graph.

Sources include the Cardano CIPs (0381, 0133, 0140 Peras, 0165), the Midnight repositories and docs (`midnight-zk`, `midnight-node`, `midnight-ledger`, including the ZKIR v3 documentation from pull request 617), the Polkadot BABE, GRANDPA, and BEEFY material, Mithril, and the Web3 Foundation apk-proofs work. A companion proof-claim taxonomy sits on top, describing the typed claims that applications consume once the bridge has produced a trustworthy anchor.

## How to read this repository

Start with the design document: [`knowledge_base/bridges/midnight-cardano-recursive-bridge.md`](knowledge_base/bridges/midnight-cardano-recursive-bridge.md). It is the synthesis, and it links down into everything else.

The knowledge base is organized by domain:

- `knowledge_base/cardano/` covers Cardano-side verification, finality, and Mithril.
- `knowledge_base/midnight/` covers Midnight's proving stack, consensus, ledger, and ZKIR.
- `knowledge_base/consensus/` covers AURA, GRANDPA, BEEFY, and the signature schemes.
- `knowledge_base/proof-systems/` covers Halo2, commitment Groth16, apk-proofs, and trusted setup.
- `knowledge_base/standards/` holds the CIPs.
- `knowledge_base/proof-claims/` holds the application layer that rides on top of the bridge.
- `knowledge_base/sources/index.md` is the source ledger, one row per source with its URL and a one-line note.

`EXAMINATION-CHECKLIST.md` tracks what still needs work to move this from a draft to a buildable spec. `RESEARCH-PLAN.md` records how the corpus was assembled.

## Status, and the things I do not yet know

This is a draft. It is honest about that. A few items are settled: the shared BLS12-381 substrate, the concrete shape of the current relay artifact, the AURA plus GRANDPA consensus, the Mithril over SCLS anchor for the reverse leg, and the ZKIR v3 pipeline that a Midnight-side verifier circuit compiles through.

Several items are open and named in the design and the checklist:

- The Cardano-side on-chain verifier for the relay's PlutusData is not yet located in public code.
- Midnight's future BABE-design finality format is not published yet, and the design is written to absorb it.
- The exact Mithril BLS12-381 encoding, and the Peras votes-and-certificates format, still need to be pinned from primary sources.
- The measured on-chain cost of the real verifier, at Midnight's actual validator-set size, still needs a benchmark.
- ZKIR v3 is not frozen. The released crate is authoritative, so circuit-level details must be re-pinned against it.

I would rather ship a design that says what it does not know than one that hides its gaps behind confident prose.

## Caveats on the corpus

The concept pages carry selective verbatim quotes from their sources, including some engineering material and figures. Where a source is a work in progress, the pages say so. Where a claim is synthesis across sources rather than a single quote, the pages flag it. Treat the design document as the current best reading, not as a specification frozen against any one release.

## License and provenance

The research corpus is a synthesis with per-claim source attribution. Individual upstream sources keep their own licenses; see `knowledge_base/sources/index.md` for the source URLs. The synthesis and prose in this repository are shared for review and discussion.
