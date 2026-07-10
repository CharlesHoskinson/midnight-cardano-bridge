use std::{fs, path::Path};

use serde_json::Value;
use sha2::{Digest, Sha256};

use crate::model::StructuralFixture;
use crate::{cbor, HarnessError, StructuralReport};

const PROFILE_ID: &str = "mcb.structural-lab.sha256-cbor.v1";
const ROOT_DOMAIN: &str = "mcb/deployment-root-set/v1";
const DEPLOYMENT_DOMAIN: &str = "mcb/deployment-domain/v1";
const CONTINUITY_DOMAIN: &str = "mcb/continuity-key/v1";

const FORBIDDEN_ROOT_FIELDS: &[&str] = &[
    "root_set_digest",
    "deployment_domain",
    "registry_activation",
    "registry_activation_digest",
    "artifact_authorization",
    "artifact_authorization_root",
    "destination_abi_instance",
    "destination_abi_instance_digest",
    "concrete_destination_instance_id",
    "deployed_code_hash",
    "runtime_state",
    "job",
    "proof",
    "replay_key",
    "transaction",
    "receipt",
    "run_manifest",
    "run_evidence_manifest",
];

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
    reject_forbidden_fields(&fixture.root_set)?;

    let roster_json_path = repo_root.join(&fixture.roster_json);
    let roster_document: Value = serde_json::from_slice(
        &fs::read(&roster_json_path)
            .map_err(|error| HarnessError::new("roster-read", error.to_string()))?,
    )
    .map_err(|error| HarnessError::new("roster-json", error.to_string()))?;
    let roster = roster_document
        .get("roster")
        .ok_or_else(|| HarnessError::new("roster-shape", "missing roster member"))?;
    let roster_bytes = cbor::encode(roster)?;
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

    let root_set_digest = digest(ROOT_DOMAIN, &cbor::encode(&fixture.root_set)?);
    let deployment_domain = digest(DEPLOYMENT_DOMAIN, &root_set_digest);

    let mut reset_root = fixture.root_set.clone();
    reset_root
        .as_object_mut()
        .ok_or_else(|| HarnessError::new("root-set-shape", "root_set must be an object"))?
        .insert(
            "fresh_deployment_instance_id".into(),
            Value::String(fixture.reset_fresh_deployment_instance_id),
        );
    reject_forbidden_fields(&reset_root)?;
    let reset_root_set_digest = digest(ROOT_DOMAIN, &cbor::encode(&reset_root)?);
    let reset_deployment_domain = digest(DEPLOYMENT_DOMAIN, &reset_root_set_digest);

    let continuity_key = digest(
        CONTINUITY_DOMAIN,
        &cbor::encode(&fixture.source_event_identity)?,
    );
    let reset_continuity_key = digest(
        CONTINUITY_DOMAIN,
        &cbor::encode(&fixture.source_event_identity)?,
    );

    Ok(StructuralReport {
        schema_version: 1,
        profile_id: PROFILE_ID.into(),
        roster_sha256: hex::encode(Sha256::digest(&roster_bytes)),
        roster_cbor_bytes: roster_bytes.len(),
        root_set_digest: hex::encode(root_set_digest),
        deployment_domain: hex::encode(deployment_domain),
        reset_root_set_digest: hex::encode(reset_root_set_digest),
        reset_deployment_domain: hex::encode(reset_deployment_domain),
        continuity_key: hex::encode(continuity_key),
        reset_continuity_key: hex::encode(reset_continuity_key),
        structural_result: "structural-pass".into(),
        deployment_outcome: "blocked".into(),
        activation_eligible: false,
    })
}

fn digest(domain: &str, bytes: &[u8]) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(domain.as_bytes());
    hasher.update(bytes);
    hasher.finalize().into()
}

fn reject_forbidden_fields(value: &Value) -> Result<(), HarnessError> {
    match value {
        Value::Object(fields) => {
            for (name, value) in fields {
                if FORBIDDEN_ROOT_FIELDS.contains(&name.as_str()) {
                    return Err(HarnessError::new(
                        "forbidden-post-domain-field",
                        format!("root-set preimage contains {name}"),
                    ));
                }
                reject_forbidden_fields(value)?;
            }
        }
        Value::Array(values) => {
            for value in values {
                reject_forbidden_fields(value)?;
            }
        }
        _ => {}
    }
    Ok(())
}
