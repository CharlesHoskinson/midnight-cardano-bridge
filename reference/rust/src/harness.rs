use std::{
    collections::{HashMap, HashSet},
    fs,
    path::Path,
};

use serde_json::{Map as JsonMap, Value as JsonValue};
use sha2::{Digest, Sha256};

use crate::cbor::{self, Value as CborValue};
use crate::model::{
    GateStatusInput, OutcomeClassifierInput, ProducerDag, SourceEventIdentityV1,
    StructuralDeploymentRootSetV1, StructuralFixture,
};
use crate::{HarnessError, StructuralReport};

const PROFILE_ID: &str = "mcb.structural-lab.sha256-cbor.v1";
const ROOT_DOMAIN: &str = "mcb/deployment-root-set/v1";
const DEPLOYMENT_DOMAIN: &str = "mcb/deployment-domain/v1";
const CONTINUITY_DOMAIN: &str = "mcb/continuity-key/v1";
const GATE_RECORD_SET_DOMAIN: &str = "mcb/structural-gate-record-set/v1";
const ROSTER_SHA256: &str = "2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f";
const RESET_MODE: &str = "state-bearing-continuity-migration";

const FORBIDDEN_ROOT_FIELDS: &[&str] = &[
    "root_set_digest",
    "deployment_domain",
    "activation",
    "activation_decision",
    "activation_decision_digest",
    "registry_activation",
    "registry_activation_digest",
    "artifact_authorization",
    "artifact_authorization_root",
    "destination_abi_instance",
    "destination_abi_instance_digest",
    "root_context",
    "root_context_digest",
    "concrete_destination_instance_id",
    "deployed_code_hash",
    "runtime_state",
    "cache_authorization",
    "claim",
    "job",
    "proof",
    "replay_key",
    "transaction",
    "receipt",
    "run_intent",
    "run_manifest",
    "run_evidence_manifest",
];

pub fn request_activation(profile_id: &str) -> Result<(), HarnessError> {
    if profile_id == PROFILE_ID {
        return Err(HarnessError::new(
            "structural-profile-not-activating",
            "the structural profile cannot authorize activation or submission",
        ));
    }
    Err(HarnessError::new(
        "unsupported-activation-profile",
        profile_id,
    ))
}

pub fn run_fixture(
    repo_root: &Path,
    fixture_path: &Path,
) -> Result<StructuralReport, HarnessError> {
    let fixture_bytes = fs::read(fixture_path)
        .map_err(|error| HarnessError::new("fixture-read", error.to_string()))?;
    let fixture: StructuralFixture = serde_json::from_slice(&fixture_bytes)
        .map_err(|error| HarnessError::new("fixture-json", error.to_string()))?;
    if fixture.schema_version != 1 || fixture.profile_id != PROFILE_ID {
        return Err(HarnessError::new(
            "unsupported-structural-profile",
            format!("{} version {}", fixture.profile_id, fixture.schema_version),
        ));
    }
    if fixture.reset_mode != RESET_MODE {
        return Err(HarnessError::new("reset-mode", fixture.reset_mode));
    }

    let root_set = parse_root_set(&fixture.root_set)?;
    validate_producer_dag(&fixture.producer_dag)?;
    let source_event = parse_source_event(&fixture.source_event_identity)?;
    let unrelated_event = parse_source_event(&fixture.continuity_replay.unrelated_event)?;

    let roster_document: JsonValue = serde_json::from_slice(
        &fs::read(repo_root.join(&fixture.roster_json))
            .map_err(|error| HarnessError::new("roster-read", error.to_string()))?,
    )
    .map_err(|error| HarnessError::new("roster-json", error.to_string()))?;
    let roster = roster_document
        .get("roster")
        .ok_or_else(|| HarnessError::new("roster-shape", "missing roster member"))?;
    let roster_bytes = cbor::encode_json(roster)?;
    let published_roster = hex::decode(
        fs::read_to_string(repo_root.join(&fixture.roster_cbor_hex))
            .map_err(|error| HarnessError::new("roster-cbor-read", error.to_string()))?
            .trim(),
    )
    .map_err(|error| HarnessError::new("roster-cbor-hex", error.to_string()))?;
    if roster_bytes != published_roster {
        return Err(HarnessError::new(
            "roster-byte-mismatch",
            "deterministic CBOR differs from the publication",
        ));
    }
    let roster_sha256 = hex::encode(Sha256::digest(&roster_bytes));
    if roster_sha256 != ROSTER_SHA256 {
        return Err(HarnessError::new("roster-digest-mismatch", roster_sha256));
    }

    let root_set_cbor = cbor::encode(&build_root_set_cbor(&root_set)?)?;
    let (root_set_preimage, root_set_digest) = framed_digest(ROOT_DOMAIN, &root_set_cbor);
    let (deployment_domain_preimage, deployment_domain) =
        framed_digest(DEPLOYMENT_DOMAIN, &root_set_digest);

    let mut reset_root = root_set.clone();
    reset_root.fresh_deployment_instance_id = fixture.reset_fresh_deployment_instance_id;
    validate_root_set(&reset_root)?;
    let reset_root_set_cbor = cbor::encode(&build_root_set_cbor(&reset_root)?)?;
    let (reset_root_set_preimage, reset_root_set_digest) =
        framed_digest(ROOT_DOMAIN, &reset_root_set_cbor);
    let (reset_deployment_domain_preimage, reset_deployment_domain) =
        framed_digest(DEPLOYMENT_DOMAIN, &reset_root_set_digest);
    if root_set_digest == reset_root_set_digest || deployment_domain == reset_deployment_domain {
        return Err(HarnessError::new(
            "reset-isolation",
            "state-bearing migration must change root-set and deployment domain",
        ));
    }

    let source_event_cbor = cbor::encode(&build_source_event_cbor(&source_event)?)?;
    let (continuity_preimage, continuity_key_bytes) =
        framed_digest(CONTINUITY_DOMAIN, &source_event_cbor);
    let continuity_key = hex::encode(continuity_key_bytes);

    let mut imported_keys = HashSet::new();
    for raw_event in &fixture.continuity_replay.imported_consumed_events {
        let event = parse_source_event(raw_event)?;
        let bytes = cbor::encode(&build_source_event_cbor(&event)?)?;
        let (_, key) = framed_digest(CONTINUITY_DOMAIN, &bytes);
        imported_keys.insert(hex::encode(key));
    }
    let same_event_replay_result = if imported_keys.contains(&continuity_key) {
        "rejected-consumed"
    } else {
        "accepted-unused"
    };
    if same_event_replay_result != "rejected-consumed" {
        return Err(HarnessError::new(
            "continuity-import",
            "candidate event was absent from the imported consumed set",
        ));
    }

    let unrelated_event_cbor = cbor::encode(&build_source_event_cbor(&unrelated_event)?)?;
    let (unrelated_continuity_preimage, unrelated_continuity_key_bytes) =
        framed_digest(CONTINUITY_DOMAIN, &unrelated_event_cbor);
    let unrelated_continuity_key = hex::encode(unrelated_continuity_key_bytes);
    let unrelated_event_replay_result = if imported_keys.contains(&unrelated_continuity_key) {
        "rejected-consumed"
    } else {
        "accepted-unused"
    };
    if unrelated_event_replay_result != "accepted-unused" {
        return Err(HarnessError::new(
            "continuity-unrelated",
            "unrelated event collided with the imported consumed set",
        ));
    }

    let classifier = evaluate_classifier(roster, &fixture.outcome_classifier)?;
    let gate_record_set_cbor = cbor::encode(&build_gate_records_cbor(&classifier.gate_records)?)?;
    let (gate_record_set_preimage, gate_record_set_digest) =
        framed_digest(GATE_RECORD_SET_DOMAIN, &gate_record_set_cbor);

    Ok(StructuralReport {
        schema_version: 1,
        profile_id: PROFILE_ID.into(),
        roster_sha256,
        roster_cbor_bytes: roster_bytes.len(),
        root_set_cbor_hex: hex::encode(&root_set_cbor),
        root_set_hash_preimage_hex: hex::encode(&root_set_preimage),
        root_set_digest: hex::encode(root_set_digest),
        deployment_domain_hash_preimage_hex: hex::encode(&deployment_domain_preimage),
        deployment_domain: hex::encode(deployment_domain),
        reset_mode: RESET_MODE.into(),
        reset_root_set_cbor_hex: hex::encode(&reset_root_set_cbor),
        reset_root_set_hash_preimage_hex: hex::encode(&reset_root_set_preimage),
        reset_root_set_digest: hex::encode(reset_root_set_digest),
        reset_deployment_domain_hash_preimage_hex: hex::encode(&reset_deployment_domain_preimage),
        reset_deployment_domain: hex::encode(reset_deployment_domain),
        source_event_identity_cbor_hex: hex::encode(&source_event_cbor),
        continuity_hash_preimage_hex: hex::encode(&continuity_preimage),
        continuity_key: continuity_key.clone(),
        reset_source_event_identity_cbor_hex: hex::encode(&source_event_cbor),
        reset_continuity_hash_preimage_hex: hex::encode(&continuity_preimage),
        reset_continuity_key: continuity_key,
        unrelated_source_event_identity_cbor_hex: hex::encode(&unrelated_event_cbor),
        unrelated_continuity_hash_preimage_hex: hex::encode(&unrelated_continuity_preimage),
        unrelated_continuity_key,
        imported_consumed_continuity_key_count: imported_keys.len(),
        same_event_replay_result: same_event_replay_result.into(),
        unrelated_event_replay_result: unrelated_event_replay_result.into(),
        producer_dag_valid: true,
        producer_dag_node_count: fixture.producer_dag.nodes.len(),
        gate_record_set_valid: classifier.valid,
        gate_record_count: fixture.outcome_classifier.gate_statuses.len(),
        gate_record_set_cbor_hex: hex::encode(&gate_record_set_cbor),
        gate_record_set_hash_preimage_hex: hex::encode(&gate_record_set_preimage),
        gate_record_set_digest: hex::encode(gate_record_set_digest),
        open_activation_gate_count: fixture
            .outcome_classifier
            .gate_statuses
            .iter()
            .filter(|status| status.gate_id.starts_with("S01-BLOCK-") && status.status != "passed")
            .count(),
        unresolved_consensus_gate_count: fixture
            .outcome_classifier
            .gate_statuses
            .iter()
            .filter(|status| status.gate_id.starts_with("CONS-") && status.status == "unresolved")
            .count(),
        selected_profile: fixture.outcome_classifier.selected_profile.clone(),
        evidence_retention_valid: fixture.outcome_classifier.evidence_retention_valid,
        cardano_to_midnight_transition_confirmed: fixture
            .outcome_classifier
            .cardano_to_midnight
            .transition_confirmed,
        cardano_to_midnight_successor_state_read_confirmed: fixture
            .outcome_classifier
            .cardano_to_midnight
            .independent_successor_state_read_confirmed,
        midnight_to_cardano_transition_confirmed: fixture
            .outcome_classifier
            .midnight_to_cardano
            .transition_confirmed,
        midnight_to_cardano_successor_state_read_confirmed: fixture
            .outcome_classifier
            .midnight_to_cardano
            .independent_successor_state_read_confirmed,
        outcome_classifier_row: classifier.row,
        classifier_vector_label: classifier.label.into(),
        structural_result: "structural-pass".into(),
        deployment_outcome: "blocked".into(),
        activation_eligible: false,
    })
}

fn parse_root_set(value: &JsonValue) -> Result<StructuralDeploymentRootSetV1, HarnessError> {
    let fields = value
        .as_object()
        .ok_or_else(|| HarnessError::new("root-set-shape", "root_set must be an object"))?;
    if let Some(field) = fields
        .keys()
        .find(|field| FORBIDDEN_ROOT_FIELDS.contains(&field.as_str()))
    {
        return Err(HarnessError::new(
            "forbidden-post-domain-field",
            format!("root-set preimage contains {field}"),
        ));
    }
    let root: StructuralDeploymentRootSetV1 = serde_json::from_value(value.clone())
        .map_err(|error| HarnessError::new("root-set-schema", error.to_string()))?;
    validate_root_set(&root)?;
    Ok(root)
}

fn validate_root_set(root: &StructuralDeploymentRootSetV1) -> Result<(), HarnessError> {
    decode_hex(&root.fresh_deployment_instance_id, 16, "root-set-schema")?;
    if root.bridge_program_id.is_empty()
        || root.source_identity_fingerprints.len() != 2
        || root.source_identity_fingerprints[0].chain != "cardano"
        || root.source_identity_fingerprints[1].chain != "midnight"
        || root.checkpoint_manifest_digests.len() != 2
        || root.destination_abi_template_digests.len() != 2
        || root.deployment_recipe_digests.len() != 2
    {
        return Err(HarnessError::new(
            "root-set-schema",
            "bidirectional root-set cardinality or source ordering is invalid",
        ));
    }
    for fingerprint in &root.source_identity_fingerprints {
        if fingerprint.chain.is_empty() {
            return Err(HarnessError::new("root-set-schema", "empty source chain"));
        }
        decode_hex(&fingerprint.identity_digest, 32, "root-set-schema")?;
        decode_hex(&fingerprint.protocol_fingerprint, 32, "root-set-schema")?;
    }
    for digest in root
        .checkpoint_manifest_digests
        .iter()
        .chain(std::iter::once(&root.semantic_registry_template_root))
        .chain(std::iter::once(&root.artifact_template_root))
        .chain(root.destination_abi_template_digests.iter())
        .chain(root.deployment_recipe_digests.iter())
        .chain(std::iter::once(&root.replay_policy_template_digest))
        .chain(std::iter::once(&root.freshness_policy_template_digest))
    {
        decode_hex(digest, 32, "root-set-schema")?;
    }
    for values in [
        &root.checkpoint_manifest_digests,
        &root.destination_abi_template_digests,
        &root.deployment_recipe_digests,
    ] {
        if values.iter().collect::<HashSet<_>>().len() != values.len() {
            return Err(HarnessError::new(
                "root-set-schema",
                "bidirectional digest entries must be unique",
            ));
        }
    }
    Ok(())
}

fn parse_source_event(value: &JsonValue) -> Result<SourceEventIdentityV1, HarnessError> {
    if !value.is_object() {
        return Err(HarnessError::new(
            "source-event-shape",
            "source event must be an object",
        ));
    }
    let event: SourceEventIdentityV1 = serde_json::from_value(value.clone())
        .map_err(|error| HarnessError::new("source-event-schema", error.to_string()))?;
    if event.version != 1
        || event.source_handler_or_namespace.is_empty()
        || event.event_discriminator.is_empty()
    {
        return Err(HarnessError::new(
            "source-event-schema",
            "invalid source event version or identifier",
        ));
    }
    decode_hex(
        &event.source_chain_identity_digest,
        32,
        "source-event-schema",
    )?;
    decode_hex(
        &event.source_transaction_or_object_id,
        32,
        "source-event-schema",
    )?;
    decode_hex(&event.source_event_commitment, 32, "source-event-schema")?;
    Ok(event)
}

fn build_root_set_cbor(root: &StructuralDeploymentRootSetV1) -> Result<CborValue, HarnessError> {
    let fingerprints = root
        .source_identity_fingerprints
        .iter()
        .map(|fingerprint| {
            Ok(CborValue::Map(vec![
                ("chain".into(), CborValue::Text(fingerprint.chain.clone())),
                (
                    "identity_digest".into(),
                    CborValue::Bytes(decode_hex(
                        &fingerprint.identity_digest,
                        32,
                        "root-set-schema",
                    )?),
                ),
                (
                    "protocol_fingerprint".into(),
                    CborValue::Bytes(decode_hex(
                        &fingerprint.protocol_fingerprint,
                        32,
                        "root-set-schema",
                    )?),
                ),
            ]))
        })
        .collect::<Result<Vec<_>, HarnessError>>()?;
    Ok(CborValue::Map(vec![
        (
            "bridge_program_id".into(),
            CborValue::Text(root.bridge_program_id.clone()),
        ),
        (
            "fresh_deployment_instance_id".into(),
            CborValue::Bytes(decode_hex(
                &root.fresh_deployment_instance_id,
                16,
                "root-set-schema",
            )?),
        ),
        (
            "source_identity_fingerprints".into(),
            CborValue::Array(fingerprints),
        ),
        (
            "checkpoint_manifest_digests".into(),
            digest_array(&root.checkpoint_manifest_digests, "root-set-schema")?,
        ),
        (
            "semantic_registry_template_root".into(),
            digest_value(&root.semantic_registry_template_root, "root-set-schema")?,
        ),
        (
            "artifact_template_root".into(),
            digest_value(&root.artifact_template_root, "root-set-schema")?,
        ),
        (
            "destination_abi_template_digests".into(),
            digest_array(&root.destination_abi_template_digests, "root-set-schema")?,
        ),
        (
            "deployment_recipe_digests".into(),
            digest_array(&root.deployment_recipe_digests, "root-set-schema")?,
        ),
        (
            "replay_policy_template_digest".into(),
            digest_value(&root.replay_policy_template_digest, "root-set-schema")?,
        ),
        (
            "freshness_policy_template_digest".into(),
            digest_value(&root.freshness_policy_template_digest, "root-set-schema")?,
        ),
    ]))
}

fn build_gate_records_cbor(records: &JsonValue) -> Result<CborValue, HarnessError> {
    let array = records
        .as_array()
        .ok_or_else(|| HarnessError::new("gate-record-shape", "gate records must be an array"))?;
    let mut out = Vec::with_capacity(array.len());
    for record in array {
        let object = record
            .as_object()
            .ok_or_else(|| HarnessError::new("gate-record-shape", "gate record must be an object"))?;
        let mut entries = Vec::with_capacity(object.len());
        for (key, value) in object {
            let projected = if key == "evidence_digest" {
                match value.as_str() {
                    Some(hex) => match decode_hex(hex, 32, "gate-record-schema") {
                        Ok(bytes) => CborValue::Bytes(bytes),
                        // Invalid overlays remain executable classifier row-1 vectors;
                        // they keep text so encoding does not abort the structural report.
                        Err(_) => CborValue::Text(hex.to_string()),
                    },
                    None => json_to_cbor_value(value)?,
                }
            } else {
                json_to_cbor_value(value)?
            };
            entries.push((key.clone(), projected));
        }
        out.push(CborValue::Map(entries));
    }
    Ok(CborValue::Array(out))
}

fn json_to_cbor_value(value: &JsonValue) -> Result<CborValue, HarnessError> {
    match value {
        JsonValue::Number(number) => number
            .as_u64()
            .map(CborValue::Unsigned)
            .ok_or_else(|| HarnessError::new("unsupported-cbor-value", "only unsigned integers")),
        JsonValue::String(text) => Ok(CborValue::Text(text.clone())),
        JsonValue::Bool(flag) => Ok(CborValue::Bool(*flag)),
        JsonValue::Array(values) => values
            .iter()
            .map(json_to_cbor_value)
            .collect::<Result<Vec<_>, _>>()
            .map(CborValue::Array),
        JsonValue::Object(map) => map
            .iter()
            .map(|(key, value)| Ok((key.clone(), json_to_cbor_value(value)?)))
            .collect::<Result<Vec<_>, _>>()
            .map(CborValue::Map),
        JsonValue::Null => Err(HarnessError::new(
            "unsupported-cbor-value",
            "null is outside the structural profile",
        )),
    }
}

fn build_source_event_cbor(event: &SourceEventIdentityV1) -> Result<CborValue, HarnessError> {
    Ok(CborValue::Map(vec![
        ("version".into(), CborValue::Unsigned(event.version)),
        (
            "source_chain_identity_digest".into(),
            digest_value(&event.source_chain_identity_digest, "source-event-schema")?,
        ),
        (
            "source_handler_or_namespace".into(),
            CborValue::Text(event.source_handler_or_namespace.clone()),
        ),
        (
            "source_transaction_or_object_id".into(),
            digest_value(
                &event.source_transaction_or_object_id,
                "source-event-schema",
            )?,
        ),
        (
            "source_action_or_event_index".into(),
            CborValue::Unsigned(event.source_action_or_event_index),
        ),
        (
            "event_discriminator".into(),
            CborValue::Text(event.event_discriminator.clone()),
        ),
        (
            "source_event_commitment".into(),
            digest_value(&event.source_event_commitment, "source-event-schema")?,
        ),
    ]))
}

fn digest_value(value: &str, code: &'static str) -> Result<CborValue, HarnessError> {
    Ok(CborValue::Bytes(decode_hex(value, 32, code)?))
}

fn digest_array(values: &[String], code: &'static str) -> Result<CborValue, HarnessError> {
    values
        .iter()
        .map(|value| digest_value(value, code))
        .collect::<Result<Vec<_>, _>>()
        .map(CborValue::Array)
}

fn decode_hex(value: &str, bytes: usize, code: &'static str) -> Result<Vec<u8>, HarnessError> {
    let decoded = hex::decode(value).map_err(|error| HarnessError::new(code, error.to_string()))?;
    if decoded.len() != bytes || hex::encode(&decoded) != value {
        return Err(HarnessError::new(
            code,
            format!("expected {bytes} canonical lowercase hexadecimal bytes"),
        ));
    }
    Ok(decoded)
}

fn framed_digest(domain: &str, body: &[u8]) -> (Vec<u8>, [u8; 32]) {
    let mut preimage = Vec::with_capacity(16 + domain.len() + body.len());
    preimage.extend_from_slice(&(domain.len() as u64).to_be_bytes());
    preimage.extend_from_slice(domain.as_bytes());
    preimage.extend_from_slice(&(body.len() as u64).to_be_bytes());
    preimage.extend_from_slice(body);
    let digest = Sha256::digest(&preimage).into();
    (preimage, digest)
}

fn validate_producer_dag(dag: &ProducerDag) -> Result<(), HarnessError> {
    let nodes = dag
        .nodes
        .iter()
        .map(|node| (node.id.as_str(), node))
        .collect::<HashMap<_, _>>();
    if nodes.len() != dag.nodes.len() {
        return Err(HarnessError::new(
            "duplicate-producer",
            "producer ids must be unique",
        ));
    }
    if dag.root_node != "deployment_root_set" || !nodes.contains_key(dag.root_node.as_str()) {
        return Err(HarnessError::new(
            "unresolved-producer",
            "deployment root producer is missing",
        ));
    }
    for node in &dag.nodes {
        stage_rank(&node.stage)?;
        if node.dependencies.iter().collect::<HashSet<_>>().len() != node.dependencies.len() {
            return Err(HarnessError::new(
                "duplicate-producer-dependency",
                format!("{} repeats a dependency", node.id),
            ));
        }
        for dependency in &node.dependencies {
            if !nodes.contains_key(dependency.as_str()) {
                return Err(HarnessError::new(
                    "unresolved-producer",
                    format!("{} depends on {dependency}", node.id),
                ));
            }
        }
    }

    let mut visiting = HashSet::new();
    let mut visited = HashSet::new();
    for node in &dag.nodes {
        visit_producer(node.id.as_str(), &nodes, &mut visiting, &mut visited)?;
    }

    let reachable = reachable_producers(dag.root_node.as_str(), &nodes);
    for (field, producer, expected) in dag.root_field_producers.entries() {
        let node = nodes.get(producer).ok_or_else(|| {
            HarnessError::new(
                "unresolved-producer",
                format!("root field {field} maps to {producer}"),
            )
        })?;
        if node.stage == "post-domain" {
            return Err(HarnessError::new(
                "post-domain-dependency",
                format!("root field {field} maps to {producer}"),
            ));
        }
        if producer != expected || !reachable.contains(producer) {
            return Err(HarnessError::new(
                "root-field-producer-mismatch",
                format!("root field {field} maps to {producer}, expected {expected}"),
            ));
        }
    }
    if reachable.iter().any(|id| nodes[*id].stage == "post-domain") {
        return Err(HarnessError::new(
            "post-domain-dependency",
            "deployment root reaches a post-domain producer",
        ));
    }
    for node in &dag.nodes {
        let node_rank = stage_rank(&node.stage)?;
        for dependency in &node.dependencies {
            let dependency_rank = stage_rank(&nodes[dependency.as_str()].stage)?;
            if dependency_rank >= node_rank {
                return Err(HarnessError::new(
                    "producer-non-forward-edge",
                    format!("{} depends on {dependency}", node.id),
                ));
            }
        }
    }
    Ok(())
}

fn stage_rank(stage: &str) -> Result<u8, HarnessError> {
    match stage {
        "source" => Ok(0),
        "template" => Ok(1),
        "manifest" => Ok(2),
        "root-set" => Ok(3),
        "root-digest" => Ok(4),
        "domain" => Ok(5),
        "post-domain" => Ok(6),
        _ => Err(HarnessError::new("producer-stage", stage)),
    }
}

fn visit_producer<'a>(
    id: &'a str,
    nodes: &HashMap<&'a str, &'a crate::model::ProducerNode>,
    visiting: &mut HashSet<&'a str>,
    visited: &mut HashSet<&'a str>,
) -> Result<(), HarnessError> {
    if visited.contains(id) {
        return Ok(());
    }
    if !visiting.insert(id) {
        return Err(HarnessError::new(
            "producer-cycle",
            format!("cycle reaches {id}"),
        ));
    }
    for dependency in &nodes[id].dependencies {
        visit_producer(dependency.as_str(), nodes, visiting, visited)?;
    }
    visiting.remove(id);
    visited.insert(id);
    Ok(())
}

fn reachable_producers<'a>(
    root: &'a str,
    nodes: &HashMap<&'a str, &'a crate::model::ProducerNode>,
) -> HashSet<&'a str> {
    let mut reachable = HashSet::new();
    let mut stack = vec![root];
    while let Some(id) = stack.pop() {
        if reachable.insert(id) {
            stack.extend(nodes[id].dependencies.iter().map(String::as_str));
        }
    }
    reachable
}

struct ClassifierResult {
    row: u8,
    label: &'static str,
    valid: bool,
    gate_records: JsonValue,
}

fn evaluate_classifier(
    roster: &JsonValue,
    input: &OutcomeClassifierInput,
) -> Result<ClassifierResult, HarnessError> {
    let entries = roster
        .get("entries")
        .and_then(JsonValue::as_array)
        .ok_or_else(|| HarnessError::new("roster-shape", "missing entries"))?;
    let mut records = Vec::with_capacity(input.gate_statuses.len());
    for status in &input.gate_statuses {
        let mut record = entries
            .iter()
            .find(|entry| entry.get("gate_id").and_then(JsonValue::as_str) == Some(&status.gate_id))
            .and_then(JsonValue::as_object)
            .cloned()
            .unwrap_or_else(JsonMap::new);
        record.insert("gate_id".into(), JsonValue::String(status.gate_id.clone()));
        record.insert("status".into(), JsonValue::String(status.status.clone()));
        record.insert(
            "evidence_digest".into(),
            JsonValue::String(status.evidence_digest.clone()),
        );
        record.insert(
            "evidence_retention_valid".into(),
            JsonValue::Bool(status.evidence_retention_valid),
        );
        records.push(JsonValue::Object(record));
    }

    let mut valid = matches!(input.selected_profile.as_str(), "public" | "lab")
        && input.evidence_retention_valid
        && input.gate_statuses.len() == entries.len();
    let mut seen = HashSet::new();
    for (index, status) in input.gate_statuses.iter().enumerate() {
        let expected = entries
            .get(index)
            .and_then(|entry| entry.get("gate_id"))
            .and_then(JsonValue::as_str);
        if expected != Some(status.gate_id.as_str()) || !seen.insert(status.gate_id.as_str()) {
            valid = false;
        }
        if !matches!(
            status.status.as_str(),
            "unresolved" | "passed" | "failed" | "mocked" | "not-applicable"
        ) || status.status == "not-applicable"
            || !status.evidence_retention_valid
            || decode_hex(&status.evidence_digest, 32, "gate-evidence-digest").is_err()
        {
            valid = false;
        }
        if let Some(entry) = entries.get(index) {
            let applicability = entry
                .get("applicability")
                .and_then(|value| value.get(input.selected_profile.as_str()))
                .and_then(JsonValue::as_str);
            match applicability {
                Some("required" | "public-only") => {}
                _ => valid = false,
            }
        } else {
            valid = false;
        }
    }
    if !valid {
        return Ok(ClassifierResult {
            row: 1,
            label: "blocked",
            valid: false,
            gate_records: JsonValue::Array(records),
        });
    }

    if has_unpassed_required(entries, &input.gate_statuses, &input.selected_profile) {
        return Ok(ClassifierResult {
            row: 2,
            label: "blocked",
            valid: true,
            gate_records: JsonValue::Array(records),
        });
    }
    let directions_confirmed = input.cardano_to_midnight.transition_confirmed
        && input
            .cardano_to_midnight
            .independent_successor_state_read_confirmed
        && input.midnight_to_cardano.transition_confirmed
        && input
            .midnight_to_cardano
            .independent_successor_state_read_confirmed;
    if !directions_confirmed {
        return Ok(ClassifierResult {
            row: 3,
            label: "blocked",
            valid: true,
            gate_records: JsonValue::Array(records),
        });
    }
    let (row, label) = if input.selected_profile == "lab" {
        (4, "degraded-lab")
    } else {
        (5, "live-pass")
    };
    Ok(ClassifierResult {
        row,
        label,
        valid: true,
        gate_records: JsonValue::Array(records),
    })
}

fn has_unpassed_required(
    entries: &[JsonValue],
    statuses: &[GateStatusInput],
    profile: &str,
) -> bool {
    entries.iter().zip(statuses).any(|(entry, status)| {
        entry
            .get("applicability")
            .and_then(|value| value.get(profile))
            .and_then(JsonValue::as_str)
            == Some("required")
            && status.status != "passed"
    })
}
