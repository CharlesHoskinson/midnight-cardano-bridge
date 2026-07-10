package bsb22

import (
	"bytes"
	"encoding/hex"
	"errors"
	"testing"
)

func decodeScalar(t *testing.T, encoded string) []byte {
	t.Helper()
	value, err := hex.DecodeString(encoded)
	if err != nil {
		t.Fatal(err)
	}
	if len(value) != PublicScalarLength {
		t.Fatalf("scalar has %d bytes", len(value))
	}
	return value
}

func TestIndependentLittleEndianScalarBoundaries(t *testing.T) {
	const (
		modulusLE      = "01000000fffffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7ed73"
		modulusMinusLE = "00000000fffffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7ed73"
		modulusPlusLE  = "02000000fffffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7ed73"
		modulusBETrap  = "73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001"
	)
	tests := []struct {
		name   string
		scalar []byte
		valid  bool
	}{
		{"zero", make([]byte, PublicScalarLength), true},
		{"r-minus-one", decodeScalar(t, modulusMinusLE), true},
		{"r", decodeScalar(t, modulusLE), false},
		{"r-plus-one", decodeScalar(t, modulusPlusLE), false},
		{"max-uint256", bytes.Repeat([]byte{0xff}, PublicScalarLength), false},
		{"big-endian-modulus-byte-sequence-is-a-valid-little-endian-value", decodeScalar(t, modulusBETrap), true},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := Parse(make([]byte, ProofLength), make([]byte, VKLength), test.scalar)
			if test.valid && err != nil {
				t.Fatalf("expected valid scalar, got %v", err)
			}
			if !test.valid && !errors.Is(err, ErrScalarRange) {
				t.Fatalf("expected scalar range error, got %v", err)
			}
		})
	}
	if !bytes.Equal(FrModulusLittleEndian(), decodeScalar(t, modulusLE)) {
		t.Fatal("exported modulus bytes differ from independent vector")
	}
}

func TestRejectsEveryWrongLengthAndTrailingByte(t *testing.T) {
	tests := []struct {
		name      string
		proof, vk []byte
		pub       []byte
		expected  error
	}{
		{"proof-short", make([]byte, ProofLength-1), make([]byte, VKLength), make([]byte, PublicScalarLength), ErrProofLength},
		{"proof-trailing", make([]byte, ProofLength+1), make([]byte, VKLength), make([]byte, PublicScalarLength), ErrProofLength},
		{"vk-short", make([]byte, ProofLength), make([]byte, VKLength-1), make([]byte, PublicScalarLength), ErrVKLength},
		{"vk-trailing", make([]byte, ProofLength), make([]byte, VKLength+1), make([]byte, PublicScalarLength), ErrVKLength},
		{"scalar-short", make([]byte, ProofLength), make([]byte, VKLength), make([]byte, PublicScalarLength-1), ErrPublicScalarLength},
		{"scalar-trailing", make([]byte, ProofLength), make([]byte, VKLength), make([]byte, PublicScalarLength+1), ErrPublicScalarLength},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if _, err := Parse(test.proof, test.vk, test.pub); !errors.Is(err, test.expected) {
				t.Fatalf("expected %v, got %v", test.expected, err)
			}
		})
	}
}

func TestEveryRegisteredFieldHasExactCompleteSliceAndMetadata(t *testing.T) {
	proof := make([]byte, ProofLength)
	vk := make([]byte, VKLength)
	for index := range proof {
		proof[index] = byte((index*17 + 3) % 251)
	}
	for index := range vk {
		vk[index] = byte((index*29 + 11) % 251)
	}
	parsed, err := Parse(proof, vk, make([]byte, PublicScalarLength))
	if err != nil {
		t.Fatal(err)
	}
	proofFields := map[string][]byte{
		"A": parsed.Proof.A, "B": parsed.Proof.B, "C": parsed.Proof.C,
		"D": parsed.Proof.D, "PoK": parsed.Proof.PoK,
	}
	vkFields := map[string][]byte{
		"alpha": parsed.VK.Alpha, "beta": parsed.VK.Beta, "gamma": parsed.VK.Gamma,
		"delta": parsed.VK.Delta, "IC0": parsed.VK.IC0, "IC1": parsed.VK.IC1,
		"K2": parsed.VK.K2, "CK.G": parsed.VK.CKG, "CK.GSigmaNeg": parsed.VK.CKGSigmaNeg,
	}
	assertLayout := func(t *testing.T, source []byte, fields map[string][]byte, actual, expected []FieldLayout) {
		t.Helper()
		if len(actual) != len(expected) {
			t.Fatalf("layout has %d fields, want %d", len(actual), len(expected))
		}
		for index, want := range expected {
			if actual[index] != want {
				t.Fatalf("layout[%d] = %+v, want %+v", index, actual[index], want)
			}
			if !bytes.Equal(fields[want.Name], source[want.Offset:want.Offset+want.Length]) {
				t.Fatalf("field %s does not equal complete registered slice", want.Name)
			}
		}
	}
	assertLayout(t, proof, proofFields, parsed.ProofLayout, []FieldLayout{
		{"A", 0, 48}, {"B", 48, 96}, {"C", 144, 48}, {"D", 192, 96}, {"PoK", 288, 48},
	})
	assertLayout(t, vk, vkFields, parsed.VKLayout, []FieldLayout{
		{"alpha", 0, 48}, {"beta", 48, 96}, {"gamma", 144, 96},
		{"delta", 240, 96}, {"IC0", 336, 48}, {"IC1", 384, 48},
		{"K2", 432, 48}, {"CK.G", 480, 96}, {"CK.GSigmaNeg", 576, 96},
	})
	if parsed.CryptographicVerification {
		t.Fatal("parser must not claim cryptographic verification")
	}
	if parsed.FullDeciderGate != "unresolved" || parsed.CardanoExecutionGate != "unresolved" {
		t.Fatalf("parser closed a proof gate: %+v", parsed)
	}
}
