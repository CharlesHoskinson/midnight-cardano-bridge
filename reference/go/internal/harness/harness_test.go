package harness

import (
	"path/filepath"
	"testing"
)

func repoRoot(t *testing.T) string {
	t.Helper()
	root, err := filepath.Abs(filepath.Join("..", "..", "..", ".."))
	if err != nil {
		t.Fatal(err)
	}
	return root
}

func fixture(t *testing.T, name string) string {
	t.Helper()
	return filepath.Join(repoRoot(t), "reference", "fixtures", name)
}

func TestStructuralReportMatchesRosterAndSafetyBoundary(t *testing.T) {
	report, err := RunFixture(repoRoot(t), fixture(t, "structural-v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	if report.RosterSHA256 != "2f0383d6eb9f781d82550edd3918b28c428eb28e5945f7d04fe770d1fced528f" {
		t.Fatalf("unexpected roster hash %s", report.RosterSHA256)
	}
	if report.RosterCBORBytes != 7705 {
		t.Fatalf("unexpected roster length %d", report.RosterCBORBytes)
	}
	if report.DeploymentOutcome != "blocked" || report.ActivationEligible {
		t.Fatalf("unsafe report: %+v", report)
	}
}

func TestResetChangesDomainButNotContinuity(t *testing.T) {
	report, err := RunFixture(repoRoot(t), fixture(t, "structural-v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	if report.RootSetDigest == report.ResetRootSetDigest || report.DeploymentDomain == report.ResetDeploymentDomain {
		t.Fatal("reset did not change root and domain")
	}
	if report.ContinuityKey != report.ResetContinuityKey {
		t.Fatal("domain-independent continuity key changed")
	}
}

func TestPostDomainFieldIsRejected(t *testing.T) {
	_, err := RunFixture(repoRoot(t), fixture(t, "invalid-post-domain-v1.json"))
	if err == nil || ErrorCode(err) != "forbidden-post-domain-field" {
		t.Fatalf("expected forbidden field, got %v", err)
	}
}
