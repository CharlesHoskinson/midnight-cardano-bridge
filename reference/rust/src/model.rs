use std::fmt;

use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct StructuralFixture {
    pub schema_version: u64,
    pub profile_id: String,
    pub roster_json: String,
    pub roster_cbor_hex: String,
    pub root_set: Value,
    pub producer_dag: ProducerDag,
    pub reset_mode: String,
    pub reset_fresh_deployment_instance_id: String,
    pub source_event_identity: Value,
    pub continuity_replay: ContinuityReplay,
    pub outcome_classifier: OutcomeClassifierInput,
    #[serde(rename = "expected")]
    pub _expected: Value,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct StructuralDeploymentRootSetV1 {
    pub bridge_program_id: String,
    pub fresh_deployment_instance_id: String,
    pub source_identity_fingerprints: Vec<SourceIdentityFingerprint>,
    pub checkpoint_manifest_digests: Vec<String>,
    pub semantic_registry_template_root: String,
    pub artifact_template_root: String,
    pub destination_abi_template_digests: Vec<String>,
    pub deployment_recipe_digests: Vec<String>,
    pub replay_policy_template_digest: String,
    pub freshness_policy_template_digest: String,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct SourceIdentityFingerprint {
    pub chain: String,
    pub identity_digest: String,
    pub protocol_fingerprint: String,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct SourceEventIdentityV1 {
    pub version: u64,
    pub source_chain_identity_digest: String,
    pub source_handler_or_namespace: String,
    pub source_transaction_or_object_id: String,
    pub source_action_or_event_index: u64,
    pub event_discriminator: String,
    pub source_event_commitment: String,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct ContinuityReplay {
    pub imported_consumed_events: Vec<Value>,
    pub unrelated_event: Value,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct ProducerDag {
    pub root_node: String,
    pub nodes: Vec<ProducerNode>,
    pub root_field_producers: RootFieldProducers,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct ProducerNode {
    pub id: String,
    pub stage: String,
    pub dependencies: Vec<String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct RootFieldProducers {
    pub bridge_program_id: String,
    pub fresh_deployment_instance_id: String,
    pub source_identity_fingerprints: String,
    pub checkpoint_manifest_digests: String,
    pub semantic_registry_template_root: String,
    pub artifact_template_root: String,
    pub destination_abi_template_digests: String,
    pub deployment_recipe_digests: String,
    pub replay_policy_template_digest: String,
    pub freshness_policy_template_digest: String,
}

impl RootFieldProducers {
    pub(crate) fn entries(&self) -> [(&'static str, &str, &'static str); 10] {
        [
            (
                "bridge_program_id",
                &self.bridge_program_id,
                "bridge_program",
            ),
            (
                "fresh_deployment_instance_id",
                &self.fresh_deployment_instance_id,
                "deployment_instance",
            ),
            (
                "source_identity_fingerprints",
                &self.source_identity_fingerprints,
                "source_fingerprints",
            ),
            (
                "checkpoint_manifest_digests",
                &self.checkpoint_manifest_digests,
                "checkpoint_manifests",
            ),
            (
                "semantic_registry_template_root",
                &self.semantic_registry_template_root,
                "semantic_registry_template",
            ),
            (
                "artifact_template_root",
                &self.artifact_template_root,
                "artifact_template",
            ),
            (
                "destination_abi_template_digests",
                &self.destination_abi_template_digests,
                "destination_abi_templates",
            ),
            (
                "deployment_recipe_digests",
                &self.deployment_recipe_digests,
                "deployment_recipes",
            ),
            (
                "replay_policy_template_digest",
                &self.replay_policy_template_digest,
                "replay_policy_template",
            ),
            (
                "freshness_policy_template_digest",
                &self.freshness_policy_template_digest,
                "freshness_policy_template",
            ),
        ]
    }
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct OutcomeClassifierInput {
    pub selected_profile: String,
    pub evidence_retention_valid: bool,
    pub cardano_to_midnight: DirectionEvidence,
    pub midnight_to_cardano: DirectionEvidence,
    pub gate_statuses: Vec<GateStatusInput>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct DirectionEvidence {
    pub transition_confirmed: bool,
    pub independent_successor_state_read_confirmed: bool,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub(crate) struct GateStatusInput {
    pub gate_id: String,
    pub status: String,
    pub evidence_digest: String,
    pub evidence_retention_valid: bool,
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq)]
pub struct StructuralReport {
    pub schema_version: u64,
    pub profile_id: String,
    pub roster_sha256: String,
    pub roster_cbor_bytes: usize,
    pub root_set_cbor_hex: String,
    pub root_set_hash_preimage_hex: String,
    pub root_set_digest: String,
    pub deployment_domain_hash_preimage_hex: String,
    pub deployment_domain: String,
    pub reset_mode: String,
    pub reset_root_set_cbor_hex: String,
    pub reset_root_set_hash_preimage_hex: String,
    pub reset_root_set_digest: String,
    pub reset_deployment_domain_hash_preimage_hex: String,
    pub reset_deployment_domain: String,
    pub source_event_identity_cbor_hex: String,
    pub continuity_hash_preimage_hex: String,
    pub continuity_key: String,
    pub reset_source_event_identity_cbor_hex: String,
    pub reset_continuity_hash_preimage_hex: String,
    pub reset_continuity_key: String,
    pub unrelated_source_event_identity_cbor_hex: String,
    pub unrelated_continuity_hash_preimage_hex: String,
    pub unrelated_continuity_key: String,
    pub imported_consumed_continuity_key_count: usize,
    pub same_event_replay_result: String,
    pub unrelated_event_replay_result: String,
    pub producer_dag_valid: bool,
    pub producer_dag_node_count: usize,
    pub gate_record_set_valid: bool,
    pub gate_record_count: usize,
    pub gate_record_set_cbor_hex: String,
    pub gate_record_set_hash_preimage_hex: String,
    pub gate_record_set_digest: String,
    pub open_activation_gate_count: usize,
    pub unresolved_consensus_gate_count: usize,
    pub selected_profile: String,
    pub evidence_retention_valid: bool,
    pub cardano_to_midnight_transition_confirmed: bool,
    pub cardano_to_midnight_successor_state_read_confirmed: bool,
    pub midnight_to_cardano_transition_confirmed: bool,
    pub midnight_to_cardano_successor_state_read_confirmed: bool,
    pub outcome_classifier_row: u8,
    pub classifier_vector_label: String,
    pub structural_result: String,
    pub deployment_outcome: String,
    pub activation_eligible: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HarnessError {
    code: &'static str,
    message: String,
}

impl HarnessError {
    pub(crate) fn new(code: &'static str, message: impl Into<String>) -> Self {
        Self {
            code,
            message: message.into(),
        }
    }

    pub fn code(&self) -> &'static str {
        self.code
    }
}

impl fmt::Display for HarnessError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "{}: {}", self.code, self.message)
    }
}

impl std::error::Error for HarnessError {}
