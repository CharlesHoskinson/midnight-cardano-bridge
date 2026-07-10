package harness

import (
  "encoding/json"
  "os"
  "testing"
)

func TestStructuralCBORSchemaManifestV1(t *testing.T) {
  raw, err := os.ReadFile("../../../fixtures/structural-cbor-schema-v1.json")
  if err != nil { t.Fatal(err) }
  var m struct { SchemaVersion int `json:"schema_version"`; Projection string `json:"projection"`; RootSet map[string]any `json:"root_set"`; Event map[string]any `json:"event"`; Gate map[string]any `json:"gate_record"` }
  if err := json.Unmarshal(raw, &m); err != nil { t.Fatal(err) }
  if m.SchemaVersion != 1 || m.Projection == "" { t.Fatalf("invalid manifest version/projection") }
  if len(m.RootSet) != 11 || len(m.Event) != 7 || len(m.Gate) != 4 { t.Fatalf("manifest does not cover all members") }
}
