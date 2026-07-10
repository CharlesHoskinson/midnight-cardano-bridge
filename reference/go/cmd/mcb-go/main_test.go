package main

import (
	"testing"

	"github.com/charleshoskinson/midnight-cardano-bridge/reference/go/internal/bsb22"
)

func TestBSB22ReportUsesExactGateIDsAndExposesEveryField(t *testing.T) {
	report, err := buildBSB22Report(
		make([]byte, bsb22.ProofLength),
		make([]byte, bsb22.VKLength),
		make([]byte, bsb22.PublicScalarLength),
	)
	if err != nil {
		t.Fatal(err)
	}
	statuses := report["gate_statuses"].(map[string]string)
	if len(statuses) != 2 || statuses["S01-BLOCK-04/full-decider"] != "unresolved" || statuses["S01-BLOCK-06/cardano-execution"] != "unresolved" {
		t.Fatalf("gate statuses = %#v", statuses)
	}
	if len(report["proof_fields"].([]bsb22.FieldLayout)) != 5 || len(report["vk_fields"].([]bsb22.FieldLayout)) != 9 {
		t.Fatalf("field metadata missing: %#v", report)
	}
	if report["cryptographic_verification"] != false {
		t.Fatalf("unsafe report: %#v", report)
	}
}
