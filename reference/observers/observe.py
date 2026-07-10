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


def _canonical_json(value: Any) -> bytes:
    return json.dumps(
        value, ensure_ascii=True, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")


def _sha256(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _response_digest(raw: Any, meta: Mapping[str, Any]) -> str:
    response_bytes = meta.get("raw_response_bytes")
    if response_bytes is None:
        response_bytes = _canonical_json(raw)
    elif isinstance(response_bytes, str):
        response_bytes = response_bytes.encode("utf-8")
    elif not isinstance(response_bytes, bytes):
        raise ValueError("invalid-provenance: raw_response_bytes")
    return _sha256(response_bytes)


def _base_record(
    *,
    chain: str,
    meta: Mapping[str, Any],
    request_method: str,
    request_body: Any,
    raw: Any,
) -> dict[str, Any]:
    required_meta = ("network", "endpoint", "observed_at")
    missing = [name for name in required_meta if not meta.get(name)]
    if missing:
        raise ValueError(f"missing-provenance: {','.join(missing)}")

    request_bytes = b"" if request_body is None else _canonical_json(request_body)
    return {
        "schema_version": 1,
        "chain": chain,
        "network": str(meta["network"]),
        "endpoint": str(meta["endpoint"]),
        "request_method": request_method,
        "request_body_sha256": _sha256(request_bytes),
        "observed_at": str(meta["observed_at"]),
        "raw_response_sha256": _response_digest(raw, meta),
        "adapter_revision": ADAPTER_REVISION,
        "trust": TRUST_LABEL,
    }


def normalize_midnight(raw: Mapping[str, Any], meta: Mapping[str, Any]) -> dict[str, Any]:
    """Normalize a finalized-head/header JSON-RPC response pair."""
    try:
        head = raw["head"]["result"]
        header = raw["header"]["result"]
        block_number = int(header["number"], 16)
        state_root = header["stateRoot"]
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError("invalid-midnight-response") from exc

    header_request = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "chain_getHeader",
        "params": [head],
    }
    record = _base_record(
        chain="midnight",
        meta=meta,
        request_method="POST:chain_getFinalizedHead+chain_getHeader",
        request_body=[MIDNIGHT_HEAD_REQUEST, header_request],
        raw=raw,
    )
    record["data"] = {
        "finalized_head": head,
        "finalized_block_number": block_number,
        "state_root": state_root,
        "affected_gates": ["S01-BLOCK-02", "S01-BLOCK-03", "S01-BLOCK-05"],
        "gate_status": "unresolved",
    }
    validate_observation(record)
    return record


def _entity_type_name(value: Any) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, Mapping) and value:
        return str(next(iter(value)))
    return "unknown"


def normalize_mithril(raw: Sequence[Any], meta: Mapping[str, Any]) -> dict[str, Any]:
    """Normalize a Mithril certificate listing without authenticating it."""
    if isinstance(raw, (str, bytes, bytearray)) or not isinstance(raw, Sequence):
        raise ValueError("invalid-mithril-response")

    counts: dict[str, int] = {}
    for certificate in raw:
        if not isinstance(certificate, Mapping):
            raise ValueError("invalid-mithril-response")
        name = _entity_type_name(certificate.get("signed_entity_type"))
        counts[name] = counts.get(name, 0) + 1

    record = _base_record(
        chain="cardano",
        meta=meta,
        request_method="GET",
        request_body=None,
        raw=raw,
    )
    record["data"] = {
        "certificate_count": len(raw),
        "signed_entity_counts": dict(sorted(counts.items())),
        "observed_scls_entity": any("scls" in name.casefold() for name in counts),
        "affected_gates": ["S01-BLOCK-01", "S01-BLOCK-03", "S01-BLOCK-05"],
        "gate_status": "unresolved",
    }
    validate_observation(record)
    return record


def validate_observation(record: Mapping[str, Any]) -> None:
    required = (
        "schema_version",
        "chain",
        "network",
        "endpoint",
        "request_method",
        "request_body_sha256",
        "observed_at",
        "raw_response_sha256",
        "adapter_revision",
        "trust",
        "data",
    )
    missing = [name for name in required if name not in record or record[name] in (None, "")]
    if missing:
        raise ValueError(f"missing-provenance: {','.join(missing)}")
    if record["trust"] != TRUST_LABEL:
        raise ValueError("trust-label: observations cannot be authenticated")
    if record["schema_version"] != 1 or record["adapter_revision"] != ADAPTER_REVISION:
        raise ValueError("invalid-provenance: schema or adapter revision")
    for field in ("request_body_sha256", "raw_response_sha256"):
        if not isinstance(record[field], str) or not SHA256_RE.fullmatch(record[field]):
            raise ValueError(f"invalid-provenance: {field}")
    data = record["data"]
    if not isinstance(data, Mapping) or data.get("gate_status") != "unresolved":
        raise ValueError("gate-claim: observation must leave affected gates unresolved")


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


def fetch_midnight(endpoint: str, network: str = "preview") -> dict[str, Any]:
    from scrapling.fetchers import Fetcher

    endpoint = endpoint.rstrip("/")
    head_response = Fetcher.post(endpoint, json=MIDNIGHT_HEAD_REQUEST)
    head_raw = _response_body(head_response)
    head_json = head_response.json()
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
    header_response = Fetcher.post(endpoint, json=header_request)
    header_raw = _response_body(header_response)
    raw = {"head": head_json, "header": header_response.json()}
    return normalize_midnight(
        raw,
        {
            "network": network,
            "endpoint": endpoint,
            "observed_at": _now(),
            "raw_response_bytes": _framed([head_raw, header_raw]),
        },
    )


def fetch_mithril(endpoint: str, network: str = "pre-release-preview") -> dict[str, Any]:
    from scrapling.fetchers import Fetcher

    endpoint = endpoint.rstrip("/")
    url = endpoint if endpoint.endswith(MITHRIL_PATH) else endpoint + MITHRIL_PATH
    response = Fetcher.get(url)
    return normalize_mithril(
        response.json(),
        {
            "network": network,
            "endpoint": url,
            "observed_at": _now(),
            "raw_response_bytes": _response_body(response),
        },
    )


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
    fixture.add_argument("chain", choices=("midnight", "mithril"))
    fixture.add_argument("input", type=Path)
    fixture.add_argument("output", type=Path)
    fixture.add_argument("observed_at")
    fixture.add_argument("--network")
    fixture.add_argument("--endpoint")

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
        raw = json.loads(args.input.read_text(encoding="utf-8"))
        if args.chain == "midnight":
            record = normalize_midnight(
                raw,
                {
                    "network": args.network or "preview",
                    "endpoint": args.endpoint or "captured://midnight-finalized-v1",
                    "observed_at": args.observed_at,
                    "raw_response_bytes": args.input.read_bytes(),
                },
            )
        else:
            record = normalize_mithril(
                raw,
                {
                    "network": args.network or "pre-release-preview",
                    "endpoint": args.endpoint or "captured://mithril-certificates-v1",
                    "observed_at": args.observed_at,
                    "raw_response_bytes": args.input.read_bytes(),
                },
            )
    _write_record(args.output, record)
    print(json.dumps(record, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
