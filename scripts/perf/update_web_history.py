#!/usr/bin/env python3
"""Build and persist one versioned daily Patrol Web performance record."""

from __future__ import annotations

import argparse
import json
import math
import re
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Any


SCHEMA_VERSION = 1
REPETITIONS = 3
ENV_PREFIX = "PERF_WEB_ENV | "
REQUIRED_METRICS = (
    "frame_count",
    "fps",
    "frame_interval_p95_ms",
    "frame_interval_p99_ms",
    "slow_frame_rate",
    "long_task_total_ms",
)


class WebHistoryError(ValueError):
    """Raised when a Web result is incomplete or unsafe to publish."""


@dataclass(frozen=True)
class WebMetadata:
    day: str
    generated_at: str
    repository: str
    sha: str
    run_id: str
    flutter_version: str
    patrol_version: str
    runner_image: str


def _load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise WebHistoryError(f"Cannot read valid JSON from {path}: {error}") from error


def _finite_number(value: Any) -> bool:
    return (
        not isinstance(value, bool)
        and isinstance(value, (int, float))
        and math.isfinite(value)
    )


def parse_environment(log_path: Path) -> dict:
    environments = []
    for line in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        marker = line.find(ENV_PREFIX)
        if marker < 0:
            continue
        try:
            environments.append(json.loads(line[marker + len(ENV_PREFIX) :]))
        except json.JSONDecodeError as error:
            raise WebHistoryError("Malformed PERF_WEB_ENV payload") from error
    if not environments:
        raise WebHistoryError("Missing PERF_WEB_ENV payload")
    first = environments[0]
    if any(environment != first for environment in environments[1:]):
        raise WebHistoryError("Browser environment changed during the benchmark")
    if not isinstance(first, dict):
        raise WebHistoryError("PERF_WEB_ENV must be an object")
    return first


def _browser_version(user_agent: str) -> str:
    match = re.search(r"(?:HeadlessChrome|Chrome)/([0-9.]+)", user_agent)
    return match.group(1) if match else "unknown"


def _validate_metadata(metadata: WebMetadata) -> None:
    try:
        date.fromisoformat(metadata.day)
        datetime.fromisoformat(metadata.generated_at.replace("Z", "+00:00"))
    except ValueError as error:
        raise WebHistoryError("Invalid date or generated_at timestamp") from error
    required = (
        metadata.sha,
        metadata.run_id,
        metadata.flutter_version,
        metadata.patrol_version,
        metadata.runner_image,
    )
    if "/" not in metadata.repository or not all(required):
        raise WebHistoryError("Incomplete Web run metadata")


def _validate_values(checkpoint: dict, metric: str, location: str) -> None:
    values = checkpoint.get(f"{metric}_values")
    if (
        not isinstance(values, list)
        or len(values) != REPETITIONS
        or not all(_finite_number(value) for value in values)
    ):
        raise WebHistoryError(
            f"{location}.{metric}_values must contain {REPETITIONS} finite values"
        )


def validate_checkpoints(value: Any) -> list[dict]:
    if not isinstance(value, list) or not value:
        raise WebHistoryError("web must contain a non-empty checkpoint list")
    validated = []
    for position, checkpoint in enumerate(value):
        location = f"web[{position}]"
        if not isinstance(checkpoint, dict):
            raise WebHistoryError(f"{location} must be an object")
        if checkpoint.get("sample_count") != REPETITIONS:
            raise WebHistoryError(f"{location} must aggregate exactly 3 repetitions")
        for identity in ("scenario", "label"):
            if not isinstance(checkpoint.get(identity), str) or not checkpoint[identity]:
                raise WebHistoryError(f"{location}.{identity} must be non-empty")
        for key, metric in checkpoint.items():
            if key in {"scenario", "label"} or key.endswith("_values"):
                continue
            if not _finite_number(metric):
                raise WebHistoryError(f"{location}.{key} must be finite")
        for metric in REQUIRED_METRICS:
            if not _finite_number(checkpoint.get(metric)):
                raise WebHistoryError(f"{location}.{metric} is required")
            _validate_values(checkpoint, metric, location)
        for key in checkpoint:
            if key.endswith("_values"):
                _validate_values(checkpoint, key.removesuffix("_values"), location)
        validated.append(checkpoint)
    return validated


def build_daily_record(
    checkpoints: Any,
    environment: dict,
    metadata: WebMetadata,
) -> dict:
    _validate_metadata(metadata)
    validated = validate_checkpoints(checkpoints)
    user_agent = environment.get("user_agent")
    viewport = environment.get("viewport")
    if not isinstance(user_agent, str) or not isinstance(viewport, dict):
        raise WebHistoryError("Browser user agent and viewport are required")
    for key in ("width", "height", "device_pixel_ratio"):
        if not _finite_number(viewport.get(key)):
            raise WebHistoryError(f"environment.viewport.{key} must be finite")
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
            "platform": "web",
            "build_mode": "profile",
            "flutter_version": metadata.flutter_version,
            "patrol_version": metadata.patrol_version,
            "browser": {
                "name": "chromium",
                "version": _browser_version(user_agent),
                "user_agent": user_agent,
            },
            "runner": {"image": metadata.runner_image},
            "viewport": viewport,
            "renderer": environment.get("renderer", "unknown"),
        },
        "web": {
            "aggregation": "median",
            "repetitions": REPETITIONS,
            "checkpoints": validated,
        },
    }


def _load_index(path: Path) -> dict:
    if not path.exists():
        return {"schema_version": SCHEMA_VERSION, "updated_at": None, "entries": []}
    index = _load_json(path)
    if (
        not isinstance(index, dict)
        or index.get("schema_version") != SCHEMA_VERSION
        or not isinstance(index.get("entries"), list)
    ):
        raise WebHistoryError(f"Unsupported history index schema in {path}")
    for entry in index["entries"]:
        if (
            not isinstance(entry, dict)
            or entry.get("file") != f"{entry.get('date')}.json"
        ):
            raise WebHistoryError(f"Malformed history index entry in {path}")
        try:
            date.fromisoformat(entry["date"])
        except (KeyError, TypeError, ValueError) as error:
            raise WebHistoryError(f"Malformed history index date in {path}") from error
    return index


def update_history(data_directory: Path, record: dict) -> dict:
    data_directory.mkdir(parents=True, exist_ok=True)
    index_path = data_directory / "index.json"
    index = _load_index(index_path)
    for entry in index["entries"]:
        persisted = _load_json(data_directory / entry["file"])
        if (
            not isinstance(persisted, dict)
            or persisted.get("schema_version") != SCHEMA_VERSION
            or persisted.get("date") != entry["date"]
        ):
            raise WebHistoryError(f"Malformed persisted record {entry['file']}")
    day = record["date"]
    file_name = f"{day}.json"
    (data_directory / file_name).write_text(
        json.dumps(record, indent=2) + "\n",
        encoding="utf-8",
    )
    entries = {entry["date"]: entry for entry in index["entries"]}
    entries[day] = {
        "date": day,
        "file": file_name,
        "sha": record["commit"]["sha"],
        "run_id": record["run"]["id"],
    }
    index["entries"] = [entries[key] for key in sorted(entries)]
    index["updated_at"] = record["generated_at"]
    index_path.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")
    return index


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--web", type=Path, required=True)
    parser.add_argument("--log", type=Path, required=True)
    parser.add_argument("--data-directory", type=Path, required=True)
    parser.add_argument("--date", required=True)
    parser.add_argument("--generated-at", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--flutter-version", required=True)
    parser.add_argument("--patrol-version", required=True)
    parser.add_argument("--runner-image", required=True)
    return parser.parse_args()


def main() -> None:
    arguments = _arguments()
    record = build_daily_record(
        _load_json(arguments.web),
        parse_environment(arguments.log),
        WebMetadata(
            day=arguments.date,
            generated_at=arguments.generated_at,
            repository=arguments.repository,
            sha=arguments.sha,
            run_id=arguments.run_id,
            flutter_version=arguments.flutter_version,
            patrol_version=arguments.patrol_version,
            runner_image=arguments.runner_image,
        ),
    )
    update_history(arguments.data_directory, record)
    print(
        f"Published Web performance point {record['date']} "
        f"with {len(record['web']['checkpoints'])} checkpoint(s)."
    )


if __name__ == "__main__":
    main()
