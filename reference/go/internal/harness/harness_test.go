package harness

import (
	"bytes"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func repoRoot(t *testing.T) string {
	t.Helper()
	root, err := filepath.Abs(filepath.Join("..", "..", "..", ".."))
	if err != nil {
		t.Fatal(err)
	}
	return root
}

func fixture(t *testing.T, name string) string {
	t.Helper()
	return filepath.Join(repoRoot(t), "reference", "fixtures", name)
}

func mutatedFixture(t *testing.T, name string, mutate func(map[string]any)) string {
	t.Helper()
	contents, err := os.ReadFile(fixture(t, "structural-v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	var value map[string]any
	if err := json.Unmarshal(contents, &value); err != nil {
		t.Fatal(err)
	}
	mutate(value)
	path := filepath.Join(t.TempDir(), name+".json")
	encoded, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, encoded, 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func assertHashFrame(t *testing.T, preimageHex, domain, bodyHex string) {
	t.Helper()
	preimage, err := hex.DecodeString(preimageHex)
	if err != nil {
		t.Fatal(err)
	}
	body, err := hex.DecodeString(bodyHex)
	if err != nil {
		t.Fatal(err)
	}
	domainLength := binary.BigEndian.Uint64(preimage[:8])
	if domainLength != uint64(len(domain)) {
		t.Fatalf("domain length = %d, want %d", domainLength, len(domain))
	}
	domainEnd := 8 + len(domain)
	if !bytes.Equal(preimage[8:domainEnd], []byte(domain)) {
		t.Fatal("domain bytes mismatch")
	}
	bodyLength := binary.BigEndian.Uint64(preimage[domainEnd : domainEnd+8])
	if bodyLength != uint64(len(body)) {
		t.Fatalf("body length = %d, want %d", bodyLength, len(body))
	}
	if !bytes.Equal(preimage[domainEnd+8:], body) {
		t.Fatal("body bytes mismatch")
	}
}

func TestStructuralReportMatchesRosterAndSafetyBoundary(t *testing.T) {
	report, err := RunFixture(repoRoot(t), fixture(t, "structural-v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	if report.RosterSHA256 != "2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f" {
		t.Fatalf("unexpected roster hash %s", report.RosterSHA256)
	}
	if report.RosterCBORBytes != 7705 {
		t.Fatalf("unexpected roster length %d", report.RosterCBORBytes)
	}
	if report.DeploymentOutcome != "blocked" || report.ActivationEligible {
		t.Fatalf("unsafe report: %+v", report)
	}
}

func TestResetChangesDomainButNotContinuity(t *testing.T) {
	report, err := RunFixture(repoRoot(t), fixture(t, "structural-v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	if report.RootSetDigest == report.ResetRootSetDigest || report.DeploymentDomain == report.ResetDeploymentDomain {
		t.Fatal("reset did not change root and domain")
	}
	if report.ContinuityKey != report.ResetContinuityKey {
		t.Fatal("domain-independent continuity key changed")
	}
	if report.SameEventReplayResult != "rejected-consumed" || report.UnrelatedEventReplayResult != "accepted-unused" {
		t.Fatalf("continuity replay results = %q, %q", report.SameEventReplayResult, report.UnrelatedEventReplayResult)
	}
	if report.ContinuityKey == report.UnrelatedContinuityKey {
		t.Fatal("unrelated event reused continuity key")
	}
	if report.ResetMode != "state-bearing-continuity-migration" {
		t.Fatalf("reset mode = %q", report.ResetMode)
	}
}

func TestPostDomainFieldIsRejected(t *testing.T) {
	_, sharedErr := RunFixture(repoRoot(t), fixture(t, "invalid-post-domain-v1.json"))
	if sharedErr == nil || ErrorCode(sharedErr) != "forbidden-post-domain-field" {
		t.Fatalf("shared fixture expected forbidden field, got %v", sharedErr)
	}

	path := mutatedFixture(t, "post-domain-root", func(value map[string]any) {
		value["root_set"].(map[string]any)["deployment_domain"] = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
	})
	_, err := RunFixture(repoRoot(t), path)
	if err == nil || ErrorCode(err) != "forbidden-post-domain-field" {
		t.Fatalf("expected forbidden field, got %v", err)
	}
}

func TestStructuralProfileRejectsActivation(t *testing.T) {
	err := RequestActivation("mcb.structural-lab.sha256-cbor.v1")
	if err == nil || ErrorCode(err) != "structural-profile-not-activating" {
		t.Fatalf("expected structural activation rejection, got %v", err)
	}
}

func TestStructuralHashPreimagesAreLengthFramedAndEmitted(t *testing.T) {
	report, err := RunFixture(repoRoot(t), fixture(t, "structural-v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	assertHashFrame(t, report.RootSetHashPreimageHex, "mcb/deployment-root-set/v1", report.RootSetCBORHex)
	assertHashFrame(t, report.ResetRootSetHashPreimageHex, "mcb/deployment-root-set/v1", report.ResetRootSetCBORHex)
	assertHashFrame(t, report.DeploymentDomainHashPreimageHex, "mcb/deployment-domain/v1", report.RootSetDigest)
	assertHashFrame(t, report.ResetDeploymentDomainHashPreimageHex, "mcb/deployment-domain/v1", report.ResetRootSetDigest)
	assertHashFrame(t, report.ContinuityHashPreimageHex, "mcb/continuity-key/v1", report.SourceEventIdentityCBORHex)
	assertHashFrame(t, report.GateRecordSetHashPreimageHex, "mcb/structural-gate-record-set/v1", report.GateRecordSetCBORHex)
}

func TestExactStructuralSchemasRejectUnknownAndMalformedFields(t *testing.T) {
	tests := []struct {
		name     string
		expected string
		mutate   func(map[string]any)
	}{
		{"post-domain-root", "forbidden-post-domain-field", func(value map[string]any) {
			value["root_set"].(map[string]any)["activation"] = map[string]any{"decision": "activate"}
		}},
		{"unknown-root", "root-set-schema", func(value map[string]any) {
			value["root_set"].(map[string]any)["unexpected"] = 1
		}},
		{"malformed-root", "root-set-shape", func(value map[string]any) {
			value["root_set"] = []any{}
		}},
		{"unknown-event", "source-event-schema", func(value map[string]any) {
			value["source_event_identity"].(map[string]any)["deployment_domain"] = "00"
		}},
		{"duplicate-source-chain", "root-set-schema", func(value map[string]any) {
			fingerprints := value["root_set"].(map[string]any)["source_identity_fingerprints"].([]any)
			fingerprints[1].(map[string]any)["chain"] = "cardano"
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			path := mutatedFixture(t, test.name, test.mutate)
			_, err := RunFixture(repoRoot(t), path)
			if err == nil || ErrorCode(err) != test.expected {
				t.Fatalf("expected %s, got %v", test.expected, err)
			}
		})
	}
}

func TestSourceEventSchemaRequiresExplicitIndexMember(t *testing.T) {
	missingIndex := mutatedFixture(t, "missing-source-event-index", func(value map[string]any) {
		delete(value["source_event_identity"].(map[string]any), "source_action_or_event_index")
	})
	_, err := RunFixture(repoRoot(t), missingIndex)
	if err == nil || ErrorCode(err) != "source-event-schema" {
		t.Fatalf("expected source-event-schema for missing index member, got %v", err)
	}

	if _, err := RunFixture(repoRoot(t), fixture(t, "structural-v1.json")); err != nil {
		t.Fatalf("explicit index zero must remain valid: %v", err)
	}
}

func TestProducerDAGRejectsCycleUnresolvedNonForwardAndPostDomainMapping(t *testing.T) {
	node := func(value map[string]any, id string) map[string]any {
		for _, raw := range value["producer_dag"].(map[string]any)["nodes"].([]any) {
			candidate := raw.(map[string]any)
			if candidate["id"] == id {
				return candidate
			}
		}
		t.Fatalf("node %s not found", id)
		return nil
	}
	tests := []struct {
		name     string
		expected string
		mutate   func(map[string]any)
	}{
		{"cycle", "producer-cycle", func(value map[string]any) {
			node(value, "semantic_registry_template")["dependencies"] = []any{"artifact_template"}
			node(value, "artifact_template")["dependencies"] = []any{"semantic_registry_template"}
		}},
		{"unresolved", "unresolved-producer", func(value map[string]any) {
			node(value, "semantic_registry_template")["dependencies"] = []any{"missing_producer"}
		}},
		{"non-forward", "producer-non-forward-edge", func(value map[string]any) {
			node(value, "source_descriptors")["dependencies"] = []any{"artifact_template"}
		}},
		{"post-domain", "post-domain-dependency", func(value map[string]any) {
			value["producer_dag"].(map[string]any)["root_field_producers"].(map[string]any)["bridge_program_id"] = "registry_activation"
		}},
		{"duplicate-id", "duplicate-producer", func(value map[string]any) {
			node(value, "source_descriptors")["id"] = "bridge_program"
		}},
		{"duplicate-dependency", "duplicate-producer-dependency", func(value map[string]any) {
			node(value, "source_fingerprints")["dependencies"] = []any{"source_descriptors", "source_descriptors"}
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			path := mutatedFixture(t, "dag-"+test.name, test.mutate)
			_, err := RunFixture(repoRoot(t), path)
			if err == nil || ErrorCode(err) != test.expected {
				t.Fatalf("expected %s, got %v", test.expected, err)
			}
		})
	}
}

func TestOutcomeClassifierUsesRosterRecordsAndFirstMatchingRow(t *testing.T) {
	base, err := RunFixture(repoRoot(t), fixture(t, "structural-v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	if base.GateRecordCount != 14 || base.OutcomeClassifierRow != 2 || base.ClassifierVectorLabel != "blocked" || base.DeploymentOutcome != "blocked" || base.OpenActivationGateCount != 6 || base.UnresolvedConsensusGateCount != 8 {
		t.Fatalf("base classifier = %+v", base)
	}

	rowOneCases := []struct {
		name   string
		mutate func(map[string]any)
	}{
		{"missing", func(value map[string]any) {
			outcome := value["outcome_classifier"].(map[string]any)
			statuses := outcome["gate_statuses"].([]any)
			outcome["gate_statuses"] = statuses[:len(statuses)-1]
		}},
		{"duplicate", func(value map[string]any) {
			statuses := value["outcome_classifier"].(map[string]any)["gate_statuses"].([]any)
			statuses[1].(map[string]any)["gate_id"] = "S01-BLOCK-01/catalog-completeness"
		}},
		{"unknown", func(value map[string]any) {
			statuses := value["outcome_classifier"].(map[string]any)["gate_statuses"].([]any)
			statuses[0].(map[string]any)["gate_id"] = "UNKNOWN-GATE"
		}},
		{"retention", func(value map[string]any) {
			value["outcome_classifier"].(map[string]any)["evidence_retention_valid"] = false
		}},
		{"not-applicable", func(value map[string]any) {
			statuses := value["outcome_classifier"].(map[string]any)["gate_statuses"].([]any)
			statuses[1].(map[string]any)["status"] = "not-applicable"
		}},
		{"evidence-digest", func(value map[string]any) {
			statuses := value["outcome_classifier"].(map[string]any)["gate_statuses"].([]any)
			statuses[0].(map[string]any)["evidence_digest"] = "not-hex"
		}},
	}
	for _, test := range rowOneCases {
		t.Run("row-1-"+test.name, func(t *testing.T) {
			path := mutatedFixture(t, "classifier-row-1-"+test.name, test.mutate)
			report, err := RunFixture(repoRoot(t), path)
			if err != nil {
				t.Fatal(err)
			}
			if report.OutcomeClassifierRow != 1 || report.ClassifierVectorLabel != "blocked" || report.DeploymentOutcome != "blocked" {
				t.Fatalf("row-one classifier = %+v", report)
			}
		})
	}

	passAll := func(value map[string]any) {
		for _, raw := range value["outcome_classifier"].(map[string]any)["gate_statuses"].([]any) {
			raw.(map[string]any)["status"] = "passed"
		}
	}
	rowThreePath := mutatedFixture(t, "classifier-row-3", passAll)
	rowThree, err := RunFixture(repoRoot(t), rowThreePath)
	if err != nil {
		t.Fatal(err)
	}
	if rowThree.OutcomeClassifierRow != 3 || rowThree.ClassifierVectorLabel != "blocked" || rowThree.DeploymentOutcome != "blocked" {
		t.Fatalf("row-three classifier = %+v", rowThree)
	}

	changedEvidencePath := mutatedFixture(t, "classifier-evidence-binding", func(value map[string]any) {
		statuses := value["outcome_classifier"].(map[string]any)["gate_statuses"].([]any)
		statuses[0].(map[string]any)["evidence_digest"] = "f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1"
	})
	changedEvidence, err := RunFixture(repoRoot(t), changedEvidencePath)
	if err != nil {
		t.Fatal(err)
	}
	if changedEvidence.GateRecordSetDigest == base.GateRecordSetDigest {
		t.Fatal("gate record set digest did not bind evidence identity")
	}

	rowFourPath := mutatedFixture(t, "classifier-row-4", func(value map[string]any) {
		outcome := value["outcome_classifier"].(map[string]any)
		outcome["selected_profile"] = "lab"
		for _, raw := range outcome["gate_statuses"].([]any) {
			status := raw.(map[string]any)
			if status["gate_id"] == "S01-BLOCK-02/public-scls-availability" {
				status["status"] = "unresolved"
			} else {
				status["status"] = "passed"
			}
		}
		for _, direction := range []string{"cardano_to_midnight", "midnight_to_cardano"} {
			evidence := outcome[direction].(map[string]any)
			evidence["transition_confirmed"] = true
			evidence["independent_successor_state_read_confirmed"] = true
		}
	})
	rowFour, err := RunFixture(repoRoot(t), rowFourPath)
	if err != nil {
		t.Fatal(err)
	}
	if rowFour.OutcomeClassifierRow != 4 || rowFour.ClassifierVectorLabel != "degraded-lab" || rowFour.DeploymentOutcome != "blocked" || rowFour.ActivationEligible {
		t.Fatalf("row-four classifier = %+v", rowFour)
	}

	rowFivePath := mutatedFixture(t, "classifier-row-5", func(value map[string]any) {
		passAll(value)
		outcome := value["outcome_classifier"].(map[string]any)
		for _, direction := range []string{"cardano_to_midnight", "midnight_to_cardano"} {
			evidence := outcome[direction].(map[string]any)
			evidence["transition_confirmed"] = true
			evidence["independent_successor_state_read_confirmed"] = true
		}
	})
	rowFive, err := RunFixture(repoRoot(t), rowFivePath)
	if err != nil {
		t.Fatal(err)
	}
	if rowFive.OutcomeClassifierRow != 5 || rowFive.ClassifierVectorLabel != "live-pass" || rowFive.DeploymentOutcome != "blocked" || rowFive.ActivationEligible || rowFive.OpenActivationGateCount != 0 || rowFive.UnresolvedConsensusGateCount != 0 {
		t.Fatalf("row-five classifier = %+v", rowFive)
	}
}
