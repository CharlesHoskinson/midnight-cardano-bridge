package harness

import "encoding/json"

type structuralFixture struct {
	SchemaVersion                  uint64                 `json:"schema_version"`
	ProfileID                      string                 `json:"profile_id"`
	RosterJSON                     string                 `json:"roster_json"`
	RosterCBORHex                  string                 `json:"roster_cbor_hex"`
	RootSet                        json.RawMessage        `json:"root_set"`
	ProducerDAG                    producerDAG            `json:"producer_dag"`
	ResetMode                      string                 `json:"reset_mode"`
	ResetFreshDeploymentInstanceID string                 `json:"reset_fresh_deployment_instance_id"`
	SourceEventIdentity            json.RawMessage        `json:"source_event_identity"`
	ContinuityReplay               continuityReplay       `json:"continuity_replay"`
	OutcomeClassifier              outcomeClassifierInput `json:"outcome_classifier"`
	Expected                       json.RawMessage        `json:"expected"`
}

type structuralDeploymentRootSetV1 struct {
	BridgeProgramID               string                      `json:"bridge_program_id"`
	FreshDeploymentInstanceID     string                      `json:"fresh_deployment_instance_id"`
	SourceIdentityFingerprints    []sourceIdentityFingerprint `json:"source_identity_fingerprints"`
	CheckpointManifestDigests     []string                    `json:"checkpoint_manifest_digests"`
	SemanticRegistryTemplateRoot  string                      `json:"semantic_registry_template_root"`
	ArtifactTemplateRoot          string                      `json:"artifact_template_root"`
	DestinationABITemplateDigests []string                    `json:"destination_abi_template_digests"`
	DeploymentRecipeDigests       []string                    `json:"deployment_recipe_digests"`
	ReplayPolicyTemplateDigest    string                      `json:"replay_policy_template_digest"`
	FreshnessPolicyTemplateDigest string                      `json:"freshness_policy_template_digest"`
}

type sourceIdentityFingerprint struct {
	Chain               string `json:"chain"`
	IdentityDigest      string `json:"identity_digest"`
	ProtocolFingerprint string `json:"protocol_fingerprint"`
}

type sourceEventIdentityV1 struct {
	Version                     uint64 `json:"version"`
	SourceChainIdentityDigest   string `json:"source_chain_identity_digest"`
	SourceHandlerOrNamespace    string `json:"source_handler_or_namespace"`
	SourceTransactionOrObjectID string `json:"source_transaction_or_object_id"`
	SourceActionOrEventIndex    uint64 `json:"source_action_or_event_index"`
	EventDiscriminator          string `json:"event_discriminator"`
	SourceEventCommitment       string `json:"source_event_commitment"`
}

type continuityReplay struct {
	ImportedConsumedEvents []json.RawMessage `json:"imported_consumed_events"`
	UnrelatedEvent         json.RawMessage   `json:"unrelated_event"`
}

type producerDAG struct {
	RootNode           string             `json:"root_node"`
	Nodes              []producerNode     `json:"nodes"`
	RootFieldProducers rootFieldProducers `json:"root_field_producers"`
}

type producerNode struct {
	ID           string   `json:"id"`
	Stage        string   `json:"stage"`
	Dependencies []string `json:"dependencies"`
}

type rootFieldProducers struct {
	BridgeProgramID               string `json:"bridge_program_id"`
	FreshDeploymentInstanceID     string `json:"fresh_deployment_instance_id"`
	SourceIdentityFingerprints    string `json:"source_identity_fingerprints"`
	CheckpointManifestDigests     string `json:"checkpoint_manifest_digests"`
	SemanticRegistryTemplateRoot  string `json:"semantic_registry_template_root"`
	ArtifactTemplateRoot          string `json:"artifact_template_root"`
	DestinationABITemplateDigests string `json:"destination_abi_template_digests"`
	DeploymentRecipeDigests       string `json:"deployment_recipe_digests"`
	ReplayPolicyTemplateDigest    string `json:"replay_policy_template_digest"`
	FreshnessPolicyTemplateDigest string `json:"freshness_policy_template_digest"`
}

type outcomeClassifierInput struct {
	SelectedProfile        string            `json:"selected_profile"`
	EvidenceRetentionValid bool              `json:"evidence_retention_valid"`
	CardanoToMidnight      directionEvidence `json:"cardano_to_midnight"`
	MidnightToCardano      directionEvidence `json:"midnight_to_cardano"`
	GateStatuses           []gateStatusInput `json:"gate_statuses"`
}

type directionEvidence struct {
	TransitionConfirmed                    bool `json:"transition_confirmed"`
	IndependentSuccessorStateReadConfirmed bool `json:"independent_successor_state_read_confirmed"`
}

type gateStatusInput struct {
	GateID                 string `json:"gate_id"`
	Status                 string `json:"status"`
	EvidenceDigest         string `json:"evidence_digest"`
	EvidenceRetentionValid bool   `json:"evidence_retention_valid"`
}

type Report struct {
	SchemaVersion                                uint64 `json:"schema_version"`
	ProfileID                                    string `json:"profile_id"`
	RosterSHA256                                 string `json:"roster_sha256"`
	RosterCBORBytes                              int    `json:"roster_cbor_bytes"`
	RootSetCBORHex                               string `json:"root_set_cbor_hex"`
	RootSetHashPreimageHex                       string `json:"root_set_hash_preimage_hex"`
	RootSetDigest                                string `json:"root_set_digest"`
	DeploymentDomainHashPreimageHex              string `json:"deployment_domain_hash_preimage_hex"`
	DeploymentDomain                             string `json:"deployment_domain"`
	ResetMode                                    string `json:"reset_mode"`
	ResetRootSetCBORHex                          string `json:"reset_root_set_cbor_hex"`
	ResetRootSetHashPreimageHex                  string `json:"reset_root_set_hash_preimage_hex"`
	ResetRootSetDigest                           string `json:"reset_root_set_digest"`
	ResetDeploymentDomainHashPreimageHex         string `json:"reset_deployment_domain_hash_preimage_hex"`
	ResetDeploymentDomain                        string `json:"reset_deployment_domain"`
	SourceEventIdentityCBORHex                   string `json:"source_event_identity_cbor_hex"`
	ContinuityHashPreimageHex                    string `json:"continuity_hash_preimage_hex"`
	ContinuityKey                                string `json:"continuity_key"`
	ResetSourceEventIdentityCBORHex              string `json:"reset_source_event_identity_cbor_hex"`
	ResetContinuityHashPreimageHex               string `json:"reset_continuity_hash_preimage_hex"`
	ResetContinuityKey                           string `json:"reset_continuity_key"`
	UnrelatedSourceEventIdentityCBORHex          string `json:"unrelated_source_event_identity_cbor_hex"`
	UnrelatedContinuityHashPreimageHex           string `json:"unrelated_continuity_hash_preimage_hex"`
	UnrelatedContinuityKey                       string `json:"unrelated_continuity_key"`
	ImportedConsumedContinuityKeyCount           int    `json:"imported_consumed_continuity_key_count"`
	SameEventReplayResult                        string `json:"same_event_replay_result"`
	UnrelatedEventReplayResult                   string `json:"unrelated_event_replay_result"`
	ProducerDAGValid                             bool   `json:"producer_dag_valid"`
	ProducerDAGNodeCount                         int    `json:"producer_dag_node_count"`
	GateRecordSetValid                           bool   `json:"gate_record_set_valid"`
	GateRecordCount                              int    `json:"gate_record_count"`
	GateRecordSetCBORHex                         string `json:"gate_record_set_cbor_hex"`
	GateRecordSetHashPreimageHex                 string `json:"gate_record_set_hash_preimage_hex"`
	GateRecordSetDigest                          string `json:"gate_record_set_digest"`
	OpenActivationGateCount                      int    `json:"open_activation_gate_count"`
	UnresolvedConsensusGateCount                 int    `json:"unresolved_consensus_gate_count"`
	SelectedProfile                              string `json:"selected_profile"`
	EvidenceRetentionValid                       bool   `json:"evidence_retention_valid"`
	CardanoToMidnightTransitionConfirmed         bool   `json:"cardano_to_midnight_transition_confirmed"`
	CardanoToMidnightSuccessorStateReadConfirmed bool   `json:"cardano_to_midnight_successor_state_read_confirmed"`
	MidnightToCardanoTransitionConfirmed         bool   `json:"midnight_to_cardano_transition_confirmed"`
	MidnightToCardanoSuccessorStateReadConfirmed bool   `json:"midnight_to_cardano_successor_state_read_confirmed"`
	OutcomeClassifierRow                         uint8  `json:"outcome_classifier_row"`
	ClassifierVectorLabel                        string `json:"classifier_vector_label"`
	StructuralResult                             string `json:"structural_result"`
	DeploymentOutcome                            string `json:"deployment_outcome"`
	ActivationEligible                           bool   `json:"activation_eligible"`
}
