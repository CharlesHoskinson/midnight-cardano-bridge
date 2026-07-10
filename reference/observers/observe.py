#!/usr/bin/env python3
"""Scrapling-only public observations for the structural bridge harness."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence


ADAPTER_REVISION = "mcb.scrapling-observer.v1"
TRUST_LABEL = "unsigned-observation"
MIDNIGHT_HEAD_REQUEST = {
    "jsonrpc": "2.0",
    "id": 1,
    "method": "chain_getFinalizedHead",
    "params": [],
}
MITHRIL_PATH = "/certificates"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
HEX_RE = re.compile(r"^(?:[0-9a-f]{2})*$")
CAPTURE_FIELDS = frozenset(
    {
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
)
EXCHANGE_FIELDS = frozenset(
    {
        "request_method",
        "request_body_hex",
        "request_body_sha256",
        "response_status",
        "response_body_hex",
        "raw_response_sha256",
    }
)
OBSERVATION_FIELDS = frozenset(
    {
        "schema_version",
        "adapter_revision",
        "trust",
        "chain",
        "network",
        "endpoint",
        "observed_at",
        "request_method",
        "request_body_sha256",
        "raw_response_sha256",
        "response_statuses",
        "exchanges",
        "capture_sha256",
        "data",
    }
)
MIDNIGHT_DATA_FIELDS = frozenset(
    {
        "endpoint_reported_head",
        "endpoint_reported_block_number",
        "endpoint_reported_state_root",
        "finality_evaluation",
        "event_inclusion_evaluation",
        "destination_execution_evaluation",
        "affected_gates",
        "gate_status",
    }
)
MITHRIL_DATA_FIELDS = frozenset(
    {
        "certificate_count",
        "endpoint_entity_type_names",
        "scls_profile_evaluation",
        "affected_gates",
        "gate_status",
    }
)
MIDNIGHT_GATE = "S01-BLOCK-03/event-inclusion"
MITHRIL_GATE = "S01-BLOCK-02/public-scls-availability"


def validate_capture(capture: Mapping[str, Any]) -> None:
    """Validate an immutable public-endpoint capture envelope."""
    _require_exact_fields(capture, CAPTURE_FIELDS, "capture-schema")
    if capture["schema_version"] != 1 or capture["adapter_revision"] != ADAPTER_REVISION:
        raise ValueError("capture-schema: unsupported schema or adapter revision")
    if capture["trust"] != TRUST_LABEL:
        raise ValueError("trust-label: captures cannot be authenticated")
    if capture["chain"] not in ("midnight", "cardano"):
        raise ValueError("capture-schema: unsupported chain")
    for field in ("network", "endpoint", "observed_at"):
        if not isinstance(capture[field], str) or not capture[field]:
            raise ValueError(f"capture-schema: invalid {field}")
    _validate_timestamp(capture["observed_at"])

    capture_digest = capture["capture_sha256"]
    if not isinstance(capture_digest, str) or not SHA256_RE.fullmatch(capture_digest):
        raise ValueError("capture-digest: invalid encoding")
    preimage = dict(capture)
    del preimage["capture_sha256"]
    if _sha256(_canonical_json(preimage)) != capture_digest:
        raise ValueError("capture-digest: provenance envelope changed")

    exchanges = capture["exchanges"]
    if (
        isinstance(exchanges, (str, bytes, bytearray))
        or not isinstance(exchanges, Sequence)
        or not exchanges
    ):
        raise ValueError("capture-schema: exchanges must be a non-empty array")

    decoded: list[tuple[Mapping[str, Any], bytes, bytes]] = []
    for exchange in exchanges:
        _require_exact_fields(exchange, EXCHANGE_FIELDS, "capture-schema")
        request = _decode_wire_hex(exchange["request_body_hex"], "request-body")
        response = _decode_wire_hex(exchange["response_body_hex"], "raw-response")
        if _sha256(request) != exchange["request_body_sha256"]:
            raise ValueError("request-body-digest: request bytes changed")
        if _sha256(response) != exchange["raw_response_sha256"]:
            raise ValueError("raw-response-digest: response bytes changed")
        status = exchange["response_status"]
        if isinstance(status, bool) or not isinstance(status, int) or not 200 <= status < 300:
            raise ValueError("response-status: endpoint did not return success")
        decoded.append((exchange, request, response))

    if capture["chain"] == "midnight":
        _validate_midnight_requests(decoded)
    else:
        _validate_mithril_request(decoded)


def _require_exact_fields(
    value: Any, expected: frozenset[str], code: str
) -> None:
    if not isinstance(value, Mapping) or set(value) != expected:
        raise ValueError(f"{code}: fields do not match the registered schema")


def _validate_timestamp(value: str) -> None:
    if not value.endswith("Z"):
        raise ValueError("capture-schema: observed_at must be UTC")
    try:
        parsed = datetime.fromisoformat(value[:-1] + "+00:00")
    except ValueError as exc:
        raise ValueError("capture-schema: invalid observed_at") from exc
    if parsed.utcoffset() != timezone.utc.utcoffset(parsed):
        raise ValueError("capture-schema: observed_at must be UTC")


def _decode_wire_hex(value: Any, field: str) -> bytes:
    if not isinstance(value, str) or not HEX_RE.fullmatch(value):
        raise ValueError(f"capture-schema: invalid {field} hex")
    return bytes.fromhex(value)


def _json_body(body: bytes, error: str) -> Any:
    try:
        return json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError(error) from exc


def _validate_midnight_requests(
    decoded: Sequence[tuple[Mapping[str, Any], bytes, bytes]],
) -> None:
    if len(decoded) != 2 or any(item[0]["request_method"] != "POST" for item in decoded):
        raise ValueError("request-shape: Midnight requires two POST exchanges")
    if decoded[0][1] != _canonical_json(MIDNIGHT_HEAD_REQUEST):
        raise ValueError("request-shape: finalized-head request bytes changed")
    head_response = _json_body(decoded[0][2], "invalid-midnight-response")
    try:
        head = head_response["result"]
    except (KeyError, TypeError) as exc:
        raise ValueError("invalid-midnight-response") from exc
    header_request = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "chain_getHeader",
        "params": [head],
    }
    if decoded[1][1] != _canonical_json(header_request):
        raise ValueError("request-shape: header request is not bound to reported head")


def _validate_mithril_request(
    decoded: Sequence[tuple[Mapping[str, Any], bytes, bytes]],
) -> None:
    if (
        len(decoded) != 1
        or decoded[0][0]["request_method"] != "GET"
        or decoded[0][1] != b""
    ):
        raise ValueError("request-shape: Mithril requires one bodyless GET exchange")


def _canonical_json(value: Any) -> bytes:
    return json.dumps(
        value, ensure_ascii=True, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")


def _sha256(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _derive_midnight_data(capture: Mapping[str, Any]) -> dict[str, Any]:
    head_response = _capture_response_json(capture, 0, "invalid-midnight-response")
    header_response = _capture_response_json(capture, 1, "invalid-midnight-response")
    try:
        head = head_response["result"]
        header = header_response["result"]
        block_number = int(header["number"], 16)
        state_root = header["stateRoot"]
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError("invalid-midnight-response") from exc
    if not isinstance(head, str) or not isinstance(state_root, str):
        raise ValueError("invalid-midnight-response")

    return {
        "endpoint_reported_head": head,
        "endpoint_reported_block_number": block_number,
        "endpoint_reported_state_root": state_root,
        "finality_evaluation": "not-performed",
        "event_inclusion_evaluation": "not-performed",
        "destination_execution_evaluation": "not-performed",
        "affected_gates": [MIDNIGHT_GATE],
        "gate_status": "unresolved",
    }


def normalize_midnight(capture: Mapping[str, Any]) -> dict[str, Any]:
    """Normalize only a validated Midnight capture envelope."""
    validate_capture(capture)
    if capture["chain"] != "midnight":
        raise ValueError("capture-schema: expected Midnight capture")
    record = _base_observation(
        capture, "POST:chain_getFinalizedHead+chain_getHeader"
    )
    record["data"] = _derive_midnight_data(capture)
    validate_observation(record)
    return record


def _entity_type_name(value: Any) -> str:
    if isinstance(value, str) and value:
        return value
    if isinstance(value, Mapping) and len(value) == 1:
        name = next(iter(value))
        if isinstance(name, str) and name:
            return name
    raise ValueError("invalid-mithril-response")


def _derive_mithril_data(capture: Mapping[str, Any]) -> dict[str, Any]:
    raw = _capture_response_json(capture, 0, "invalid-mithril-response")
    if isinstance(raw, (str, bytes, bytearray)) or not isinstance(raw, Sequence):
        raise ValueError("invalid-mithril-response")

    names: set[str] = set()
    for certificate in raw:
        if not isinstance(certificate, Mapping):
            raise ValueError("invalid-mithril-response")
        names.add(_entity_type_name(certificate.get("signed_entity_type")))

    return {
        "certificate_count": len(raw),
        "endpoint_entity_type_names": sorted(names),
        "scls_profile_evaluation": "not-performed",
        "affected_gates": [MITHRIL_GATE],
        "gate_status": "unresolved",
    }


def normalize_mithril(capture: Mapping[str, Any]) -> dict[str, Any]:
    """Normalize only a validated Mithril capture without trust inference."""
    validate_capture(capture)
    if capture["chain"] != "cardano":
        raise ValueError("capture-schema: expected Cardano capture")
    record = _base_observation(capture, "GET")
    record["data"] = _derive_mithril_data(capture)
    validate_observation(record)
    return record


def normalize_capture(capture: Mapping[str, Any]) -> dict[str, Any]:
    validate_capture(capture)
    if capture["chain"] == "midnight":
        return normalize_midnight(capture)
    return normalize_mithril(capture)


def _capture_response_json(
    capture: Mapping[str, Any], index: int, error: str
) -> Any:
    body = _decode_wire_hex(capture["exchanges"][index]["response_body_hex"], "raw-response")
    return _json_body(body, error)


def _base_observation(
    capture: Mapping[str, Any], request_method: str
) -> dict[str, Any]:
    exchanges = [dict(exchange) for exchange in capture["exchanges"]]
    return {
        "schema_version": capture["schema_version"],
        "adapter_revision": capture["adapter_revision"],
        "trust": capture["trust"],
        "chain": capture["chain"],
        "network": capture["network"],
        "endpoint": capture["endpoint"],
        "observed_at": capture["observed_at"],
        "request_method": request_method,
        "request_body_sha256": _aggregate_exchange_digest(
            exchanges, "request_body_hex"
        ),
        "raw_response_sha256": _aggregate_exchange_digest(
            exchanges, "response_body_hex"
        ),
        "response_statuses": [exchange["response_status"] for exchange in exchanges],
        "exchanges": exchanges,
        "capture_sha256": capture["capture_sha256"],
    }


def _aggregate_exchange_digest(
    exchanges: Sequence[Mapping[str, Any]], field: str
) -> str:
    parts = [_decode_wire_hex(exchange[field], field) for exchange in exchanges]
    return _sha256(parts[0] if len(parts) == 1 else _framed(parts))


def validate_observation(record: Mapping[str, Any]) -> None:
    _require_exact_fields(record, OBSERVATION_FIELDS, "observation-schema")
    if record["trust"] != TRUST_LABEL:
        raise ValueError("trust-label: observations cannot be authenticated")
    capture = {
        field: record[field]
        for field in CAPTURE_FIELDS
    }
    validate_capture(capture)

    exchanges = capture["exchanges"]
    expected_method = (
        "POST:chain_getFinalizedHead+chain_getHeader"
        if capture["chain"] == "midnight"
        else "GET"
    )
    if record["request_method"] != expected_method:
        raise ValueError("observation-provenance: request method changed")
    if record["request_body_sha256"] != _aggregate_exchange_digest(
        exchanges, "request_body_hex"
    ):
        raise ValueError("observation-provenance: request digest changed")
    if record["raw_response_sha256"] != _aggregate_exchange_digest(
        exchanges, "response_body_hex"
    ):
        raise ValueError("observation-provenance: response digest changed")
    if record["response_statuses"] != [
        exchange["response_status"] for exchange in exchanges
    ]:
        raise ValueError("observation-provenance: response status changed")

    data = record["data"]
    if capture["chain"] == "midnight":
        _validate_midnight_data(data)
        expected_data = _derive_midnight_data(capture)
    else:
        _validate_mithril_data(data)
        expected_data = _derive_mithril_data(capture)
    if data != expected_data:
        raise ValueError(
            "observation-data: normalized data does not match preserved response bytes"
        )


def _validate_gate_reference(data: Mapping[str, Any], expected: str) -> None:
    gates = data.get("affected_gates")
    if (
        not isinstance(gates, list)
        or any(not isinstance(gate, str) for gate in gates)
        or len(gates) != len(set(gates))
        or gates != [expected]
    ):
        raise ValueError("gate-reference: gate ids must exactly match the roster")
    if data.get("gate_status") != "unresolved":
        raise ValueError("gate-claim: observations cannot change gate state")


def _validate_midnight_data(data: Any) -> None:
    _require_exact_fields(data, MIDNIGHT_DATA_FIELDS, "data-schema")
    _validate_gate_reference(data, MIDNIGHT_GATE)
    if any(
        data[field] != "not-performed"
        for field in (
            "finality_evaluation",
            "event_inclusion_evaluation",
            "destination_execution_evaluation",
        )
    ):
        raise ValueError("trust-claim: security evaluation was not performed")
    if (
        not isinstance(data["endpoint_reported_head"], str)
        or isinstance(data["endpoint_reported_block_number"], bool)
        or not isinstance(data["endpoint_reported_block_number"], int)
        or data["endpoint_reported_block_number"] < 0
        or not isinstance(data["endpoint_reported_state_root"], str)
    ):
        raise ValueError("data-schema: invalid Midnight endpoint values")


def _validate_mithril_data(data: Any) -> None:
    _require_exact_fields(data, MITHRIL_DATA_FIELDS, "data-schema")
    _validate_gate_reference(data, MITHRIL_GATE)
    if data["scls_profile_evaluation"] != "not-performed":
        raise ValueError("trust-claim: SCLS profile evaluation was not performed")
    count = data["certificate_count"]
    names = data["endpoint_entity_type_names"]
    if (
        isinstance(count, bool)
        or not isinstance(count, int)
        or count < 0
        or not isinstance(names, list)
        or any(not isinstance(name, str) or not name for name in names)
        or names != sorted(set(names))
    ):
        raise ValueError("data-schema: invalid Mithril endpoint values")


def _response_body(response: Any) -> bytes:
    body = response.body
    if isinstance(body, bytes):
        return body
    if isinstance(body, bytearray):
        return bytes(body)
    if isinstance(body, str):
        return body.encode("utf-8")
    return bytes(body)


def _framed(parts: Sequence[bytes]) -> bytes:
    return b"".join(len(part).to_bytes(8, "big") + part for part in parts)


def _exchange(
    request_method: str, request_body: bytes, response: Any
) -> dict[str, Any]:
    response_body = _response_body(response)
    return {
        "request_method": request_method,
        "request_body_hex": request_body.hex(),
        "request_body_sha256": _sha256(request_body),
        "response_status": response.status,
        "response_body_hex": response_body.hex(),
        "raw_response_sha256": _sha256(response_body),
    }


def _capture_envelope(
    *,
    chain: str,
    network: str,
    endpoint: str,
    exchanges: Sequence[Mapping[str, Any]],
) -> dict[str, Any]:
    capture: dict[str, Any] = {
        "schema_version": 1,
        "adapter_revision": ADAPTER_REVISION,
        "trust": TRUST_LABEL,
        "chain": chain,
        "network": network,
        "endpoint": endpoint,
        "observed_at": _now(),
        "exchanges": [dict(exchange) for exchange in exchanges],
    }
    capture["capture_sha256"] = _sha256(_canonical_json(capture))
    return capture


def fetch_midnight(endpoint: str, network: str = "preview") -> dict[str, Any]:
    from scrapling.fetchers import Fetcher

    endpoint = endpoint.rstrip("/")
    headers = {"Content-Type": "application/json"}
    head_request = _canonical_json(MIDNIGHT_HEAD_REQUEST)
    head_response = Fetcher.post(endpoint, data=head_request, headers=headers)
    head_raw = _response_body(head_response)
    head_json = _json_body(head_raw, "invalid-midnight-response")
    try:
        head = head_json["result"]
    except (KeyError, TypeError) as exc:
        raise ValueError("invalid-midnight-response") from exc

    header_request = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "chain_getHeader",
        "params": [head],
    }
    header_request_bytes = _canonical_json(header_request)
    header_response = Fetcher.post(endpoint, data=header_request_bytes, headers=headers)
    capture = _capture_envelope(
        chain="midnight",
        network=network,
        endpoint=endpoint,
        exchanges=(
            _exchange("POST", head_request, head_response),
            _exchange("POST", header_request_bytes, header_response),
        ),
    )
    return normalize_midnight(capture)


def fetch_mithril(endpoint: str, network: str = "pre-release-preview") -> dict[str, Any]:
    from scrapling.fetchers import Fetcher

    endpoint = endpoint.rstrip("/")
    url = endpoint if endpoint.endswith(MITHRIL_PATH) else endpoint + MITHRIL_PATH
    response = Fetcher.get(url)
    capture = _capture_envelope(
        chain="cardano",
        network=network,
        endpoint=url,
        exchanges=(_exchange("GET", b"", response),),
    )
    return normalize_mithril(capture)


def _now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _write_record(path: Path, record: Mapping[str, Any]) -> None:
    validate_observation(record)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    fixture = commands.add_parser("fixture", help="normalize a captured JSON fixture")
    fixture.add_argument("input", type=Path)
    fixture.add_argument("output", type=Path)

    midnight = commands.add_parser("live-midnight", help="observe Midnight preview RPC")
    midnight.add_argument("output", type=Path)
    midnight.add_argument("--endpoint", default="https://rpc.preview.midnight.network")
    midnight.add_argument("--network", default="preview")

    mithril = commands.add_parser("live-mithril", help="observe Mithril preview certificates")
    mithril.add_argument("output", type=Path)
    mithril.add_argument(
        "--endpoint",
        default="https://aggregator.pre-release-preview.api.mithril.network/aggregator",
    )
    mithril.add_argument("--network", default="pre-release-preview")
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    if args.command == "live-midnight":
        record = fetch_midnight(args.endpoint, args.network)
    elif args.command == "live-mithril":
        record = fetch_mithril(args.endpoint, args.network)
    else:
        capture = json.loads(args.input.read_text(encoding="utf-8"))
        record = normalize_capture(capture)
    _write_record(args.output, record)
    print(json.dumps(record, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
