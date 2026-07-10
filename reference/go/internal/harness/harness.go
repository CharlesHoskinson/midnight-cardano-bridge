package harness

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/charleshoskinson/midnight-cardano-bridge/reference/go/internal/canon"
)

const (
	profileID           = "mcb.structural-lab.sha256-cbor.v1"
	rootDomain          = "mcb/deployment-root-set/v1"
	deploymentDomain    = "mcb/deployment-domain/v1"
	continuityDomain    = "mcb/continuity-key/v1"
	gateRecordSetDomain = "mcb/structural-gate-record-set/v1"
	rosterSHA256        = "2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f"
	resetMode           = "state-bearing-continuity-migration"
)

var forbiddenRootFields = map[string]struct{}{
	"root_set_digest": {}, "deployment_domain": {}, "activation": {},
	"activation_decision": {}, "activation_decision_digest": {},
	"registry_activation": {}, "registry_activation_digest": {},
	"artifact_authorization": {}, "artifact_authorization_root": {},
	"destination_abi_instance": {}, "destination_abi_instance_digest": {},
	"root_context": {}, "root_context_digest": {}, "concrete_destination_instance_id": {},
	"deployed_code_hash": {}, "runtime_state": {}, "cache_authorization": {},
	"claim": {}, "job": {}, "proof": {}, "replay_key": {}, "transaction": {},
	"receipt": {}, "run_intent": {}, "run_manifest": {}, "run_evidence_manifest": {},
}

type HarnessError struct {
	Code    string
	Message string
}

func (e *HarnessError) Error() string { return e.Code + ": " + e.Message }

func ErrorCode(err error) string {
	if typed, ok := err.(*HarnessError); ok {
		return typed.Code
	}
	return ""
}

func RequestActivation(requestedProfileID string) error {
	if requestedProfileID == profileID {
		return &HarnessError{"structural-profile-not-activating", "the structural profile cannot authorize activation or submission"}
	}
	return &HarnessError{"unsupported-activation-profile", requestedProfileID}
}

func RunFixture(repoRoot, fixturePath string) (Report, error) {
	fixtureBytes, err := os.ReadFile(fixturePath)
	if err != nil {
		return Report{}, fail("fixture-read", err)
	}
	var input structuralFixture
	if err := decodeStrict(fixtureBytes, &input); err != nil {
		return Report{}, fail("fixture-json", err)
	}
	if input.SchemaVersion != 1 || input.ProfileID != profileID {
		return Report{}, &HarnessError{"unsupported-structural-profile", input.ProfileID}
	}
	if input.ResetMode != resetMode {
		return Report{}, &HarnessError{"reset-mode", input.ResetMode}
	}
	rootSet, err := parseRootSet(input.RootSet)
	if err != nil {
		return Report{}, err
	}
	if err := validateProducerDAG(input.ProducerDAG); err != nil {
		return Report{}, err
	}
	sourceEvent, err := parseSourceEvent(input.SourceEventIdentity)
	if err != nil {
		return Report{}, err
	}
	unrelatedEvent, err := parseSourceEvent(input.ContinuityReplay.UnrelatedEvent)
	if err != nil {
		return Report{}, err
	}

	rosterJSON, err := os.ReadFile(filepath.Join(repoRoot, filepath.FromSlash(input.RosterJSON)))
	if err != nil {
		return Report{}, fail("roster-read", err)
	}
	rosterDocument, err := decodeJSON(rosterJSON)
	if err != nil {
		return Report{}, fail("roster-json", err)
	}
	roster, ok := rosterDocument.(map[string]any)["roster"].(map[string]any)
	if !ok {
		return Report{}, &HarnessError{"roster-shape", "missing roster member"}
	}
	rosterCBOR, err := canon.Encode(roster)
	if err != nil {
		return Report{}, fail("roster-cbor", err)
	}
	publishedHex, err := os.ReadFile(filepath.Join(repoRoot, filepath.FromSlash(input.RosterCBORHex)))
	if err != nil {
		return Report{}, fail("roster-cbor-read", err)
	}
	published, err := hex.DecodeString(strings.TrimSpace(string(publishedHex)))
	if err != nil {
		return Report{}, fail("roster-cbor-hex", err)
	}
	if !bytes.Equal(rosterCBOR, published) {
		return Report{}, &HarnessError{"roster-byte-mismatch", "deterministic CBOR differs from publication"}
	}
	rosterHash := sha256.Sum256(rosterCBOR)
	rosterDigest := hex.EncodeToString(rosterHash[:])
	if rosterDigest != rosterSHA256 {
		return Report{}, &HarnessError{"roster-digest-mismatch", rosterDigest}
	}

	rootCBOR, err := canon.Encode(rootSetCBORValue(rootSet))
	if err != nil {
		return Report{}, fail("root-set-cbor", err)
	}
	rootPreimage, rootDigest := framedDigest(rootDomain, rootCBOR)
	domainPreimage, domainDigest := framedDigest(deploymentDomain, rootDigest[:])

	resetRoot := rootSet
	resetRoot.FreshDeploymentInstanceID = input.ResetFreshDeploymentInstanceID
	if err := validateRootSet(resetRoot); err != nil {
		return Report{}, err
	}
	resetCBOR, err := canon.Encode(rootSetCBORValue(resetRoot))
	if err != nil {
		return Report{}, fail("reset-root-cbor", err)
	}
	resetRootPreimage, resetRootDigest := framedDigest(rootDomain, resetCBOR)
	resetDomainPreimage, resetDomainDigest := framedDigest(deploymentDomain, resetRootDigest[:])
	if rootDigest == resetRootDigest || domainDigest == resetDomainDigest {
		return Report{}, &HarnessError{"reset-isolation", "state-bearing migration must change root-set and deployment domain"}
	}

	eventCBOR, err := canon.Encode(sourceEventCBORValue(sourceEvent))
	if err != nil {
		return Report{}, fail("source-event-cbor", err)
	}
	continuityPreimage, continuityDigest := framedDigest(continuityDomain, eventCBOR)
	continuityKey := hex.EncodeToString(continuityDigest[:])
	importedKeys := map[string]bool{}
	for _, raw := range input.ContinuityReplay.ImportedConsumedEvents {
		event, err := parseSourceEvent(raw)
		if err != nil {
			return Report{}, err
		}
		encoded, err := canon.Encode(sourceEventCBORValue(event))
		if err != nil {
			return Report{}, fail("source-event-cbor", err)
		}
		_, digest := framedDigest(continuityDomain, encoded)
		importedKeys[hex.EncodeToString(digest[:])] = true
	}
	sameResult := "accepted-unused"
	if importedKeys[continuityKey] {
		sameResult = "rejected-consumed"
	}
	if sameResult != "rejected-consumed" {
		return Report{}, &HarnessError{"continuity-import", "candidate event was absent from imported consumed set"}
	}
	unrelatedEventCBOR, err := canon.Encode(sourceEventCBORValue(unrelatedEvent))
	if err != nil {
		return Report{}, fail("source-event-cbor", err)
	}
	unrelatedPreimage, unrelatedDigest := framedDigest(continuityDomain, unrelatedEventCBOR)
	unrelatedKey := hex.EncodeToString(unrelatedDigest[:])
	unrelatedResult := "accepted-unused"
	if importedKeys[unrelatedKey] {
		unrelatedResult = "rejected-consumed"
	}
	if unrelatedResult != "accepted-unused" {
		return Report{}, &HarnessError{"continuity-unrelated", "unrelated event collided with imported consumed set"}
	}

	classifier, err := evaluateClassifier(roster, input.OutcomeClassifier)
	if err != nil {
		return Report{}, err
	}
	gateRecordCBOR, err := canon.Encode(classifier.gateRecords)
	if err != nil {
		return Report{}, fail("gate-record-set-cbor", err)
	}
	gateRecordPreimage, gateRecordDigest := framedDigest(gateRecordSetDomain, gateRecordCBOR)
	openActivationGateCount := 0
	unresolvedConsensusGateCount := 0
	for _, status := range input.OutcomeClassifier.GateStatuses {
		if strings.HasPrefix(status.GateID, "S01-BLOCK-") && status.Status != "passed" {
			openActivationGateCount++
		}
		if strings.HasPrefix(status.GateID, "CONS-") && status.Status == "unresolved" {
			unresolvedConsensusGateCount++
		}
	}

	return Report{
		SchemaVersion: 1, ProfileID: profileID,
		RosterSHA256: rosterDigest, RosterCBORBytes: len(rosterCBOR),
		RootSetCBORHex: hex.EncodeToString(rootCBOR), RootSetHashPreimageHex: hex.EncodeToString(rootPreimage),
		RootSetDigest: hex.EncodeToString(rootDigest[:]), DeploymentDomainHashPreimageHex: hex.EncodeToString(domainPreimage),
		DeploymentDomain: hex.EncodeToString(domainDigest[:]), ResetMode: resetMode,
		ResetRootSetCBORHex: hex.EncodeToString(resetCBOR), ResetRootSetHashPreimageHex: hex.EncodeToString(resetRootPreimage),
		ResetRootSetDigest: hex.EncodeToString(resetRootDigest[:]), ResetDeploymentDomainHashPreimageHex: hex.EncodeToString(resetDomainPreimage),
		ResetDeploymentDomain:      hex.EncodeToString(resetDomainDigest[:]),
		SourceEventIdentityCBORHex: hex.EncodeToString(eventCBOR), ContinuityHashPreimageHex: hex.EncodeToString(continuityPreimage),
		ContinuityKey: continuityKey, ResetSourceEventIdentityCBORHex: hex.EncodeToString(eventCBOR),
		ResetContinuityHashPreimageHex: hex.EncodeToString(continuityPreimage), ResetContinuityKey: continuityKey,
		UnrelatedSourceEventIdentityCBORHex: hex.EncodeToString(unrelatedEventCBOR),
		UnrelatedContinuityHashPreimageHex:  hex.EncodeToString(unrelatedPreimage), UnrelatedContinuityKey: unrelatedKey,
		ImportedConsumedContinuityKeyCount: len(importedKeys), SameEventReplayResult: sameResult,
		UnrelatedEventReplayResult: unrelatedResult, ProducerDAGValid: true, ProducerDAGNodeCount: len(input.ProducerDAG.Nodes),
		GateRecordSetValid: classifier.valid, GateRecordCount: len(input.OutcomeClassifier.GateStatuses),
		GateRecordSetCBORHex: hex.EncodeToString(gateRecordCBOR), GateRecordSetHashPreimageHex: hex.EncodeToString(gateRecordPreimage),
		GateRecordSetDigest: hex.EncodeToString(gateRecordDigest[:]), SelectedProfile: input.OutcomeClassifier.SelectedProfile,
		OpenActivationGateCount: openActivationGateCount, UnresolvedConsensusGateCount: unresolvedConsensusGateCount,
		EvidenceRetentionValid:                       input.OutcomeClassifier.EvidenceRetentionValid,
		CardanoToMidnightTransitionConfirmed:         input.OutcomeClassifier.CardanoToMidnight.TransitionConfirmed,
		CardanoToMidnightSuccessorStateReadConfirmed: input.OutcomeClassifier.CardanoToMidnight.IndependentSuccessorStateReadConfirmed,
		MidnightToCardanoTransitionConfirmed:         input.OutcomeClassifier.MidnightToCardano.TransitionConfirmed,
		MidnightToCardanoSuccessorStateReadConfirmed: input.OutcomeClassifier.MidnightToCardano.IndependentSuccessorStateReadConfirmed,
		OutcomeClassifierRow:                         classifier.row, ClassifierVectorLabel: classifier.label,
		StructuralResult: "structural-pass", DeploymentOutcome: "blocked", ActivationEligible: false,
	}, nil
}

func parseRootSet(raw []byte) (structuralDeploymentRootSetV1, error) {
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(raw, &fields); err != nil || fields == nil {
		return structuralDeploymentRootSetV1{}, &HarnessError{"root-set-shape", "root_set must be an object"}
	}
	for field := range fields {
		if _, forbidden := forbiddenRootFields[field]; forbidden {
			return structuralDeploymentRootSetV1{}, &HarnessError{"forbidden-post-domain-field", "root-set preimage contains " + field}
		}
	}
	var root structuralDeploymentRootSetV1
	if err := decodeStrict(raw, &root); err != nil {
		return structuralDeploymentRootSetV1{}, fail("root-set-schema", err)
	}
	if err := validateRootSet(root); err != nil {
		return structuralDeploymentRootSetV1{}, err
	}
	return root, nil
}

func validateRootSet(root structuralDeploymentRootSetV1) error {
	if _, err := decodeCanonicalHex(root.FreshDeploymentInstanceID, 16); err != nil {
		return fail("root-set-schema", err)
	}
	if root.BridgeProgramID == "" || len(root.SourceIdentityFingerprints) != 2 ||
		root.SourceIdentityFingerprints[0].Chain != "cardano" || root.SourceIdentityFingerprints[1].Chain != "midnight" ||
		len(root.CheckpointManifestDigests) != 2 || len(root.DestinationABITemplateDigests) != 2 || len(root.DeploymentRecipeDigests) != 2 {
		return &HarnessError{"root-set-schema", "bidirectional root-set cardinality or source ordering is invalid"}
	}
	for _, fingerprint := range root.SourceIdentityFingerprints {
		if fingerprint.Chain == "" {
			return &HarnessError{"root-set-schema", "empty source chain"}
		}
		if _, err := decodeCanonicalHex(fingerprint.IdentityDigest, 32); err != nil {
			return fail("root-set-schema", err)
		}
		if _, err := decodeCanonicalHex(fingerprint.ProtocolFingerprint, 32); err != nil {
			return fail("root-set-schema", err)
		}
	}
	digests := append([]string{}, root.CheckpointManifestDigests...)
	digests = append(digests, root.SemanticRegistryTemplateRoot, root.ArtifactTemplateRoot)
	digests = append(digests, root.DestinationABITemplateDigests...)
	digests = append(digests, root.DeploymentRecipeDigests...)
	digests = append(digests, root.ReplayPolicyTemplateDigest, root.FreshnessPolicyTemplateDigest)
	for _, digest := range digests {
		if _, err := decodeCanonicalHex(digest, 32); err != nil {
			return fail("root-set-schema", err)
		}
	}
	for _, values := range [][]string{root.CheckpointManifestDigests, root.DestinationABITemplateDigests, root.DeploymentRecipeDigests} {
		seen := map[string]bool{}
		for _, value := range values {
			if seen[value] {
				return &HarnessError{"root-set-schema", "bidirectional digest entries must be unique"}
			}
			seen[value] = true
		}
	}
	return nil
}

func parseSourceEvent(raw []byte) (sourceEventIdentityV1, error) {
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(raw, &fields); err != nil || fields == nil {
		return sourceEventIdentityV1{}, &HarnessError{"source-event-shape", "source event must be an object"}
	}
	requiredFields := [...]string{
		"version",
		"source_chain_identity_digest",
		"source_handler_or_namespace",
		"source_transaction_or_object_id",
		"source_action_or_event_index",
		"event_discriminator",
		"source_event_commitment",
	}
	if len(fields) != len(requiredFields) {
		return sourceEventIdentityV1{}, &HarnessError{"source-event-schema", "fields do not match SourceEventIdentityV1"}
	}
	for _, field := range requiredFields {
		if _, ok := fields[field]; !ok {
			return sourceEventIdentityV1{}, &HarnessError{"source-event-schema", "fields do not match SourceEventIdentityV1"}
		}
	}
	var event sourceEventIdentityV1
	if err := decodeStrict(raw, &event); err != nil {
		return sourceEventIdentityV1{}, fail("source-event-schema", err)
	}
	if event.Version != 1 || event.SourceHandlerOrNamespace == "" || event.EventDiscriminator == "" {
		return sourceEventIdentityV1{}, &HarnessError{"source-event-schema", "invalid source event version or identifier"}
	}
	for _, value := range []string{event.SourceChainIdentityDigest, event.SourceTransactionOrObjectID, event.SourceEventCommitment} {
		if _, err := decodeCanonicalHex(value, 32); err != nil {
			return sourceEventIdentityV1{}, fail("source-event-schema", err)
		}
	}
	return event, nil
}

func rootSetCBORValue(root structuralDeploymentRootSetV1) map[string]any {
	fingerprints := make([]any, len(root.SourceIdentityFingerprints))
	for index, fingerprint := range root.SourceIdentityFingerprints {
		fingerprints[index] = map[string]any{
			"chain":                fingerprint.Chain,
			"identity_digest":      mustDecodeHex(fingerprint.IdentityDigest),
			"protocol_fingerprint": mustDecodeHex(fingerprint.ProtocolFingerprint),
		}
	}
	return map[string]any{
		"bridge_program_id":                root.BridgeProgramID,
		"fresh_deployment_instance_id":     mustDecodeHex(root.FreshDeploymentInstanceID),
		"source_identity_fingerprints":     fingerprints,
		"checkpoint_manifest_digests":      digestValues(root.CheckpointManifestDigests),
		"semantic_registry_template_root":  mustDecodeHex(root.SemanticRegistryTemplateRoot),
		"artifact_template_root":           mustDecodeHex(root.ArtifactTemplateRoot),
		"destination_abi_template_digests": digestValues(root.DestinationABITemplateDigests),
		"deployment_recipe_digests":        digestValues(root.DeploymentRecipeDigests),
		"replay_policy_template_digest":    mustDecodeHex(root.ReplayPolicyTemplateDigest),
		"freshness_policy_template_digest": mustDecodeHex(root.FreshnessPolicyTemplateDigest),
	}
}

func sourceEventCBORValue(event sourceEventIdentityV1) map[string]any {
	return map[string]any{
		"version":                         event.Version,
		"source_chain_identity_digest":    mustDecodeHex(event.SourceChainIdentityDigest),
		"source_handler_or_namespace":     event.SourceHandlerOrNamespace,
		"source_transaction_or_object_id": mustDecodeHex(event.SourceTransactionOrObjectID),
		"source_action_or_event_index":    event.SourceActionOrEventIndex,
		"event_discriminator":             event.EventDiscriminator,
		"source_event_commitment":         mustDecodeHex(event.SourceEventCommitment),
	}
}

func digestValues(values []string) []any {
	out := make([]any, len(values))
	for index, value := range values {
		out[index] = mustDecodeHex(value)
	}
	return out
}

func mustDecodeHex(value string) []byte {
	decoded, err := hex.DecodeString(value)
	if err != nil {
		panic(err)
	}
	return decoded
}

func decodeCanonicalHex(value string, length int) ([]byte, error) {
	decoded, err := hex.DecodeString(value)
	if err != nil {
		return nil, err
	}
	if len(decoded) != length || hex.EncodeToString(decoded) != value {
		return nil, fmt.Errorf("expected %d canonical lowercase hexadecimal bytes", length)
	}
	return decoded, nil
}

func decodeStrict(raw []byte, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	var extra any
	if err := decoder.Decode(&extra); err != io.EOF {
		if err == nil {
			return fmt.Errorf("trailing JSON value")
		}
		return err
	}
	return nil
}

func decodeJSON(raw []byte) (any, error) {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	var value any
	if err := decoder.Decode(&value); err != nil {
		return nil, err
	}
	if decoder.Decode(&struct{}{}) != io.EOF {
		return nil, fmt.Errorf("trailing JSON value")
	}
	return value, nil
}

func fail(code string, err error) error { return &HarnessError{code, err.Error()} }
