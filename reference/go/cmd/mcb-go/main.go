package main

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"

	"github.com/charleshoskinson/midnight-cardano-bridge/reference/go/internal/bsb22"
	"github.com/charleshoskinson/midnight-cardano-bridge/reference/go/internal/harness"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) == 3 && args[0] == "run" {
		report, err := harness.RunFixture(args[2], args[1])
		if err != nil {
			return err
		}
		return json.NewEncoder(os.Stdout).Encode(report)
	}
	if len(args) == 4 && args[0] == "bsb22-check" {
		proof, err := hex.DecodeString(args[1])
		if err != nil {
			return err
		}
		vk, err := hex.DecodeString(args[2])
		if err != nil {
			return err
		}
		pub, err := hex.DecodeString(args[3])
		if err != nil {
			return err
		}
		report, err := buildBSB22Report(proof, vk, pub)
		if err != nil {
			return err
		}
		return json.NewEncoder(os.Stdout).Encode(report)
	}
	return fmt.Errorf("usage: mcb-go run <fixture> <repo-root> | bsb22-check <proof-hex> <vk-hex> <pub-hex>")
}

func buildBSB22Report(proof, vk, publicScalar []byte) (map[string]any, error) {
	parsed, err := bsb22.Parse(proof, vk, publicScalar)
	if err != nil {
		return nil, err
	}
	return map[string]any{
		"proof_bytes":                len(proof),
		"vk_bytes":                   len(vk),
		"public_scalar_bytes":        len(publicScalar),
		"proof_fields":               parsed.ProofLayout,
		"vk_fields":                  parsed.VKLayout,
		"cryptographic_verification": parsed.CryptographicVerification,
		"gate_statuses": map[string]string{
			"S01-BLOCK-04/full-decider":      parsed.FullDeciderGate,
			"S01-BLOCK-06/cardano-execution": parsed.CardanoExecutionGate,
		},
	}, nil
}
