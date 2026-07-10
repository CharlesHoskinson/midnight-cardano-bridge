import json
import sys
import unittest
from pathlib import Path

OBSERVER_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(OBSERVER_DIR))

from observe import normalize_midnight, normalize_mithril, validate_observation


class ObservationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        fixture_dir = OBSERVER_DIR / "fixtures"
        cls.raw_midnight = json.loads(
            (fixture_dir / "midnight-finalized-v1.json").read_text(encoding="utf-8")
        )
        cls.raw_mithril = json.loads(
            (fixture_dir / "mithril-certificates-v1.json").read_text(encoding="utf-8")
        )

    def test_midnight_normalization_is_unsigned_and_bounded(self):
        record = normalize_midnight(
            self.raw_midnight,
            {
                "network": "preview",
                "endpoint": "https://rpc.preview.midnight.network",
                "observed_at": "2026-07-10T00:00:00Z",
            },
        )
        self.assertEqual(record["trust"], "unsigned-observation")
        self.assertEqual(record["data"]["finalized_block_number"], 1541269)
        self.assertEqual(
            record["data"]["finalized_head"], self.raw_midnight["head"]["result"]
        )
        self.assertEqual(len(record["raw_response_sha256"]), 64)
        validate_observation(record)

    def test_mithril_normalization_counts_entity_types_without_scls_claim(self):
        record = normalize_mithril(
            self.raw_mithril,
            {
                "network": "pre-release-preview",
                "endpoint": "https://aggregator.pre-release-preview.api.mithril.network/aggregator/certificates",
                "observed_at": "2026-07-10T00:00:00Z",
            },
        )
        self.assertEqual(record["trust"], "unsigned-observation")
        self.assertEqual(record["data"]["certificate_count"], 3)
        self.assertEqual(record["data"]["signed_entity_counts"]["CardanoTransactions"], 2)
        self.assertEqual(record["data"]["signed_entity_counts"]["CardanoDatabase"], 1)
        self.assertFalse(record["data"]["observed_scls_entity"])
        validate_observation(record)

    def test_authenticated_relabel_is_rejected(self):
        record = normalize_mithril(
            self.raw_mithril,
            {
                "network": "pre-release-preview",
                "endpoint": "https://example.invalid/certificates",
                "observed_at": "2026-07-10T00:00:00Z",
            },
        )
        record["trust"] = "authenticated"
        with self.assertRaisesRegex(ValueError, "trust-label"):
            validate_observation(record)

    def test_missing_provenance_is_rejected(self):
        record = normalize_midnight(
            self.raw_midnight,
            {
                "network": "preview",
                "endpoint": "https://rpc.preview.midnight.network",
                "observed_at": "2026-07-10T00:00:00Z",
            },
        )
        del record["adapter_revision"]
        with self.assertRaisesRegex(ValueError, "missing-provenance"):
            validate_observation(record)

    def test_captured_observations_are_unsigned_and_leave_gates_open(self):
        evidence_dir = OBSERVER_DIR.parent / "evidence" / "observations"
        for path in evidence_dir.glob("*-unsigned.json"):
            with self.subTest(path=path.name):
                record = json.loads(path.read_text(encoding="utf-8"))
                validate_observation(record)
                self.assertEqual(record["trust"], "unsigned-observation")
                self.assertEqual(record["data"]["gate_status"], "unresolved")


if __name__ == "__main__":
    unittest.main()
