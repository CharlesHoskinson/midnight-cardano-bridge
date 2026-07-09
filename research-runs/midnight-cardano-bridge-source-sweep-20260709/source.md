# Midnight Cardano Bridge Source Sweep 2026-07-09

This source pack captures exact excerpts from public upstream checkouts used for
the bridge checklist sweep. The run is structured for the deep-research-toolkit
web-style claim gate; every claim quote is copied from one of the excerpts below.

## Relay PlutusData encoding

Source: `_external/midnight-node/relay/src/cardano_encoding.rs`

```rust
use sp_consensus_beefy::known_payloads::MMR_ROOT_ID;

// Known encoding tag
pub const TAG: u64 = 121;

pub struct RelayChainProof {
    pub signed_commitment: SignedCommitment,
    pub proof: AuthoritiesProof,
}

fields: MaybeIndefArray::Indef(vec![
    self.signed_commitment.to_plutus_data(),
    self.proof.to_plutus_data(),
])

.get_all_raw(&MMR_ROOT_ID)
.map(|i| Payload { id: MMR_ROOT_ID.to_vec(), data: i.clone() })

// Substrate adds an extra byte to these signatures. We'll remove this manually for compatibility
signature.pop();
```

## Authority proof hashing

Source: `_external/midnight-node/relay/src/authorities.rs`

```rust
/// Returns AuthoritiesProof, using Keccak256 hashing

fn prep_leaf_hash(beefy_stake: BeefyStake<BeefyId>) -> Hash {
    // convert public key to bytes
    let mut data = beefy_stake.0.into_inner().0.to_vec();

    // convert stake to bytes
    let stake_bytes = beefy_stake.1.to_le_bytes();
    data.extend_from_slice(&stake_bytes);
}
```

## Runtime BEEFY stakes and MMR leaf

Source: `_external/midnight-node/runtime/src/beefy.rs` and `_external/midnight-node/runtime/src/lib.rs`

```rust
beefy_with_stakes.push((
    validator, 1, // default stake
));

log::warn!(target: BEEFY_LOG_TARGET, "No match found for {validator}, still setting stake to 1");
beefy_with_stakes.push((validator, 1));
```

```rust
type LeafData = pallet_beefy_mmr::Pallet<Runtime>;
type OnNewRoot = pallet_beefy_mmr::DepositBeefyDigest<Runtime>;

parameter_types! {
    pub const MaxAuthorities: u32 = 10_000;
}

input.d_parameter.num_permissioned_candidates = d_parameter.num_permissioned_candidates;
input.d_parameter.num_registered_candidates = d_parameter.num_registered_candidates;
```

## Relayer proof flow

Source: `_external/midnight-node/relay/src/relayer.rs`

```rust
.subscribe(
    "beefy_subscribeJustifications",
    rpc_params![],
    "beefy_unsubscribeJustifications",
)

let relay_chain_proof = RelayChainProof::generate(beef_signed_commitment, validator_set)?;

let plutus_data = relay_chain_proof.to_plutus_data();

let raw_proof_data = self.rpc.request_raw("mmr_generateProof", params.build()).await?;
```

## Cardano to Midnight bridge approval gate

Source: `_external/midnight-node/pallets/c2m-bridge/src/lib.rs`

```rust
/// Maximum number of approved mainchain transaction hashes that can be added in a single batch.
pub const MAX_APPROVALS_PER_BATCH: u32 = 32;

/// mNIGHT to the recipient. Modeled as a map-with-unit-value: presence of a key
/// denotes membership; absence denotes non-membership.
pub type ApprovedMcTxHashes<T: Config> =
    StorageMap<_, Blake2_128Concat, McTxHash, (), OptionQuery>;

pub fn add_approved_mc_tx_hashes(
    origin: OriginFor<T>,
    hashes: BoundedVec<McTxHash, ConstU32<MAX_APPROVALS_PER_BATCH>>,
) -> DispatchResult {
    T::GovernanceOrigin::ensure_origin(origin)?;
    for hash in hashes {
        ApprovedMcTxHashes::<T>::insert(hash, ());
    }
    Ok(())
}

// Approval is single-use: remove before executing so a failed ledger call
// cannot be replayed against the same approval.
match ApprovedMcTxHashes::<T>::take(mc_tx_hash) {
    None => {
        // Not pre-approved by governance -- redirect funds to the Treasury.
        Self::execute_serialized_tx(
            LedgerApi::construct_unlock_to_treasury_system_tx(amount.into()),
```

## Mithril STM BLS evidence

Source: `_external/mithril/mithril-stm/Cargo.toml` and `_external/mithril/mithril-stm/src/lib.rs`

```toml
# Enforce blst portable feature for runtime detection of Intel ADX instruction set.
blst = { version = "0.3.16", features = ["portable"] }
midnight-curves = { version = "=0.2.0", optional = true }
```

```rust
pub use signature_scheme::{
    BlsProofOfPossession, BlsSignature, BlsSigningKey, BlsVerificationKey,
};

pub use proof_system::{AggregateVerificationKeyForSnark, MERKLE_TREE_DEPTH_FOR_SNARK, SnarkProof};
```

## Midnight proof aggregation and SRS

Source: `_external/midnight-zk/aggregation/src/multi_circuit_aggregator/mod.rs` and `_external/midnight-zk/zk_stdlib/src/utils/plonk_api.rs`

```rust
//! This module provides an IVC-based proof aggregator that can aggregate proofs
//! from different inner circuits (i.e. circuits with different verifying keys)
//! into a single succinct proof.

//! A verifier receives the final IVC proof together with the list of claims.
//! The public instance of the IVC proof is composed of the claims digest
//! (the tip of a Poseidon hash chain) and the inner-proof accumulator. Both are
//! constant-size regardless of how many proofs were aggregated.

//! 2. Check that the aggregated claims are acceptable. Step 1 guarantees that
//!    every claim has a valid inner proof, but says nothing about *what* was
//!    proved. It is up to the verifier to decide whether the claims are
//!    meaningful by checking that each VK belongs to a trusted circuit, whose
//!    setup was run by the verifier and whose architecture is the expected one.

pub enum SrsSource {
    Filecoin,
    Midnight,
}

/// Loads an SRS (over BLS12-381) for the given circuit size `k` and
/// constraint-system degree `cs_degree`.

/// Loads Midnight's production SRS (over BLS12-381) for the given circuit
/// size `k` (log2 of the number of rows).
```

## Cardano signature builtins and Midnight token model

Source: `_external/CIPs/CIP-0049/README.md`, `_external/midnight-ledger/spec/dust.md`, and `_external/midnight-ledger/coin-structure/src/coin.rs`

```markdown
Support ECDSA and Schnorr signatures over the SECP256k1 curve in Plutus Core;
specifically, allow validation of such signatures as builtins.

* `verifyEcdsaSecp256k1Signature :: BuiltinByteString -> BuiltinByteString ->
  BuiltinByteString -> BuiltinBool`, for verifying 32-byte message hashes signed
  using the ECDSA signature scheme on the SECP256k1 curve; and
* `verifySchnorrSecp256k1Signature :: BuiltinByteString -> BuiltinByteString
  -> BuiltinByteString -> BuiltinBool`, for verifying arbitrary binary messages
  signed using the Schnorr signature scheme on the SECP256k1 curve.
```

```markdown
Dust operates similarly to, but separately from, [Zswap](./zswap.md). It
operates as the fee payment token of Midnight, but has the following unique
properties:

- Dust is a shielded token, but is not transferable, instead being usable only
  for fees.
- The value of a Dust UTXO is dynamically computed and derived from an
  associated Night UTXO.
```

```rust
pub enum TokenType {
    Unshielded(UnshieldedTokenType),
    Shielded(ShieldedTokenType),
    Dust,
}

pub const NIGHT: UnshieldedTokenType = UnshieldedTokenType(HashOutput([0u8; 32]));
```
