package harness

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/charleshoskinson/midnight-cardano-bridge/reference/go/internal/canon"
)

const (
	profileID        = "mcb.structural-lab.sha256-cbor.v1"
	rootDomain       = "mcb/deployment-root-set/v1"
	deploymentDomain = "mcb/deployment-domain/v1"
	continuityDomain = "mcb/continuity-key/v1"
)

var forbiddenRootFields = map[string]struct{}{
	"root_set_digest": {}, "deployment_domain": {}, "registry_activation": {},
	"registry_activation_digest": {}, "artifact_authorization": {},
	"artifact_authorization_root": {}, "destination_abi_instance": {},
	"destination_abi_instance_digest": {}, "concrete_destination_instance_id": {},
	"deployed_code_hash": {}, "runtime_state": {}, "job": {}, "proof": {},
	"replay_key": {}, "transaction": {}, "receipt": {}, "run_manifest": {},
	"run_evidence_manifest": {},
}

type structuralFixture struct {
	SchemaVersion                  uint64          `json:"schema_version"`
	ProfileID                      string          `json:"profile_id"`
	RosterJSON                     string          `json:"roster_json"`
	RosterCBORHex                  string          `json:"roster_cbor_hex"`
	RootSet                        json.RawMessage `json:"root_set"`
	ResetFreshDeploymentInstanceID string          `json:"reset_fresh_deployment_instance_id"`
	SourceEventIdentity            json.RawMessage `json:"source_event_identity"`
}

type Report struct {
	SchemaVersion         uint64 `json:"schema_version"`
	ProfileID             string `json:"profile_id"`
	RosterSHA256          string `json:"roster_sha256"`
	RosterCBORBytes       int    `json:"roster_cbor_bytes"`
	RootSetDigest         string `json:"root_set_digest"`
	DeploymentDomain      string `json:"deployment_domain"`
	ResetRootSetDigest    string `json:"reset_root_set_digest"`
	ResetDeploymentDomain string `json:"reset_deployment_domain"`
	ContinuityKey         string `json:"continuity_key"`
	ResetContinuityKey    string `json:"reset_continuity_key"`
	StructuralResult      string `json:"structural_result"`
	DeploymentOutcome     string `json:"deployment_outcome"`
	ActivationEligible    bool   `json:"activation_eligible"`
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

func RunFixture(repoRoot, fixturePath string) (Report, error) {
	var input structuralFixture
	fixtureBytes, err := os.ReadFile(fixturePath)
	if err != nil {
		return Report{}, fail("fixture-read", err)
	}
	if err := json.Unmarshal(fixtureBytes, &input); err != nil {
		return Report{}, fail("fixture-json", err)
	}
	if input.SchemaVersion != 1 || input.ProfileID != profileID {
		return Report{}, &HarnessError{"unsupported-structural-profile", input.ProfileID}
	}

	rootSet, err := decodeJSON(input.RootSet)
	if err != nil {
		return Report{}, fail("root-set-json", err)
	}
	if err := rejectForbidden(rootSet); err != nil {
		return Report{}, err
	}

	var rosterDocument struct {
		Roster json.RawMessage `json:"roster"`
	}
	rosterJSON, err := os.ReadFile(filepath.Join(repoRoot, filepath.FromSlash(input.RosterJSON)))
	if err != nil {
		return Report{}, fail("roster-read", err)
	}
	if err := json.Unmarshal(rosterJSON, &rosterDocument); err != nil {
		return Report{}, fail("roster-json", err)
	}
	roster, err := decodeJSON(rosterDocument.Roster)
	if err != nil {
		return Report{}, fail("roster-json", err)
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

	rootCBOR, err := canon.Encode(rootSet)
	if err != nil {
		return Report{}, fail("root-set-cbor", err)
	}
	rootDigest := digest(rootDomain, rootCBOR)
	domainDigest := digest(deploymentDomain, rootDigest[:])

	resetRoot := cloneMap(rootSet.(map[string]any))
	resetRoot["fresh_deployment_instance_id"] = input.ResetFreshDeploymentInstanceID
	resetCBOR, err := canon.Encode(resetRoot)
	if err != nil {
		return Report{}, fail("reset-root-cbor", err)
	}
	resetRootDigest := digest(rootDomain, resetCBOR)
	resetDomainDigest := digest(deploymentDomain, resetRootDigest[:])

	eventIdentity, err := decodeJSON(input.SourceEventIdentity)
	if err != nil {
		return Report{}, fail("source-event-json", err)
	}
	eventCBOR, err := canon.Encode(eventIdentity)
	if err != nil {
		return Report{}, fail("source-event-cbor", err)
	}
	continuity := digest(continuityDomain, eventCBOR)

	return Report{
		SchemaVersion: 1, ProfileID: profileID,
		RosterSHA256: hex.EncodeToString(sum(rosterCBOR)), RosterCBORBytes: len(rosterCBOR),
		RootSetDigest: hex.EncodeToString(rootDigest[:]), DeploymentDomain: hex.EncodeToString(domainDigest[:]),
		ResetRootSetDigest: hex.EncodeToString(resetRootDigest[:]), ResetDeploymentDomain: hex.EncodeToString(resetDomainDigest[:]),
		ContinuityKey: hex.EncodeToString(continuity[:]), ResetContinuityKey: hex.EncodeToString(continuity[:]),
		StructuralResult: "structural-pass", DeploymentOutcome: "blocked", ActivationEligible: false,
	}, nil
}

func decodeJSON(raw []byte) (any, error) {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	var value any
	err := decoder.Decode(&value)
	return value, err
}

func digest(domain string, body []byte) [32]byte {
	h := sha256.New()
	h.Write([]byte(domain))
	h.Write(body)
	var out [32]byte
	copy(out[:], h.Sum(nil))
	return out
}

func sum(body []byte) []byte {
	value := sha256.Sum256(body)
	return value[:]
}

func rejectForbidden(value any) error {
	switch value := value.(type) {
	case map[string]any:
		for name, child := range value {
			if _, found := forbiddenRootFields[name]; found {
				return &HarnessError{"forbidden-post-domain-field", fmt.Sprintf("root-set preimage contains %s", name)}
			}
			if err := rejectForbidden(child); err != nil {
				return err
			}
		}
	case []any:
		for _, child := range value {
			if err := rejectForbidden(child); err != nil {
				return err
			}
		}
	}
	return nil
}

func cloneMap(input map[string]any) map[string]any {
	output := make(map[string]any, len(input))
	for key, value := range input {
		output[key] = value
	}
	return output
}

func fail(code string, err error) error { return &HarnessError{code, err.Error()} }
