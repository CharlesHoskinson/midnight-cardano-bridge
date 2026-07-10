package bsb22

import (
	"bytes"
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
)

const (
	ProofLength        = 336
	VKLength           = 672
	PublicScalarLength = 32
)

var (
	ErrProofLength        = errors.New("BSB22 proof must be exactly 336 bytes")
	ErrVKLength           = errors.New("BSB22 VK must be exactly 672 bytes")
	ErrPublicScalarLength = errors.New("public scalar must be exactly 32 bytes")
	ErrScalarRange        = errors.New("public scalar is not canonical BLS12-381 Fr")
	ErrFieldMismatch      = errors.New("bsb22-field-mismatch")
)

type Proof struct {
	A, B, C, D, PoK []byte
}

type VK struct {
	Alpha, Beta, Gamma, Delta, IC0, IC1, K2, CKG, CKGSigmaNeg []byte
}

type FieldLayout struct {
	Name   string `json:"name"`
	Offset int    `json:"offset"`
	Length int    `json:"length"`
}

var proofLayout = []FieldLayout{
	{"A", 0, 48},
	{"B", 48, 96},
	{"C", 144, 48},
	{"D", 192, 96},
	{"PoK", 288, 48},
}

var vkLayout = []FieldLayout{
	{"alpha", 0, 48},
	{"beta", 48, 96},
	{"gamma", 144, 96},
	{"delta", 240, 96},
	{"IC0", 336, 48},
	{"IC1", 384, 48},
	{"K2", 432, 48},
	{"CK.G", 480, 96},
	{"CK.GSigmaNeg", 576, 96},
}

type Parsed struct {
	Proof                     Proof
	VK                        VK
	PublicScalar              []byte
	ProofLayout               []FieldLayout
	VKLayout                  []FieldLayout
	CryptographicVerification bool
	FullDeciderGate           string
	CardanoExecutionGate      string
}

func Parse(proof, vk, publicScalar []byte) (Parsed, error) {
	if len(proof) != ProofLength {
		return Parsed{}, ErrProofLength
	}
	if len(vk) != VKLength {
		return Parsed{}, ErrVKLength
	}
	if len(publicScalar) != PublicScalarLength {
		return Parsed{}, ErrPublicScalarLength
	}
	if littleEndianInt(publicScalar).Cmp(frModulus()) >= 0 {
		return Parsed{}, ErrScalarRange
	}
	return Parsed{
		Proof:                     Proof{proof[0:48], proof[48:144], proof[144:192], proof[192:288], proof[288:336]},
		VK:                        VK{vk[0:48], vk[48:144], vk[144:240], vk[240:336], vk[336:384], vk[384:432], vk[432:480], vk[480:576], vk[576:672]},
		PublicScalar:              append([]byte(nil), publicScalar...),
		ProofLayout:               append([]FieldLayout(nil), proofLayout...),
		VKLayout:                  append([]FieldLayout(nil), vkLayout...),
		CryptographicVerification: false,
		FullDeciderGate:           "unresolved",
		CardanoExecutionGate:      "unresolved",
	}, nil
}

// ParseNamedExpectations parses proof/VK bytes and requires every named field
// to equal the registered sentinel expectation. Equal-width swaps fail with
// ErrFieldMismatch. This remains parser-only: CryptographicVerification is false.
func ParseNamedExpectations(proof, vk, publicScalar []byte, expectedProof, expectedVK map[string][]byte) (Parsed, error) {
	parsed, err := Parse(proof, vk, publicScalar)
	if err != nil {
		return Parsed{}, err
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
	for _, layout := range proofLayout {
		want, ok := expectedProof[layout.Name]
		if !ok || len(want) != layout.Length {
			return Parsed{}, fmt.Errorf("%w: missing proof expectation %s", ErrFieldMismatch, layout.Name)
		}
		if !bytes.Equal(proofFields[layout.Name], want) {
			return Parsed{}, fmt.Errorf("%w: proof field %s", ErrFieldMismatch, layout.Name)
		}
	}
	for _, layout := range vkLayout {
		want, ok := expectedVK[layout.Name]
		if !ok || len(want) != layout.Length {
			return Parsed{}, fmt.Errorf("%w: missing vk expectation %s", ErrFieldMismatch, layout.Name)
		}
		if !bytes.Equal(vkFields[layout.Name], want) {
			return Parsed{}, fmt.Errorf("%w: vk field %s", ErrFieldMismatch, layout.Name)
		}
	}
	return parsed, nil
}

func FrModulusLittleEndian() []byte {
	be, _ := hex.DecodeString("73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001")
	reverse(be)
	return be
}

func frModulus() *big.Int {
	value, _ := new(big.Int).SetString("73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001", 16)
	return value
}

func littleEndianInt(value []byte) *big.Int {
	copyValue := append([]byte(nil), value...)
	reverse(copyValue)
	return new(big.Int).SetBytes(copyValue)
}

func reverse(value []byte) {
	for left, right := 0, len(value)-1; left < right; left, right = left+1, right-1 {
		value[left], value[right] = value[right], value[left]
	}
}
