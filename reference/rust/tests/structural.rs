use std::{
    fs,
    path::{Path, PathBuf},
    time::{SystemTime, UNIX_EPOCH},
};

use serde_json::{json, Value};

fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .and_then(Path::parent)
        .expect("reference/rust has a repository parent")
        .to_path_buf()
}

fn fixture(name: &str) -> PathBuf {
    repo_root().join("reference").join("fixtures").join(name)
}

struct TempFixture(PathBuf);

impl TempFixture {
    fn path(&self) -> &Path {
        &self.0
    }
}

impl Drop for TempFixture {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.0);
    }
}

fn mutated_fixture(name: &str, mutate: impl FnOnce(&mut Value)) -> TempFixture {
    let mut value: Value = serde_json::from_slice(
        &fs::read(fixture("structural-v1.json")).expect("read base structural fixture"),
    )
    .expect("decode base structural fixture");
    mutate(&mut value);
    let nonce = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("time after epoch")
        .as_nanos();
    let path = std::env::temp_dir().join(format!("mcb-{name}-{nonce}.json"));
    fs::write(
        &path,
        serde_json::to_vec_pretty(&value).expect("encode mutated fixture"),
    )
    .expect("write mutated fixture");
    TempFixture(path)
}

fn assert_hash_frame(preimage_hex: &str, domain: &str, body_hex: &str) {
    let preimage = hex::decode(preimage_hex).expect("preimage hex");
    let body = hex::decode(body_hex).expect("body hex");
    let domain_len = u64::from_be_bytes(preimage[0..8].try_into().expect("domain length"));
    assert_eq!(domain_len as usize, domain.len());
    let domain_end = 8 + domain.len();
    assert_eq!(&preimage[8..domain_end], domain.as_bytes());
    let body_len = u64::from_be_bytes(
        preimage[domain_end..domain_end + 8]
            .try_into()
            .expect("body length"),
    );
    assert_eq!(body_len as usize, body.len());
    assert_eq!(&preimage[domain_end + 8..], body);
}

#[test]
fn published_roster_reencodes_byte_exactly() {
    let report = mcb_harness::run_fixture(&repo_root(), &fixture("structural-v1.json"))
        .expect("valid structural fixture");
    assert_eq!(
        report.roster_sha256,
        "2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f"
    );
    assert_eq!(report.roster_cbor_bytes, 7_705);
}

#[test]
fn post_domain_root_field_is_rejected() {
    let shared_err =
        mcb_harness::run_fixture(&repo_root(), &fixture("invalid-post-domain-v1.json"))
            .expect_err("shared post-domain fixture must fail");
    assert_eq!(shared_err.code(), "forbidden-post-domain-field");

    let invalid = mutated_fixture("post-domain-root", |value| {
        value["root_set"]["deployment_domain"] =
            json!("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
    });
    let err = mcb_harness::run_fixture(&repo_root(), invalid.path())
        .expect_err("post-domain fields must fail");
    assert_eq!(err.code(), "forbidden-post-domain-field");
}

#[test]
fn reset_changes_domain_but_not_continuity_key() {
    let report = mcb_harness::run_fixture(&repo_root(), &fixture("structural-v1.json"))
        .expect("valid structural fixture");
    assert_ne!(report.root_set_digest, report.reset_root_set_digest);
    assert_ne!(report.deployment_domain, report.reset_deployment_domain);
    assert_eq!(report.continuity_key, report.reset_continuity_key);
    assert_eq!(report.same_event_replay_result, "rejected-consumed");
    assert_eq!(report.unrelated_event_replay_result, "accepted-unused");
    assert_ne!(report.continuity_key, report.unrelated_continuity_key);
    assert_eq!(report.reset_mode, "state-bearing-continuity-migration");
}

#[test]
fn structural_profile_never_activates_or_claims_deployment() {
    let report = mcb_harness::run_fixture(&repo_root(), &fixture("structural-v1.json"))
        .expect("valid structural fixture");
    assert_eq!(report.profile_id, "mcb.structural-lab.sha256-cbor.v1");
    assert_eq!(report.structural_result, "structural-pass");
    assert_eq!(report.deployment_outcome, "blocked");
    assert!(!report.activation_eligible);

    let err = mcb_harness::request_activation("mcb.structural-lab.sha256-cbor.v1")
        .expect_err("structural activation must be rejected");
    assert_eq!(err.code(), "structural-profile-not-activating");
}

#[test]
fn structural_hash_preimages_are_length_framed_and_emitted() {
    let report = mcb_harness::run_fixture(&repo_root(), &fixture("structural-v1.json"))
        .expect("valid structural fixture");

    assert_hash_frame(
        &report.root_set_hash_preimage_hex,
        "mcb/deployment-root-set/v1",
        &report.root_set_cbor_hex,
    );
    assert_hash_frame(
        &report.reset_root_set_hash_preimage_hex,
        "mcb/deployment-root-set/v1",
        &report.reset_root_set_cbor_hex,
    );
    assert_hash_frame(
        &report.deployment_domain_hash_preimage_hex,
        "mcb/deployment-domain/v1",
        &report.root_set_digest,
    );
    assert_hash_frame(
        &report.reset_deployment_domain_hash_preimage_hex,
        "mcb/deployment-domain/v1",
        &report.reset_root_set_digest,
    );
    assert_hash_frame(
        &report.continuity_hash_preimage_hex,
        "mcb/continuity-key/v1",
        &report.source_event_identity_cbor_hex,
    );
    assert_hash_frame(
        &report.gate_record_set_hash_preimage_hex,
        "mcb/structural-gate-record-set/v1",
        &report.gate_record_set_cbor_hex,
    );
}

#[test]
fn exact_structural_schemas_reject_unknown_and_malformed_fields() {
    let cases = [
        (
            "post-domain-root",
            "forbidden-post-domain-field",
            Box::new(|value: &mut Value| {
                value["root_set"]["activation"] = json!({"decision": "activate"});
            }) as Box<dyn Fn(&mut Value)>,
        ),
        (
            "unknown-root",
            "root-set-schema",
            Box::new(|value: &mut Value| {
                value["root_set"]["unexpected"] = json!(1);
            }),
        ),
        (
            "malformed-root",
            "root-set-shape",
            Box::new(|value: &mut Value| {
                value["root_set"] = json!([]);
            }),
        ),
        (
            "unknown-event",
            "source-event-schema",
            Box::new(|value: &mut Value| {
                value["source_event_identity"]["deployment_domain"] = json!("00");
            }),
        ),
        (
            "duplicate-source-chain",
            "root-set-schema",
            Box::new(|value: &mut Value| {
                value["root_set"]["source_identity_fingerprints"][1]["chain"] = json!("cardano");
            }),
        ),
    ];

    for (name, expected, mutate) in cases {
        let fixture = mutated_fixture(name, mutate);
        let err = mcb_harness::run_fixture(&repo_root(), fixture.path())
            .expect_err("invalid typed fixture must fail");
        assert_eq!(err.code(), expected, "case {name}");
    }
}

#[test]
fn producer_dag_rejects_cycle_unresolved_back_edge_and_post_domain_dependency() {
    fn node_mut<'a>(value: &'a mut Value, id: &str) -> &'a mut Value {
        value["producer_dag"]["nodes"]
            .as_array_mut()
            .expect("nodes array")
            .iter_mut()
            .find(|node| node["id"] == id)
            .expect("named node")
    }

    let cases = [
        ("dag-cycle", "producer-cycle"),
        ("dag-unresolved", "unresolved-producer"),
        ("dag-non-forward", "producer-non-forward-edge"),
        ("dag-post-domain", "post-domain-dependency"),
        ("dag-duplicate-id", "duplicate-producer"),
        ("dag-duplicate-dependency", "duplicate-producer-dependency"),
    ];
    for (name, expected) in cases {
        let fixture = mutated_fixture(name, |value| match name {
            "dag-cycle" => {
                node_mut(value, "semantic_registry_template")["dependencies"] =
                    json!(["artifact_template"]);
                node_mut(value, "artifact_template")["dependencies"] =
                    json!(["semantic_registry_template"]);
            }
            "dag-unresolved" => {
                node_mut(value, "semantic_registry_template")["dependencies"] =
                    json!(["missing_producer"]);
            }
            "dag-non-forward" => {
                node_mut(value, "source_descriptors")["dependencies"] =
                    json!(["artifact_template"]);
            }
            "dag-post-domain" => {
                value["producer_dag"]["root_field_producers"]["bridge_program_id"] =
                    json!("registry_activation");
            }
            "dag-duplicate-id" => {
                node_mut(value, "source_descriptors")["id"] = json!("bridge_program");
            }
            "dag-duplicate-dependency" => {
                node_mut(value, "source_fingerprints")["dependencies"] =
                    json!(["source_descriptors", "source_descriptors"]);
            }
            _ => unreachable!(),
        });
        let err = mcb_harness::run_fixture(&repo_root(), fixture.path())
            .expect_err("invalid producer DAG must fail");
        assert_eq!(err.code(), expected, "case {name}");
    }
}

#[test]
fn outcome_classifier_uses_roster_records_and_first_matching_row() {
    let base = mcb_harness::run_fixture(&repo_root(), &fixture("structural-v1.json"))
        .expect("valid structural fixture");
    assert_eq!(base.gate_record_count, 14);
    assert_eq!(base.outcome_classifier_row, 2);
    assert_eq!(base.classifier_vector_label, "blocked");
    assert_eq!(base.deployment_outcome, "blocked");
    assert_eq!(base.open_activation_gate_count, 6);
    assert_eq!(base.unresolved_consensus_gate_count, 8);

    for (name, mutate) in [
        (
            "classifier-row-1-missing",
            Box::new(|value: &mut Value| {
                value["outcome_classifier"]["gate_statuses"]
                    .as_array_mut()
                    .expect("gate statuses")
                    .pop();
            }) as Box<dyn Fn(&mut Value)>,
        ),
        (
            "classifier-row-1-duplicate",
            Box::new(|value: &mut Value| {
                let statuses = value["outcome_classifier"]["gate_statuses"]
                    .as_array_mut()
                    .expect("gate statuses");
                statuses[1]["gate_id"] = json!("S01-BLOCK-01/catalog-completeness");
            }),
        ),
        (
            "classifier-row-1-unknown",
            Box::new(|value: &mut Value| {
                value["outcome_classifier"]["gate_statuses"][0]["gate_id"] = json!("UNKNOWN-GATE");
            }),
        ),
        (
            "classifier-row-1-retention",
            Box::new(|value: &mut Value| {
                value["outcome_classifier"]["evidence_retention_valid"] = json!(false);
            }),
        ),
        (
            "classifier-row-1-not-applicable",
            Box::new(|value: &mut Value| {
                value["outcome_classifier"]["gate_statuses"][1]["status"] = json!("not-applicable");
            }),
        ),
        (
            "classifier-row-1-evidence-digest",
            Box::new(|value: &mut Value| {
                value["outcome_classifier"]["gate_statuses"][0]["evidence_digest"] =
                    json!("not-hex");
            }),
        ),
    ] {
        let invalid = mutated_fixture(name, mutate);
        let row_one = mcb_harness::run_fixture(&repo_root(), invalid.path())
            .expect("invalid classifier input remains an executable row-1 vector");
        assert_eq!(row_one.outcome_classifier_row, 1, "case {name}");
        assert_eq!(row_one.classifier_vector_label, "blocked", "case {name}");
        assert_eq!(row_one.deployment_outcome, "blocked", "case {name}");
    }

    let all_passed = mutated_fixture("classifier-row-3", |value| {
        for status in value["outcome_classifier"]["gate_statuses"]
            .as_array_mut()
            .expect("gate statuses")
        {
            status["status"] = json!("passed");
        }
    });
    let row_three = mcb_harness::run_fixture(&repo_root(), all_passed.path())
        .expect("valid all-passed fixture");
    assert_eq!(row_three.outcome_classifier_row, 3);
    assert_eq!(row_three.classifier_vector_label, "blocked");
    assert_eq!(row_three.deployment_outcome, "blocked");

    let changed_evidence = mutated_fixture("classifier-evidence-binding", |value| {
        value["outcome_classifier"]["gate_statuses"][0]["evidence_digest"] =
            json!("f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1");
    });
    let changed_evidence_report = mcb_harness::run_fixture(&repo_root(), changed_evidence.path())
        .expect("valid changed evidence identity");
    assert_ne!(
        base.gate_record_set_digest,
        changed_evidence_report.gate_record_set_digest
    );

    let lab = mutated_fixture("classifier-row-4", |value| {
        value["outcome_classifier"]["selected_profile"] = json!("lab");
        for status in value["outcome_classifier"]["gate_statuses"]
            .as_array_mut()
            .expect("gate statuses")
        {
            status["status"] = if status["gate_id"] == "S01-BLOCK-02/public-scls-availability" {
                json!("unresolved")
            } else {
                json!("passed")
            };
        }
        for direction in ["cardano_to_midnight", "midnight_to_cardano"] {
            value["outcome_classifier"][direction]["transition_confirmed"] = json!(true);
            value["outcome_classifier"][direction]["independent_successor_state_read_confirmed"] =
                json!(true);
        }
    });
    let row_four = mcb_harness::run_fixture(&repo_root(), lab.path()).expect("valid lab fixture");
    assert_eq!(row_four.outcome_classifier_row, 4);
    assert_eq!(row_four.classifier_vector_label, "degraded-lab");
    assert_eq!(row_four.deployment_outcome, "blocked");
    assert!(!row_four.activation_eligible);

    let confirmed = mutated_fixture("classifier-row-5", |value| {
        for status in value["outcome_classifier"]["gate_statuses"]
            .as_array_mut()
            .expect("gate statuses")
        {
            status["status"] = json!("passed");
        }
        value["outcome_classifier"]["cardano_to_midnight"]["transition_confirmed"] = json!(true);
        value["outcome_classifier"]["cardano_to_midnight"]
            ["independent_successor_state_read_confirmed"] = json!(true);
        value["outcome_classifier"]["midnight_to_cardano"]["transition_confirmed"] = json!(true);
        value["outcome_classifier"]["midnight_to_cardano"]
            ["independent_successor_state_read_confirmed"] = json!(true);
    });
    let row_five =
        mcb_harness::run_fixture(&repo_root(), confirmed.path()).expect("valid confirmed fixture");
    assert_eq!(row_five.outcome_classifier_row, 5);
    assert_eq!(row_five.classifier_vector_label, "live-pass");
    assert_eq!(row_five.deployment_outcome, "blocked");
    assert!(!row_five.activation_eligible);
    assert_eq!(row_five.open_activation_gate_count, 0);
    assert_eq!(row_five.unresolved_consensus_gate_count, 0);
}
