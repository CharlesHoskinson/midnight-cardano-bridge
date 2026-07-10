package harness

type classifierResult struct {
	row         uint8
	label       string
	valid       bool
	gateRecords []any
}

func evaluateClassifier(roster map[string]any, input outcomeClassifierInput) (classifierResult, error) {
	entries, ok := roster["entries"].([]any)
	if !ok {
		return classifierResult{}, &HarnessError{"roster-shape", "missing entries"}
	}
	records := make([]any, 0, len(input.GateStatuses))
	for _, status := range input.GateStatuses {
		record := map[string]any{}
		for _, raw := range entries {
			entry := raw.(map[string]any)
			if entry["gate_id"] == status.GateID {
				for key, value := range entry {
					record[key] = value
				}
				break
			}
		}
		record["gate_id"] = status.GateID
		record["status"] = status.Status
		record["evidence_digest"] = status.EvidenceDigest
		record["evidence_retention_valid"] = status.EvidenceRetentionValid
		records = append(records, record)
	}

	valid := (input.SelectedProfile == "public" || input.SelectedProfile == "lab") &&
		input.EvidenceRetentionValid && len(input.GateStatuses) == len(entries)
	seen := map[string]bool{}
	for index, status := range input.GateStatuses {
		if index >= len(entries) || entries[index].(map[string]any)["gate_id"] != status.GateID || seen[status.GateID] {
			valid = false
		}
		seen[status.GateID] = true
		if !validGateStatus(status.Status) || status.Status == "not-applicable" || !status.EvidenceRetentionValid {
			valid = false
		}
		if _, err := decodeCanonicalHex(status.EvidenceDigest, 32); err != nil {
			valid = false
		}
		if index >= len(entries) {
			continue
		}
		entry := entries[index].(map[string]any)
		applicability, ok := entry["applicability"].(map[string]any)[input.SelectedProfile].(string)
		if !ok {
			valid = false
			continue
		}
		switch applicability {
		case "required", "public-only":
		default:
			valid = false
		}
	}
	if !valid {
		return classifierResult{1, "blocked", false, records}, nil
	}
	for index, raw := range entries {
		entry := raw.(map[string]any)
		applicability := entry["applicability"].(map[string]any)[input.SelectedProfile].(string)
		if applicability == "required" && input.GateStatuses[index].Status != "passed" {
			return classifierResult{2, "blocked", true, records}, nil
		}
	}
	directionsConfirmed := input.CardanoToMidnight.TransitionConfirmed &&
		input.CardanoToMidnight.IndependentSuccessorStateReadConfirmed &&
		input.MidnightToCardano.TransitionConfirmed &&
		input.MidnightToCardano.IndependentSuccessorStateReadConfirmed
	if !directionsConfirmed {
		return classifierResult{3, "blocked", true, records}, nil
	}
	if input.SelectedProfile == "lab" {
		return classifierResult{4, "degraded-lab", true, records}, nil
	}
	return classifierResult{5, "live-pass", true, records}, nil
}

func validGateStatus(status string) bool {
	switch status {
	case "unresolved", "passed", "failed", "mocked", "not-applicable":
		return true
	default:
		return false
	}
}
