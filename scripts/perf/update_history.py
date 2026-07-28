#!/usr/bin/env python3
"""Build one versioned daily FTL performance record and update its index."""

from __future__ import annotations

import argparse
import json
import math
import os
import statistics
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Any


SCHEMA_VERSION = 1
DEFAULT_DASHBOARD_URL = "https://linagora.github.io/twake-on-matrix/performance/"
HEADLINE_METRICS = (
    "rss_bytes",
    "build_p95_us",
    "raster_p95_us",
    "jank_rate",
    "transition_ms",
)


class HistoryError(ValueError):
    """Raised when inputs or the persisted history are unsafe to publish."""


@dataclass(frozen=True)
class RecordMetadata:
    """Metadata shared by every measurement in a daily record."""

    day: str
    generated_at: str
    repository: str
    sha: str
    run_id: str
    flutter_version: str


def _load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise HistoryError(f"Cannot read valid JSON from {path}: {error}") from error


def _is_finite_number(value: Any) -> bool:
    if isinstance(value, bool):
        return False
    if not isinstance(value, (int, float)):
        return False
    return math.isfinite(value)


def _checkpoint_location(source: str, position: int) -> str:
    return f"{source}[{position}]"


def _validate_checkpoint_identity(checkpoint: dict, location: str) -> None:
    for key in ("scenario", "label"):
        if not isinstance(checkpoint.get(key), str) or not checkpoint[key]:
            raise HistoryError(f"{location}.{key} must be a non-empty string")


def _validate_sample_count(checkpoint: dict, location: str, minimum_samples: int) -> None:
    sample_count = checkpoint.get("sample_count")
    if not _is_finite_number(sample_count):
        raise HistoryError(f"{location}.sample_count must be a finite number")
    if sample_count < minimum_samples:
        raise HistoryError(
            f"{location} has {sample_count} sample(s); at least {minimum_samples} required"
        )


def _validate_metrics(checkpoint: dict, location: str) -> None:
    for key, metric in checkpoint.items():
        if key in {"scenario", "label"}:
            continue
        if not _is_finite_number(metric):
            raise HistoryError(f"{location}.{key} must be a finite number")


def _validate_checkpoint(
    checkpoint: Any,
    *,
    location: str,
    minimum_samples: int,
) -> dict:
    if not isinstance(checkpoint, dict):
        raise HistoryError(f"{location} must be an object")
    _validate_checkpoint_identity(checkpoint, location)
    _validate_sample_count(checkpoint, location, minimum_samples)
    _validate_metrics(checkpoint, location)
    return checkpoint


def _validate_checkpoints(value: Any, source: str, minimum_samples: int) -> list[dict]:
    if not isinstance(value, list) or not value:
        raise HistoryError(f"{source} must contain a non-empty checkpoint list")

    return [
        _validate_checkpoint(
            checkpoint,
            location=_checkpoint_location(source, position),
            minimum_samples=minimum_samples,
        )
        for position, checkpoint in enumerate(value)
    ]


def _validate_day(day: str) -> None:
    try:
        date.fromisoformat(day)
    except ValueError as error:
        raise HistoryError(f"Invalid UTC date: {day}") from error


def _validate_timestamp(generated_at: str) -> None:
    try:
        datetime.fromisoformat(generated_at.replace("Z", "+00:00"))
    except ValueError as error:
        raise HistoryError(
            f"Invalid generated_at timestamp: {generated_at}"
        ) from error


def _validate_repository(repository: str) -> None:
    if not repository or "/" not in repository:
        raise HistoryError("repository must use the owner/name form")


def _validate_required_metadata(metadata: RecordMetadata) -> None:
    required = (metadata.sha, metadata.run_id, metadata.flutter_version)
    if not all(required):
        raise HistoryError("sha, run_id and flutter_version are required")


def _validate_metadata(metadata: RecordMetadata) -> None:
    _validate_day(metadata.day)
    _validate_timestamp(metadata.generated_at)
    _validate_repository(metadata.repository)
    _validate_required_metadata(metadata)


def build_daily_record(
    memory: Any,
    physical: Any,
    metadata: RecordMetadata,
) -> dict:
    _validate_metadata(metadata)
    memory_checkpoints = _validate_checkpoints(memory, "memory", minimum_samples=3)
    physical_checkpoints = _validate_checkpoints(physical, "physical", minimum_samples=1)
    repository_url = f"https://github.com/{metadata.repository}"

    return {
        "schema_version": SCHEMA_VERSION,
        "date": metadata.day,
        "generated_at": metadata.generated_at,
        "commit": {
            "sha": metadata.sha,
            "url": f"{repository_url}/commit/{metadata.sha}",
        },
        "run": {
            "id": str(metadata.run_id),
            "url": f"{repository_url}/actions/runs/{metadata.run_id}",
        },
        "environment": {
            "flutter_version": metadata.flutter_version,
            "build_mode": "profile",
            "virtual_device": {"model": "MediumPhone.arm", "android": 34, "runs": 3},
            "physical_device": {"model": "oriole", "android": 33, "runs": 1},
        },
        "memory": {"aggregation": "median", "checkpoints": memory_checkpoints},
        "physical": {"aggregation": "single_run", "checkpoints": physical_checkpoints},
    }


def _empty_index() -> dict:
    return {"schema_version": SCHEMA_VERSION, "updated_at": None, "entries": []}


def _validate_index_entry(entry: Any, path: Path) -> None:
    required_keys = {"date", "file", "sha", "run_id"}
    if not isinstance(entry, dict) or not required_keys <= entry.keys():
        raise HistoryError(f"Malformed history index entry in {path}")
    try:
        date.fromisoformat(entry["date"])
    except (TypeError, ValueError) as error:
        raise HistoryError(f"Malformed history index date in {path}") from error
    if entry["file"] != f"{entry['date']}.json":
        raise HistoryError(f"Unsafe history index file in {path}")


def _validate_index(index: Any, path: Path) -> dict:
    if not isinstance(index, dict):
        raise HistoryError(f"Unsupported history index schema in {path}")
    if index.get("schema_version") != SCHEMA_VERSION:
        raise HistoryError(f"Unsupported history index schema in {path}")
    if not isinstance(index.get("entries"), list):
        raise HistoryError(f"History index entries must be a list in {path}")
    for entry in index["entries"]:
        _validate_index_entry(entry, path)
    return index


def _load_index(path: Path) -> dict:
    if not path.exists():
        return _empty_index()
    return _validate_index(_load_json(path), path)


def _validate_persisted_record(path: Path, expected_day: str) -> None:
    persisted = _load_json(path)
    if not isinstance(persisted, dict):
        raise HistoryError(f"Malformed daily history record in {path}")
    expected_values = (SCHEMA_VERSION, expected_day)
    actual_values = (persisted.get("schema_version"), persisted.get("date"))
    if actual_values != expected_values:
        raise HistoryError(f"Malformed daily history record in {path}")


def update_history(data_directory: Path, record: dict) -> dict:
    data_directory.mkdir(parents=True, exist_ok=True)
    index_path = data_directory / "index.json"
    index = _load_index(index_path)
    for entry in index["entries"]:
        persisted_path = data_directory / entry["file"]
        _validate_persisted_record(persisted_path, entry["date"])
    day = record["date"]
    file_name = f"{day}.json"

    daily_path = data_directory / file_name
    daily_path.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")

    entry = {
        "date": day,
        "file": file_name,
        "sha": record["commit"]["sha"],
        "run_id": record["run"]["id"],
    }
    entries_by_date = {item["date"]: item for item in index["entries"]}
    entries_by_date[day] = entry
    index["entries"] = [entries_by_date[key] for key in sorted(entries_by_date)]
    index["updated_at"] = record["generated_at"]
    index_path.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    return index


def _checkpoint_map(record: dict, family: str) -> dict[tuple[str, str], dict]:
    return {
        (checkpoint["scenario"], checkpoint["label"]): checkpoint
        for checkpoint in record[family]["checkpoints"]
    }


def _regression_finding(
    selection: dict,
    current_value: Any,
    baseline_values: list[Any],
) -> dict | None:
    if current_value is None:
        return None
    if any(value is None for value in baseline_values):
        return None
    baseline = statistics.median(baseline_values)
    if baseline <= 0:
        return None
    delta = (current_value - baseline) / baseline
    if delta < 0.10:
        return None
    return {
        "severity": "critical" if delta >= 0.20 else "warning",
        **selection,
        "delta": delta,
    }


def _checkpoint_regressions(
    family: str,
    checkpoint_key: tuple[str, str],
    checkpoint: dict,
    prior_maps: list[dict],
) -> list[dict]:
    findings = []
    for metric in HEADLINE_METRICS:
        baseline_values = [
            mapping.get(checkpoint_key, {}).get(metric) for mapping in prior_maps
        ]
        selection = {
            "family": family,
            "scenario": checkpoint_key[0],
            "label": checkpoint_key[1],
            "metric": metric,
        }
        finding = _regression_finding(
            selection,
            checkpoint.get(metric),
            baseline_values,
        )
        if finding:
            findings.append(finding)
    return findings


def _family_regressions(
    family: str,
    current: dict,
    prior_records: list[dict],
) -> list[dict]:
    current_map = _checkpoint_map(current, family)
    prior_maps = [_checkpoint_map(record, family) for record in prior_records]
    findings = []
    for checkpoint_key, checkpoint in current_map.items():
        findings.extend(
            _checkpoint_regressions(
                family,
                checkpoint_key,
                checkpoint,
                prior_maps,
            )
        )
    return findings


def _regressions(data_directory: Path, index: dict, current: dict) -> list[dict]:
    prior_entries = [item for item in index["entries"] if item["date"] < current["date"]]
    prior_records = [_load_json(data_directory / item["file"]) for item in prior_entries]
    build_mode = current.get("environment", {}).get("build_mode")
    compatible_records = [
        record
        for record in prior_records
        if record.get("environment", {}).get("build_mode") == build_mode
    ][-7:]
    if len(compatible_records) < 7:
        return []
    findings = [
        finding
        for family in ("memory", "physical")
        for finding in _family_regressions(family, current, compatible_records)
    ]
    return sorted(findings, key=lambda item: item["delta"], reverse=True)


def write_summary(path: Path, data_directory: Path, index: dict, record: dict) -> None:
    findings = _regressions(data_directory, index, record)
    dashboard_url = os.environ.get("PERF_DASHBOARD_URL", DEFAULT_DASHBOARD_URL)
    lines = [
        "## FTL performance history",
        "",
        f"Published **{record['date']}** from [`{record['commit']['sha'][:9]}`]({record['commit']['url']}).",
        "",
        f"- [Open the performance dashboard]({dashboard_url})",
        f"- [Open this workflow run]({record['run']['url']})",
        f"- [Download the consolidated JSON artifact]({record['run']['url']}#artifacts)",
        f"- Stored history points: **{len(index['entries'])}**",
    ]
    if not findings:
        lines.extend(["", "No visual regression marker is available until seven prior points exist, or no +10% regression was detected."])
    else:
        lines.extend(["", "### Largest visual regression markers", "", "| Level | Source | Checkpoint | Metric | Delta vs 7-day median |", "| --- | --- | --- | --- | ---: |"])
        for finding in findings[:5]:
            lines.append(
                f"| {finding['severity']} | {finding['family']} | "
                f"`{finding['scenario']}/{finding['label']}` | `{finding['metric']}` | "
                f"+{finding['delta']:.1%} |"
            )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--memory", type=Path, required=True)
    parser.add_argument("--physical", type=Path, required=True)
    parser.add_argument("--data-directory", type=Path, required=True)
    parser.add_argument("--date", required=True)
    parser.add_argument("--generated-at", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--flutter-version", required=True)
    parser.add_argument("--summary-file", type=Path)
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    metadata = RecordMetadata(
        day=args.date,
        generated_at=args.generated_at,
        repository=args.repository,
        sha=args.sha,
        run_id=args.run_id,
        flutter_version=args.flutter_version,
    )
    record = build_daily_record(
        _load_json(args.memory),
        _load_json(args.physical),
        metadata,
    )
    index = update_history(args.data_directory, record)
    if args.summary_file:
        write_summary(args.summary_file, args.data_directory, index, record)
    print(f"Published {record['date']} with {len(index['entries'])} history point(s).")


if __name__ == "__main__":
    main()
