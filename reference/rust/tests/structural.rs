use std::path::{Path, PathBuf};

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
    let err = mcb_harness::run_fixture(&repo_root(), &fixture("invalid-post-domain-v1.json"))
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
}

#[test]
fn structural_profile_never_activates_or_claims_deployment() {
    let report = mcb_harness::run_fixture(&repo_root(), &fixture("structural-v1.json"))
        .expect("valid structural fixture");
    assert_eq!(report.profile_id, "mcb.structural-lab.sha256-cbor.v1");
    assert_eq!(report.structural_result, "structural-pass");
    assert_eq!(report.deployment_outcome, "blocked");
    assert!(!report.activation_eligible);
}
