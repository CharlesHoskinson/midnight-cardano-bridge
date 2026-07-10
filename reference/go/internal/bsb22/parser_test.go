package bsb22

import (
	"errors"
	"testing"
)

func TestRejectsScalarAtModulus(t *testing.T) {
	_, err := Parse(make([]byte, ProofLength), make([]byte, VKLength), FrModulusLittleEndian())
	if !errors.Is(err, ErrScalarRange) {
		t.Fatalf("expected scalar range error, got %v", err)
	}
}

func TestRejectsWrongLengths(t *testing.T) {
	if _, err := Parse(make([]byte, ProofLength-1), make([]byte, VKLength), make([]byte, PublicScalarLength)); !errors.Is(err, ErrProofLength) {
		t.Fatalf("expected proof length error, got %v", err)
	}
	if _, err := Parse(make([]byte, ProofLength), make([]byte, VKLength+1), make([]byte, PublicScalarLength)); !errors.Is(err, ErrVKLength) {
		t.Fatalf("expected VK length error, got %v", err)
	}
	if _, err := Parse(make([]byte, ProofLength), make([]byte, VKLength), make([]byte, PublicScalarLength+1)); !errors.Is(err, ErrPublicScalarLength) {
		t.Fatalf("expected scalar length error, got %v", err)
	}
}

func TestRegisteredOffsetsAndNonClaimBoundary(t *testing.T) {
	proof := make([]byte, ProofLength)
	vk := make([]byte, VKLength)
	for index := range proof {
		proof[index] = byte(index % 251)
	}
	for index := range vk {
		vk[index] = byte((index + 17) % 251)
	}
	parsed, err := Parse(proof, vk, make([]byte, PublicScalarLength))
	if err != nil {
		t.Fatal(err)
	}
	if len(parsed.Proof.A) != 48 || len(parsed.Proof.B) != 96 || len(parsed.Proof.C) != 48 || len(parsed.Proof.D) != 96 || len(parsed.Proof.PoK) != 48 {
		t.Fatalf("bad proof slices: %+v", parsed.Proof)
	}
	if len(parsed.VK.Alpha) != 48 || len(parsed.VK.Beta) != 96 || len(parsed.VK.Gamma) != 96 || len(parsed.VK.Delta) != 96 || len(parsed.VK.IC0) != 48 || len(parsed.VK.IC1) != 48 || len(parsed.VK.K2) != 48 || len(parsed.VK.CKG) != 96 || len(parsed.VK.CKGSigmaNeg) != 96 {
		t.Fatalf("bad VK slices: %+v", parsed.VK)
	}
	if parsed.Proof.A[0] != proof[0] || parsed.Proof.B[0] != proof[48] || parsed.Proof.PoK[0] != proof[288] {
		t.Fatal("proof offsets drifted")
	}
	if parsed.VK.IC0[0] != vk[336] || parsed.VK.CKG[0] != vk[480] || parsed.VK.CKGSigmaNeg[0] != vk[576] {
		t.Fatal("VK offsets drifted")
	}
	if parsed.CryptographicVerification {
		t.Fatal("parser must not claim cryptographic verification")
	}
	if parsed.FullDeciderGate != "unresolved" || parsed.CardanoExecutionGate != "unresolved" {
		t.Fatalf("parser closed a proof gate: %+v", parsed)
	}
}
