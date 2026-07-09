---
type: Concept
title: Midnight transaction types — Standard/ClaimRewards + 9 system-transaction variants
timestamp: '2026-07-09T16:08:57Z'
description: 'The Midnight ledger-9 transaction catalog: user transactions (Standard
  carries ZK proofs + signatures and pays DUST fees; ClaimRewards is signature-only)
  versus 9 unproven consensus-authorized SystemTransaction variants, and what that
  split means for a bridge.'
resource: https://github.com/midnightntwrk/midnight-ledger/blob/tna/feature-documentation-zkir_v3/spec/transaction-types.md
tags:
- midnight
- transaction
- system-transaction
- standard-transaction
- dust
- ledger-9
- pr-617
- state
source: src-0032
status: researched
okf_version: '1.0'
---

# Midnight transaction types — Standard/ClaimRewards + 9 system-transaction variants

Source: **[midnight-ledger PR #617](https://github.com/midnightntwrk/midnight-ledger/blob/tna/feature-documentation-zkir_v3/spec/transaction-types.md)** (open PR, base **ledger-9**) — the authoritative catalog of every Midnight transaction *type / variant*. For a [Midnight <-> Cardano recursive trustless bridge](/bridges/midnight-cardano-recursive-bridge.md), this is the tx/state model a bridge must attest: it fixes **which state changes are user-proven versus consensus-authorized**.

## Two layers of transaction

[Midnight](/index.md) has **two layers** of "transaction", and the split is the load-bearing fact for a bridge:

- **User transactions** — the user-facing `Transaction` enum (`transaction[v12]`) with exactly two variants:
  - `Transaction::Standard` -> `StandardTransaction`: the general-purpose transaction (shielded Zswap + unshielded Night transfers, contract deploys/calls/maintenance, DUST fee payment). Submitted by users/wallets, **pays DUST fees**, and **carries ZK proofs + signatures**. Its validity is enforced by `Transaction::well_formed` (balancing per `(token, segment)`, Pedersen commitment openings, 1-to-1 `Effects` matching, proof + signature verification).
  - `Transaction::ClaimRewards` -> `ClaimRewardsTransaction`: a deliberately minimal, **proof-free** transaction (**signature only**) that withdraws accrued Night — block rewards or Cardano-bridge receipts — into a spendable UTXO. Fee is paid from the claim.

- **System transactions** — `SystemTransaction` (`system-transaction[v9]`, `#[non_exhaustive]`), a **separate type with 9 variants**. Created by the chain/consensus layer (block production, the partner-chain / Cardano bridge, governance), applied directly to `LedgerState` via `LedgerState::apply_system_tx`, **never submitted in a block as a user `Transaction`**. They **carry no fees, signatures, or proofs** and are logged as `[privileged]`.

## User-proven vs consensus-authorized (the bridge-relevant split)

The critical asymmetry: user transactions carry their own cryptographic authorization (ZK proofs and/or signatures that the ledger verifies), whereas **system transactions are unauthenticated / unproven because their authority comes from the consensus layer that produces them**. A bridge attesting Midnight state must therefore reason about two distinct trust roots:

- state changes from `Transaction::Standard` are backed by verifiable ZK proofs + signatures on-chain;
- state changes from `SystemTransaction` are backed only by consensus (block validity), not by any in-transaction proof.

This directly parallels the [Cardano system-transaction](/bridges/cardano-system-transactions.md) reasoning and the proof model in [Compact circuits](/midnight/compact-circuits.md): a recursive proof can attest what a Standard tx proved, but system-transaction effects must be justified by attesting consensus, not a per-tx proof.

A single global invariant governs the privileged path: **Night is conserved across four pools** — `treasury`, `reserve_pool`, `block_reward_pool`, `locked_pool` — and a payout is rejected if the source pool is insufficient.

## The 9 SystemTransaction variants

| Variant | Purpose | Pool movement / note |
|---|---|---|
| `OverwriteParameters` | replace the active `LedgerParameters` (cost model, limits, dust, fees, TTL, bridge params) | emits `ParamChange`; bridge fee basis points must be `<= 10_000` |
| `DistributeNight` | credit Night to addresses from a pool, by `ClaimKind` | `Reward` credits `unclaimed_block_rewards`; `CardanoBridge` deducts bridge fee to `treasury`, credits `bridge_receiving`; replay-protected per output |
| `PayBlockRewardsToTreasury` | move block-reward Night into the treasury | `amount <= block_reward_pool` |
| `DistributeReserve` | release reserve Night into the block-reward pool (emission) | `reserve_pool -> block_reward_pool` |
| `CNightGeneratesDustUpdate` | register / deregister cardano-Night -> DUST generation | `Create`/`Destroy` dust-generation entries |
| `UnlockToTreasury` | release Night from the locked (Cardano-bridge) pool into the treasury | `locked_pool -> treasury` |
| `UnlockToReserve` | release Night from the locked pool into the reserve pool | `locked_pool -> reserve_pool` |
| `PayFromTreasuryShielded` | (intended) pay shielded outputs from the treasury | **DISABLED** — returns `TreasuryDisabled` |
| `PayFromTreasuryUnshielded` | (intended) pay unshielded outputs from the treasury | **DISABLED** — returns `TreasuryDisabled` |

Note how the user and system layers interlock: a `ClaimRewards` transaction claims a balance that was previously credited to `unclaimed_block_rewards` / `bridge_receiving` by a `DistributeNight` **system** transaction — i.e. consensus authorizes the credit, and the user proves (via signature) the withdrawal.

## Bridge relevance

For the [recursive trustless bridge](/bridges/midnight-cardano-recursive-bridge.md), this catalog delimits what a Midnight-side attestation can and cannot cover with a proof alone. Cardano-bridge inflows arrive via `DistributeNight(CardanoBridge)` and the `locked_pool` (`UnlockToTreasury` / `UnlockToReserve`); DUST generation from cardano-Night is registered by `CNightGeneratesDustUpdate`. All of these are consensus-authorized, so bridge trust for those paths reduces to attesting Midnight consensus, while `Standard` transaction effects reduce to verifying their embedded proofs.

## Sources

- [Sources index](/sources/index.md) — src-0032 (this catalog).