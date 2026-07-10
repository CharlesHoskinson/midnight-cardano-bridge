package bsb22

import (
	"encoding/hex"
	"errors"
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
)

type Proof struct {
	A, B, C, D, PoK []byte
}

type VK struct {
	Alpha, Beta, Gamma, Delta, IC0, IC1, K2, CKG, CKGSigmaNeg []byte
}

type Parsed struct {
	Proof                     Proof
	VK                        VK
	PublicScalar              []byte
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
		CryptographicVerification: false,
		FullDeciderGate:           "unresolved",
		CardanoExecutionGate:      "unresolved",
	}, nil
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
