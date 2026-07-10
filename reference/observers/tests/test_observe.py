import copy
import hashlib
import io
import json
import sys
import tempfile
import unittest
from argparse import Namespace
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

OBSERVER_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(OBSERVER_DIR))

import observe


class CaptureFixtureTests(unittest.TestCase):
    @staticmethod
    def _load(name):
        path = OBSERVER_DIR / "fixtures" / name
        return json.loads(path.read_text(encoding="utf-8"))

    @staticmethod
    def _reseal(capture):
        preimage = dict(capture)
        preimage.pop("capture_sha256", None)
        canonical = json.dumps(
            preimage,
            ensure_ascii=True,
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
        capture["capture_sha256"] = hashlib.sha256(canonical).hexdigest()

    def test_capture_validator_accepts_committed_envelopes(self):
        validator = getattr(observe, "validate_capture", None)
        self.assertIsNotNone(validator, "capture validator is required")
        fixture_dir = OBSERVER_DIR / "fixtures"
        for path in fixture_dir.glob("*-v1.json"):
            with self.subTest(path=path.name):
                validator(json.loads(path.read_text(encoding="utf-8")))

    def test_capture_validator_rejects_provenance_tamper(self):
        capture = self._load("midnight-finalized-v1.json")
        capture["endpoint"] += "/tampered"
        with self.assertRaisesRegex(ValueError, "capture-digest"):
            observe.validate_capture(capture)

    def test_capture_validator_rejects_resealed_request_and_response_tamper(self):
        request_tamper = self._load("midnight-finalized-v1.json")
        request_tamper["exchanges"][0]["request_body_hex"] = "00"
        self._reseal(request_tamper)
        with self.assertRaisesRegex(ValueError, "request-body-digest"):
            observe.validate_capture(request_tamper)

        response_tamper = self._load("mithril-certificates-v1.json")
        response_tamper["exchanges"][0]["response_body_hex"] = "00"
        self._reseal(response_tamper)
        with self.assertRaisesRegex(ValueError, "raw-response-digest"):
            observe.validate_capture(response_tamper)

    def test_capture_validator_rejects_trust_relabel_and_unknown_fields(self):
        relabeled = self._load("mithril-certificates-v1.json")
        relabeled["trust"] = "authenticated"
        self._reseal(relabeled)
        with self.assertRaisesRegex(ValueError, "trust-label"):
            observe.validate_capture(relabeled)

        unknown = self._load("midnight-finalized-v1.json")
        unknown["finality_verified"] = True
        self._reseal(unknown)
        with self.assertRaisesRegex(ValueError, "capture-schema"):
            observe.validate_capture(unknown)

        unknown_exchange = self._load("midnight-finalized-v1.json")
        unknown_exchange["exchanges"][0]["checkpoint_approved"] = True
        self._reseal(unknown_exchange)
        with self.assertRaisesRegex(ValueError, "capture-schema"):
            observe.validate_capture(unknown_exchange)

    def test_capture_validator_rejects_bad_status_and_request_sequence(self):
        bad_status = self._load("mithril-certificates-v1.json")
        bad_status["exchanges"][0]["response_status"] = 503
        self._reseal(bad_status)
        with self.assertRaisesRegex(ValueError, "response-status"):
            observe.validate_capture(bad_status)

        wrong_request = self._load("midnight-finalized-v1.json")
        body = b'{"id":1,"jsonrpc":"2.0","method":"chain_getHeader","params":[]}'
        wrong_request["exchanges"][0]["request_body_hex"] = body.hex()
        wrong_request["exchanges"][0]["request_body_sha256"] = hashlib.sha256(body).hexdigest()
        self._reseal(wrong_request)
        with self.assertRaisesRegex(ValueError, "request-shape"):
            observe.validate_capture(wrong_request)

    def test_capture_fixtures_retain_exact_wire_bytes_and_digests(self):
        fixture_dir = OBSERVER_DIR / "fixtures"
        expected_top_level = {
            "schema_version",
            "adapter_revision",
            "trust",
            "chain",
            "network",
            "endpoint",
            "observed_at",
            "exchanges",
            "capture_sha256",
        }
        expected_exchange = {
            "request_method",
            "request_body_hex",
            "request_body_sha256",
            "response_status",
            "response_body_hex",
            "raw_response_sha256",
        }

        for path in fixture_dir.glob("*-v1.json"):
            with self.subTest(path=path.name):
                capture = json.loads(path.read_text(encoding="utf-8"))
                self.assertIsInstance(capture, dict)
                self.assertEqual(set(capture), expected_top_level)
                self.assertEqual(capture["trust"], "unsigned-observation")
                self.assertEqual(capture["adapter_revision"], "mcb.scrapling-observer.v1")
                capture_preimage = dict(capture)
                capture_digest = capture_preimage.pop("capture_sha256")
                canonical = json.dumps(
                    capture_preimage,
                    ensure_ascii=True,
                    sort_keys=True,
                    separators=(",", ":"),
                ).encode("utf-8")
                self.assertEqual(hashlib.sha256(canonical).hexdigest(), capture_digest)
                self.assertTrue(capture["exchanges"])
                for exchange in capture["exchanges"]:
                    self.assertEqual(set(exchange), expected_exchange)
                    request = bytes.fromhex(exchange["request_body_hex"])
                    response = bytes.fromhex(exchange["response_body_hex"])
                    self.assertEqual(
                        hashlib.sha256(request).hexdigest(),
                        exchange["request_body_sha256"],
                    )
                    self.assertEqual(
                        hashlib.sha256(response).hexdigest(),
                        exchange["raw_response_sha256"],
                    )


class ObservationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        fixture_dir = OBSERVER_DIR / "fixtures"
        cls.midnight_capture = json.loads(
            (fixture_dir / "midnight-finalized-v1.json").read_text(encoding="utf-8")
        )
        cls.mithril_capture = json.loads(
            (fixture_dir / "mithril-certificates-v1.json").read_text(encoding="utf-8")
        )

    def _normalize(self, function, capture):
        try:
            return function(copy.deepcopy(capture))
        except TypeError as exc:
            self.fail(f"normalizer must accept one validated capture envelope: {exc}")

    @staticmethod
    def _replace_response(capture, index, value):
        body = json.dumps(
            value,
            ensure_ascii=True,
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
        exchange = capture["exchanges"][index]
        exchange["response_body_hex"] = body.hex()
        exchange["raw_response_sha256"] = hashlib.sha256(body).hexdigest()
        CaptureFixtureTests._reseal(capture)

    def test_midnight_normalization_is_unsigned_bounded_and_exactly_mapped(self):
        record = self._normalize(observe.normalize_midnight, self.midnight_capture)
        self.assertEqual(record["trust"], "unsigned-observation")
        self.assertEqual(
            record["data"]["affected_gates"],
            ["S01-BLOCK-03/event-inclusion"],
        )
        self.assertEqual(record["data"]["endpoint_reported_block_number"], 1541269)
        self.assertEqual(record["data"]["finality_evaluation"], "not-performed")
        self.assertEqual(record["data"]["event_inclusion_evaluation"], "not-performed")
        self.assertEqual(record["data"]["destination_execution_evaluation"], "not-performed")
        self.assertNotIn("finalized_head", record["data"])
        observe.validate_observation(record)

    def test_mithril_reports_names_without_inferring_scls(self):
        record = self._normalize(observe.normalize_mithril, self.mithril_capture)
        self.assertEqual(record["trust"], "unsigned-observation")
        self.assertEqual(record["data"]["certificate_count"], 3)
        self.assertEqual(
            record["data"]["endpoint_entity_type_names"],
            ["CardanoDatabase", "CardanoTransactions"],
        )
        self.assertEqual(record["data"]["scls_profile_evaluation"], "not-performed")
        self.assertEqual(
            record["data"]["affected_gates"],
            ["S01-BLOCK-02/public-scls-availability"],
        )
        self.assertNotIn("observed_scls_entity", record["data"])
        observe.validate_observation(record)

    def test_scls_like_endpoint_name_remains_an_uninterpreted_name(self):
        capture = copy.deepcopy(self.mithril_capture)
        payload = [
            {
                "hash": "a" * 64,
                "epoch": 1,
                "signed_entity_type": {"SCLSUnregisteredShape": [1, 2]},
            }
        ]
        self._replace_response(capture, 0, payload)
        record = self._normalize(observe.normalize_mithril, capture)
        self.assertEqual(
            record["data"]["endpoint_entity_type_names"],
            ["SCLSUnregisteredShape"],
        )
        self.assertEqual(record["data"]["scls_profile_evaluation"], "not-performed")
        self.assertNotIn("observed_scls_entity", record["data"])

    def test_observation_validator_rejects_trust_relabel_positive_claims_and_unknown_fields(self):
        record = self._normalize(observe.normalize_mithril, self.mithril_capture)
        record["trust"] = "authenticated"
        with self.assertRaisesRegex(ValueError, "trust-label"):
            observe.validate_observation(record)

        for claim in (
            "finality_verified",
            "scls_verified",
            "event_inclusion_verified",
            "destination_execution_confirmed",
        ):
            with self.subTest(claim=claim):
                claimed = self._normalize(observe.normalize_mithril, self.mithril_capture)
                claimed["data"][claim] = True
                with self.assertRaisesRegex(ValueError, "data-schema"):
                    observe.validate_observation(claimed)

        unknown = self._normalize(observe.normalize_mithril, self.mithril_capture)
        unknown["checkpoint_approved"] = True
        with self.assertRaisesRegex(ValueError, "observation-schema"):
            observe.validate_observation(unknown)

    def test_observation_validator_rejects_duplicate_and_unknown_gate_references(self):
        record = self._normalize(observe.normalize_midnight, self.midnight_capture)
        record["data"]["affected_gates"] *= 2
        with self.assertRaisesRegex(ValueError, "gate-reference"):
            observe.validate_observation(record)

        record = self._normalize(observe.normalize_midnight, self.midnight_capture)
        record["data"]["affected_gates"] = ["S01-BLOCK-03"]
        with self.assertRaisesRegex(ValueError, "gate-reference"):
            observe.validate_observation(record)

    def test_normalization_rejects_invalid_envelopes_and_hostile_responses(self):
        tampered = copy.deepcopy(self.midnight_capture)
        tampered["endpoint"] += "/tampered"
        with self.assertRaisesRegex(ValueError, "capture-digest"):
            self._normalize(observe.normalize_midnight, tampered)

        hostile = copy.deepcopy(self.mithril_capture)
        self._replace_response(hostile, 0, {"signed_entity_type": "SCLS"})
        with self.assertRaisesRegex(ValueError, "invalid-mithril-response"):
            self._normalize(observe.normalize_mithril, hostile)

    def test_captured_observations_are_unsigned_and_leave_gates_open(self):
        evidence_dir = OBSERVER_DIR.parent / "evidence" / "observations"
        for path in evidence_dir.glob("*-unsigned.json"):
            with self.subTest(path=path.name):
                record = json.loads(path.read_text(encoding="utf-8"))
                observe.validate_observation(record)
                self.assertEqual(record["trust"], "unsigned-observation")
                self.assertEqual(record["data"]["gate_status"], "unresolved")


class TransportTests(unittest.TestCase):
    class Response:
        def __init__(self, body, status=200):
            self.body = body
            self.status = status

        def json(self):
            return json.loads(self.body)

    @staticmethod
    def _wire(value):
        return json.dumps(
            value,
            ensure_ascii=True,
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")

    def test_midnight_transport_sends_exact_preserialized_request_bytes(self):
        head = "0x" + "ab" * 32
        head_body = self._wire({"jsonrpc": "2.0", "id": 1, "result": head})
        header_body = self._wire(
            {
                "jsonrpc": "2.0",
                "id": 2,
                "result": {
                    "number": "0x2a",
                    "stateRoot": "0x" + "cd" * 32,
                },
            }
        )
        responses = [self.Response(head_body), self.Response(header_body)]
        with patch("scrapling.fetchers.Fetcher.post", side_effect=responses) as post:
            try:
                record = observe.fetch_midnight("https://rpc.example.invalid", "preview")
            except TypeError as exc:
                self.fail(f"transport must build and normalize a capture envelope: {exc}")

        expected_head = self._wire(observe.MIDNIGHT_HEAD_REQUEST)
        expected_header = self._wire(
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "chain_getHeader",
                "params": [head],
            }
        )
        self.assertEqual(post.call_count, 2)
        self.assertEqual(post.call_args_list[0].kwargs["data"], expected_head)
        self.assertEqual(post.call_args_list[1].kwargs["data"], expected_header)
        self.assertNotIn("json", post.call_args_list[0].kwargs)
        self.assertNotIn("json", post.call_args_list[1].kwargs)
        self.assertEqual(
            post.call_args_list[0].kwargs["headers"],
            {"Content-Type": "application/json"},
        )
        self.assertEqual(
            bytes.fromhex(record["exchanges"][0]["request_body_hex"]),
            expected_head,
        )
        self.assertEqual(
            bytes.fromhex(record["exchanges"][1]["response_body_hex"]),
            header_body,
        )
        observe.validate_observation(record)

    def test_mithril_transport_retains_exact_get_response_bytes_and_status(self):
        body = self._wire(
            [
                {
                    "hash": "a" * 64,
                    "signed_entity_type": {"CardanoTransactions": [1, 2]},
                }
            ]
        )
        response = self.Response(body, status=206)
        with patch("scrapling.fetchers.Fetcher.get", return_value=response) as get:
            try:
                record = observe.fetch_mithril(
                    "https://aggregator.example.invalid/aggregator",
                    "pre-release-preview",
                )
            except TypeError as exc:
                self.fail(f"transport must build and normalize a capture envelope: {exc}")

        get.assert_called_once_with(
            "https://aggregator.example.invalid/aggregator/certificates"
        )
        self.assertEqual(record["response_statuses"], [206])
        self.assertEqual(bytes.fromhex(record["exchanges"][0]["response_body_hex"]), body)
        self.assertEqual(record["data"]["scls_profile_evaluation"], "not-performed")
        observe.validate_observation(record)

    def test_observer_dependencies_are_exactly_pinned(self):
        requirements = OBSERVER_DIR / "requirements.txt"
        self.assertTrue(requirements.exists(), "observer requirements must be pinned")
        lines = {
            line.strip()
            for line in requirements.read_text(encoding="utf-8").splitlines()
            if line.strip()
        }
        self.assertEqual(lines, {"scrapling==0.4.10", "cbor2==5.7.1"})

    def test_fixture_cli_normalizes_only_the_envelopes_own_provenance(self):
        fixture = OBSERVER_DIR / "fixtures" / "midnight-finalized-v1.json"
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "observation.json"
            args = Namespace(command="fixture", input=fixture, output=output)
            with patch.object(observe, "_parse_args", return_value=args):
                try:
                    with redirect_stdout(io.StringIO()):
                        result = observe.main()
                except (AttributeError, TypeError) as exc:
                    self.fail(
                        "fixture CLI must consume a capture envelope without "
                        f"overrides: {exc}"
                    )
            self.assertEqual(result, 0)
            record = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(record["endpoint"], "https://rpc.preview.midnight.network")
            self.assertEqual(record["observed_at"], "2026-07-10T00:00:00Z")
            observe.validate_observation(record)


if __name__ == "__main__":
    unittest.main()
