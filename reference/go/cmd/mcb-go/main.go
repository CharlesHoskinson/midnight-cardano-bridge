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
		parsed, err := bsb22.Parse(proof, vk, pub)
		if err != nil {
			return err
		}
		return json.NewEncoder(os.Stdout).Encode(map[string]any{
			"proof_bytes": len(proof), "vk_bytes": len(vk), "public_scalar_bytes": len(pub),
			"cryptographic_verification": parsed.CryptographicVerification,
			"S01-BLOCK-04":               parsed.FullDeciderGate, "S01-BLOCK-06": parsed.CardanoExecutionGate,
		})
	}
	return fmt.Errorf("usage: mcb-go run <fixture> <repo-root> | bsb22-check <proof-hex> <vk-hex> <pub-hex>")
}
