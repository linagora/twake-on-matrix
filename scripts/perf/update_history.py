#!/usr/bin/env python3
"""Build one versioned daily FTL performance record and update its index."""

from __future__ import annotations

import argparse
import json
import math
import statistics
from datetime import date, datetime
from pathlib import Path
from typing import Any


SCHEMA_VERSION = 1
HEADLINE_METRICS = (
    "rss_bytes",
    "build_p95_us",
    "raster_p95_us",
    "jank_rate",
    "transition_ms",
)


class HistoryError(ValueError):
    """Raised when inputs or the persisted history are unsafe to publish."""


def _load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise HistoryError(f"Cannot read valid JSON from {path}: {error}") from error


def _validate_checkpoints(value: Any, source: str, minimum_samples: int) -> list[dict]:
    if not isinstance(value, list) or not value:
        raise HistoryError(f"{source} must contain a non-empty checkpoint list")

    validated: list[dict] = []
    for position, checkpoint in enumerate(value):
        if not isinstance(checkpoint, dict):
            raise HistoryError(f"{source}[{position}] must be an object")
        for key in ("scenario", "label", "sample_count"):
            if key not in checkpoint:
                raise HistoryError(f"{source}[{position}] is missing {key}")
        if not isinstance(checkpoint["scenario"], str) or not checkpoint["scenario"]:
            raise HistoryError(f"{source}[{position}].scenario must be a non-empty string")
        if not isinstance(checkpoint["label"], str) or not checkpoint["label"]:
            raise HistoryError(f"{source}[{position}].label must be a non-empty string")
        sample_count = checkpoint["sample_count"]
        if (
            isinstance(sample_count, bool)
            or not isinstance(sample_count, (int, float))
            or not math.isfinite(sample_count)
        ):
            raise HistoryError(f"{source}[{position}].sample_count must be a finite number")
        if sample_count < minimum_samples:
            raise HistoryError(
                f"{source}[{position}] has {sample_count} sample(s); "
                f"at least {minimum_samples} required"
            )
        for key, metric in checkpoint.items():
            if key in {"scenario", "label"}:
                continue
            if (
                isinstance(metric, bool)
                or not isinstance(metric, (int, float))
                or not math.isfinite(metric)
            ):
                raise HistoryError(f"{source}[{position}].{key} must be a finite number")
        validated.append(checkpoint)
    return validated


def build_daily_record(
    memory: Any,
    physical: Any,
    *,
    day: str,
    generated_at: str,
    repository: str,
    sha: str,
    run_id: str,
    flutter_version: str,
) -> dict:
    try:
        date.fromisoformat(day)
    except ValueError as error:
        raise HistoryError(f"Invalid UTC date: {day}") from error
    if not repository or "/" not in repository:
        raise HistoryError("repository must use the owner/name form")
    try:
        datetime.fromisoformat(generated_at.replace("Z", "+00:00"))
    except ValueError as error:
        raise HistoryError(f"Invalid generated_at timestamp: {generated_at}") from error
    if not sha or not run_id or not flutter_version:
        raise HistoryError("sha, run_id and flutter_version are required")

    memory_checkpoints = _validate_checkpoints(memory, "memory", minimum_samples=3)
    physical_checkpoints = _validate_checkpoints(physical, "physical", minimum_samples=1)
    repository_url = f"https://github.com/{repository}"

    return {
        "schema_version": SCHEMA_VERSION,
        "date": day,
        "generated_at": generated_at,
        "commit": {
            "sha": sha,
            "url": f"{repository_url}/commit/{sha}",
        },
        "run": {
            "id": str(run_id),
            "url": f"{repository_url}/actions/runs/{run_id}",
        },
        "environment": {
            "flutter_version": flutter_version,
            "virtual_device": {"model": "MediumPhone.arm", "android": 34, "runs": 3},
            "physical_device": {"model": "oriole", "android": 33, "runs": 1},
        },
        "memory": {"aggregation": "median", "checkpoints": memory_checkpoints},
        "physical": {"aggregation": "single_run", "checkpoints": physical_checkpoints},
    }


def _empty_index() -> dict:
    return {"schema_version": SCHEMA_VERSION, "updated_at": None, "entries": []}


def _load_index(path: Path) -> dict:
    if not path.exists():
        return _empty_index()
    index = _load_json(path)
    if not isinstance(index, dict) or index.get("schema_version") != SCHEMA_VERSION:
        raise HistoryError(f"Unsupported history index schema in {path}")
    if not isinstance(index.get("entries"), list):
        raise HistoryError(f"History index entries must be a list in {path}")
    for entry in index["entries"]:
        if not isinstance(entry, dict) or not {"date", "file", "sha", "run_id"} <= entry.keys():
            raise HistoryError(f"Malformed history index entry in {path}")
        try:
            date.fromisoformat(entry["date"])
        except (TypeError, ValueError) as error:
            raise HistoryError(f"Malformed history index date in {path}") from error
        if entry["file"] != f"{entry['date']}.json":
            raise HistoryError(f"Unsafe history index file in {path}")
    return index


def update_history(data_directory: Path, record: dict) -> dict:
    data_directory.mkdir(parents=True, exist_ok=True)
    index_path = data_directory / "index.json"
    index = _load_index(index_path)
    for entry in index["entries"]:
        persisted_path = data_directory / entry["file"]
        persisted = _load_json(persisted_path)
        if (
            not isinstance(persisted, dict)
            or persisted.get("schema_version") != SCHEMA_VERSION
            or persisted.get("date") != entry["date"]
        ):
            raise HistoryError(f"Malformed daily history record in {persisted_path}")
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


def _regressions(data_directory: Path, index: dict, current: dict) -> list[dict]:
    prior_entries = [item for item in index["entries"] if item["date"] < current["date"]][-7:]
    if len(prior_entries) < 7:
        return []
    prior_records = [_load_json(data_directory / item["file"]) for item in prior_entries]
    findings: list[dict] = []

    for family in ("memory", "physical"):
        current_map = _checkpoint_map(current, family)
        prior_maps = [_checkpoint_map(record, family) for record in prior_records]
        for checkpoint_key, checkpoint in current_map.items():
            for metric in HEADLINE_METRICS:
                current_value = checkpoint.get(metric)
                baseline_values = [mapping.get(checkpoint_key, {}).get(metric) for mapping in prior_maps]
                if current_value is None or any(value is None for value in baseline_values):
                    continue
                baseline = statistics.median(baseline_values)
                if baseline <= 0:
                    continue
                delta = (current_value - baseline) / baseline
                if delta >= 0.10:
                    findings.append(
                        {
                            "severity": "critical" if delta >= 0.20 else "warning",
                            "family": family,
                            "scenario": checkpoint_key[0],
                            "label": checkpoint_key[1],
                            "metric": metric,
                            "delta": delta,
                        }
                    )
    return sorted(findings, key=lambda item: item["delta"], reverse=True)


def write_summary(path: Path, data_directory: Path, index: dict, record: dict) -> None:
    findings = _regressions(data_directory, index, record)
    dashboard_url = "https://linagora.github.io/twake-on-matrix/performance/"
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
    record = build_daily_record(
        _load_json(args.memory),
        _load_json(args.physical),
        day=args.date,
        generated_at=args.generated_at,
        repository=args.repository,
        sha=args.sha,
        run_id=args.run_id,
        flutter_version=args.flutter_version,
    )
    index = update_history(args.data_directory, record)
    if args.summary_file:
        write_summary(args.summary_file, args.data_directory, index, record)
    print(f"Published {record['date']} with {len(index['entries'])} history point(s).")


if __name__ == "__main__":
    main()
