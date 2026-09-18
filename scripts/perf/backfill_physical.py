#!/usr/bin/env python3
"""Rebuild the FTL physical performance history from Firebase Test Lab results.

The nightly pipeline only publishes the physical median when the three runs
of a given night all succeeded. Nighlies that were skipped, that failed, or
that ran before the publication job existed leave gaps in the dashboard.

This script replays the exact same computation for any past night whose three
logcats are still present in the FTL results bucket:

    logcat( run1, run2, run3 ) --compute_median.py--> median.json
    median.json --update_history.py--> <data-directory>/<date>.json + index.json

It resolves each run id to its GitHub metadata (creation date, head sha) and
skips nights that cannot be rebuilt with three samples.

Usage (local, authenticated with gcloud + a GitHub token):

    export GH_TOKEN=...
    python3 scripts/perf/backfill_physical.py \
        --bucket gs://twake-195010_test_results \
        --data-directory /path/to/gh-pages/performance/data \
        --repository linagora/twake-on-matrix \
        --since 2026-07-01 --until 2026-09-18

Usage in CI (see .github/workflows/perf-backfill.yaml) is identical; the
Google authentication comes from Workload Identity Federation and GH_TOKEN
from the job token.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from collections import defaultdict
from datetime import date
from pathlib import Path

PERF_DIR_PATTERN = re.compile(r"perf-physical-(\d+)(?:-run(\d+))?$")
RUN_DIRS = (1, 2, 3)
SCRIPT_DIR = Path(__file__).resolve().parent


class BackfillError(RuntimeError):
    """Raised when the backfill cannot proceed safely."""


def _run(command: list[str], *, capture: bool = True) -> str:
    result = subprocess.run(
        command,
        check=False,
        capture_output=capture,
        text=True,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "").strip()
        raise BackfillError(f"{command[0]} failed: {detail[-400:]}")
    return result.stdout if capture else ""


def _gcloud(args: list[str], account: str | None) -> list[str]:
    command = ["gcloud", "storage", *args]
    if account:
        command.append(f"--account={account}")
    return command


def list_run_ids(bucket: str, account: str | None) -> dict[str, set[int]]:
    output = _run(_gcloud(["ls", f"{bucket}/"], account))
    runs: dict[str, set[int]] = defaultdict(set)
    for line in output.splitlines():
        prefix = line.strip().rstrip("/").rsplit("/", 1)[-1]
        match = PERF_DIR_PATTERN.fullmatch(prefix)
        if not match:
            continue
        run_id, run_number = match.group(1), match.group(2)
        runs[run_id].add(int(run_number) if run_number else 1)
    return runs


def _github_json(path: str) -> dict:
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    request = urllib.request.Request(f"https://api.github.com{path}")
    request.add_header("Accept", "application/vnd.github+json")
    if token:
        request.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise BackfillError(
            f"GitHub API {path} returned HTTP {error.code}"
        ) from error


def run_metadata(repository: str, run_id: str) -> dict:
    payload = _github_json(f"/repos/{repository}/actions/runs/{run_id}")
    return {
        "id": run_id,
        "day": payload["created_at"][:10],
        "created": payload["created_at"],
        "sha": payload["head_sha"],
        "event": payload.get("event", ""),
    }


def select_nights(
    runs: dict[str, set[int]],
    repository: str,
    since: date | None,
    until: date | None,
) -> dict[str, dict]:
    """Return one run per night, preferring scheduled runs over manual ones."""
    complete = {
        run_id: numbers
        for run_id, numbers in runs.items()
        if set(RUN_DIRS) <= numbers
    }
    by_day: dict[str, list[dict]] = defaultdict(list)
    for run_id in complete:
        metadata = run_metadata(repository, run_id)
        day = date.fromisoformat(metadata["day"])
        if since and day < since:
            continue
        if until and day > until:
            continue
        by_day[metadata["day"]].append(metadata)
    selected: dict[str, dict] = {}
    for day, candidates in by_day.items():
        scheduled = [item for item in candidates if item["event"] == "schedule"]
        pool = scheduled or candidates
        selected[day] = max(pool, key=lambda item: int(item["id"]))
    return selected


def existing_days(data_directory: Path) -> set[str]:
    index_path = data_directory / "index.json"
    if not index_path.exists():
        return set()
    index = json.loads(index_path.read_text(encoding="utf-8"))
    return {entry["date"] for entry in index.get("entries", [])}


def download_logcats(
    bucket: str,
    run_id: str,
    work_directory: Path,
    account: str | None,
) -> list[Path]:
    logcats = []
    for number in RUN_DIRS:
        source = (
            f"{bucket}/perf-physical-{run_id}-run{number}"
            "/oriole-33-en-portrait/logcat"
        )
        destination = work_directory / f"run{number}.log"
        if not destination.exists() or destination.stat().st_size == 0:
            _run(
                _gcloud(
                    ["cp", source, str(destination)],
                    account,
                )
            )
        logcats.append(destination)
    return logcats


def compute_median(logcats: list[Path], output: Path) -> None:
    _run(
        [
            sys.executable,
            str(SCRIPT_DIR / "compute_median.py"),
            "--expected-samples",
            "3",
            "--requirements",
            str(SCRIPT_DIR / "android_requirements.json"),
            *(str(logcat) for logcat in logcats),
            str(output),
        ]
    )


def update_history(
    median: Path,
    data_directory: Path,
    night: dict,
    repository: str,
    flutter_version: str,
) -> None:
    _run(
        [
            sys.executable,
            str(SCRIPT_DIR / "update_history.py"),
            "--memory",
            str(median),
            "--physical",
            str(median),
            "--benchmark-source",
            "physical",
            "--physical-runs",
            "3",
            "--data-directory",
            str(data_directory),
            "--date",
            night["day"],
            "--generated-at",
            night["created"],
            "--repository",
            repository,
            "--sha",
            night["sha"],
            "--run-id",
            night["id"],
            "--flutter-version",
            flutter_version,
        ]
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bucket", required=True)
    parser.add_argument("--data-directory", type=Path, required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--flutter-version", default="3.38.9")
    parser.add_argument("--gcloud-account")
    parser.add_argument("--since", type=date.fromisoformat)
    parser.add_argument("--until", type=date.fromisoformat)
    parser.add_argument("--run-id", action="append", default=[])
    parser.add_argument("--skip-existing", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--work-directory",
        type=Path,
        help="Reuse an existing directory for downloaded logcats.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    args.data_directory.mkdir(parents=True, exist_ok=True)

    if args.run_id:
        runs = {run_id: set(RUN_DIRS) for run_id in args.run_id}
    else:
        runs = list_run_ids(args.bucket, args.gcloud_account)

    nights = select_nights(runs, args.repository, args.since, args.until)
    skip = existing_days(args.data_directory) if args.skip_existing else set()

    work_root = args.work_directory or Path(tempfile.mkdtemp(prefix="perf-backfill-"))
    work_root.mkdir(parents=True, exist_ok=True)

    ok: list[str] = []
    skipped: list[str] = []
    failed: list[tuple[str, str]] = []

    for day in sorted(nights):
        night = nights[day]
        if day in skip:
            skipped.append(day)
            print(f"SKIP {day} {night['id']} (already published)")
            continue
        if args.dry_run:
            print(f"WOULD {day} {night['id']} sha={night['sha'][:8]} ({night['event']})")
            continue
        night_directory = work_root / night["id"]
        night_directory.mkdir(parents=True, exist_ok=True)
        try:
            logcats = download_logcats(
                args.bucket, night["id"], night_directory, args.gcloud_account
            )
            median = night_directory / "median.json"
            compute_median(logcats, median)
            update_history(
                median,
                args.data_directory,
                night,
                args.repository,
                args.flutter_version,
            )
            ok.append(day)
            print(f"OK   {day} {night['id']} ({night['event']})")
        except BackfillError as error:
            failed.append((day, str(error)))
            print(f"FAIL {day} {night['id']}: {error}")

    print(
        f"\nbackfilled {len(ok)} night(s), "
        f"{len(skipped)} skipped, {len(failed)} failed"
    )
    for day, error in failed:
        print(f"  FAIL {day}: {error}")

    if not args.work_directory and not args.dry_run:
        shutil.rmtree(work_root, ignore_errors=True)


if __name__ == "__main__":
    main()
