use std::fmt;

use serde::{Deserialize, Serialize};
use serde_json::Value;

#[derive(Debug, Deserialize)]
pub(crate) struct StructuralFixture {
    pub schema_version: u64,
    pub profile_id: String,
    pub roster_json: String,
    pub roster_cbor_hex: String,
    pub root_set: Value,
    pub reset_fresh_deployment_instance_id: String,
    pub source_event_identity: Value,
}

#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, Eq)]
pub struct StructuralReport {
    pub schema_version: u64,
    pub profile_id: String,
    pub roster_sha256: String,
    pub roster_cbor_bytes: usize,
    pub root_set_digest: String,
    pub deployment_domain: String,
    pub reset_root_set_digest: String,
    pub reset_deployment_domain: String,
    pub continuity_key: String,
    pub reset_continuity_key: String,
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
