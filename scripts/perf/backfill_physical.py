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
from dataclasses import dataclass
from datetime import date
from pathlib import Path

PERF_DIR_PATTERN = re.compile(r"perf-physical-(\d+)(?:-run(\d+))?$")
RUN_DIRS = (1, 2, 3)
SCRIPT_DIR = Path(__file__).resolve().parent

SKIP = "skip"
DRY = "dry"
OK = "ok"
FAIL = "fail"


class BackfillError(RuntimeError):
    """Raised when the backfill cannot proceed safely."""


@dataclass(frozen=True)
class BackfillConfig:
    """Immutable settings shared by every backfill step."""

    bucket: str
    data_directory: Path
    repository: str
    flutter_version: str
    account: str | None
    dry_run: bool


def _run(command: list[str], *, capture: bool = True) -> str:
    """Run a command, raising BackfillError on a non-zero exit code."""
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
    """Build a `gcloud storage` command, appending the account when set."""
    command = ["gcloud", "storage", *args]
    if account:
        command.append(f"--account={account}")
    return command


def list_run_samples(bucket: str, account: str | None) -> dict[str, dict[int, str]]:
    """List the FTL result directories as {run_id: {sample_number: name}}.

    The directory name is preserved for every sample so downloads use the exact
    name that exists in the bucket (both `perf-physical-<id>` and
    `perf-physical-<id>-run<n>` are accepted, the former being sample one).
    """
    output = _run(_gcloud(["ls", f"{bucket}/"], account))
    runs: dict[str, dict[int, str]] = defaultdict(dict)
    for line in output.splitlines():
        prefix = line.strip().rstrip("/").rsplit("/", 1)[-1]
        match = PERF_DIR_PATTERN.fullmatch(prefix)
        if not match:
            continue
        run_id, run_number = match.group(1), match.group(2)
        runs[run_id][int(run_number) if run_number else 1] = prefix
    return runs


def _github_json(path: str) -> dict:
    """Fetch and decode a JSON document from the GitHub REST API."""
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
    """Resolve the date, sha and event of a GitHub Actions run."""
    payload = _github_json(f"/repos/{repository}/actions/runs/{run_id}")
    return {
        "id": run_id,
        "day": payload["created_at"][:10],
        "created": payload["created_at"],
        "sha": payload["head_sha"],
        "event": payload.get("event", ""),
    }


def in_range(day: date, since: date | None, until: date | None) -> bool:
    """Return True when the day falls inside the requested inclusive window."""
    return (since is None or day >= since) and (until is None or day <= until)


def pick_night(candidates: list[dict]) -> dict:
    """Return one run per night, preferring scheduled runs over manual ones."""
    scheduled = [item for item in candidates if item["event"] == "schedule"]
    return max(scheduled or candidates, key=lambda item: int(item["id"]))


def resolve_metadata(repository: str, run_id: str) -> tuple[dict | None, str]:
    """Resolve a run's metadata, capturing failures instead of raising."""
    try:
        return run_metadata(repository, run_id), ""
    except BackfillError as error:
        return None, f"run {run_id}: {error}"


def select_nights(
    runs: dict[str, dict[int, str]],
    repository: str,
    since: date | None,
    until: date | None,
) -> tuple[dict[str, dict], list[tuple[str, str]]]:
    """Return the night to replay per eligible day, plus discovery failures."""
    complete = {
        run_id: samples
        for run_id, samples in runs.items()
        if set(RUN_DIRS) <= set(samples)
    }
    by_day: dict[str, list[dict]] = defaultdict(list)
    failures: list[tuple[str, str]] = []
    for run_id, samples in complete.items():
        metadata, error = resolve_metadata(repository, run_id)
        if metadata is None:
            failures.append((run_id, error))
            print(f"WARN {error}")
            continue
        if in_range(date.fromisoformat(metadata["day"]), since, until):
            metadata["samples"] = samples
            by_day[metadata["day"]].append(metadata)
    nights = {day: pick_night(c) for day, c in by_day.items()}
    return nights, failures


def existing_days(data_directory: Path) -> set[str]:
    """Return the dates already present in the published index.json."""
    index_path = data_directory / "index.json"
    if not index_path.exists():
        return set()
    index = json.loads(index_path.read_text(encoding="utf-8"))
    return {entry["date"] for entry in index.get("entries", [])}


def download_logcats(
    config: BackfillConfig,
    night: dict,
    work_directory: Path,
) -> list[Path]:
    """Download the three logcats of a night, reusing local copies."""
    logcats = []
    for number in RUN_DIRS:
        directory = night["samples"][number]
        source = f"{config.bucket}/{directory}/oriole-33-en-portrait/logcat"
        destination = work_directory / f"run{number}.log"
        if not destination.exists() or destination.stat().st_size == 0:
            _run(
                _gcloud(
                    ["cp", source, str(destination)],
                    config.account,
                )
            )
        logcats.append(destination)
    return logcats


def compute_median(logcats: list[Path], output: Path) -> None:
    """Run compute_median.py over the downloaded logcats."""
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


def update_history(median: Path, night: dict, config: BackfillConfig) -> None:
    """Run update_history.py to publish the median for a single night."""
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
            str(config.data_directory),
            "--date",
            night["day"],
            "--generated-at",
            night["created"],
            "--repository",
            config.repository,
            "--sha",
            night["sha"],
            "--run-id",
            night["id"],
            "--flutter-version",
            config.flutter_version,
        ]
    )


def parse_args() -> argparse.Namespace:
    """Parse the command-line arguments."""
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


def resolve_runs(
    args: argparse.Namespace,
    config: BackfillConfig,
) -> dict[str, dict[int, str]]:
    """Discover bucket runs, keeping only the requested ids when provided."""
    runs = list_run_samples(config.bucket, config.account)
    if not args.run_id:
        return runs
    requested = set(args.run_id)
    for run_id in sorted(requested - runs.keys()):
        print(f"WARN run id {run_id} not found in bucket, skipping")
    return {run_id: samples for run_id, samples in runs.items() if run_id in requested}


def resolve_work_root(args: argparse.Namespace) -> Path:
    """Reuse the requested directory or create a throwaway temporary one."""
    work_root = args.work_directory or Path(tempfile.mkdtemp(prefix="perf-backfill-"))
    work_root.mkdir(parents=True, exist_ok=True)
    return work_root


def config_from_args(args: argparse.Namespace) -> BackfillConfig:
    """Build the immutable settings consumed by the backfill steps."""
    return BackfillConfig(
        bucket=args.bucket,
        data_directory=args.data_directory,
        repository=args.repository,
        flutter_version=args.flutter_version,
        account=args.gcloud_account,
        dry_run=args.dry_run,
    )


def rebuild_night(config: BackfillConfig, night: dict, work_root: Path) -> None:
    """Download the logcats and replay median + history for a single night."""
    night_directory = work_root / night["id"]
    night_directory.mkdir(parents=True, exist_ok=True)
    logcats = download_logcats(config, night, night_directory)
    median = night_directory / "median.json"
    compute_median(logcats, median)
    update_history(median, night, config)


def process_day(
    config: BackfillConfig,
    night: dict,
    skip: set[str],
    work_root: Path,
) -> tuple[str, str]:
    """Return the outcome status and a short human-readable detail."""
    if night["day"] in skip:
        return SKIP, "already published"
    if config.dry_run:
        return DRY, f"sha={night['sha'][:8]} ({night['event']})"
    try:
        rebuild_night(config, night, work_root)
    except (BackfillError, OSError) as error:
        return FAIL, str(error)
    return OK, night["event"]


def describe(status: str, night: dict, detail: str) -> str:
    """Format the progress line printed for a finished night."""
    day = night["day"]
    if status == SKIP:
        return f"SKIP {day} {night['id']} ({detail})"
    if status == DRY:
        return f"WOULD {day} {night['id']} {detail}"
    if status == FAIL:
        return f"FAIL {day} {night['id']}: {detail}"
    return f"OK   {day} {night['id']} ({detail})"


def report(
    outcomes: dict[str, list],
    discovery_failures: list[tuple[str, str]],
) -> None:
    """Print the run summary and the details of every failed item."""
    print(
        f"\nbackfilled {len(outcomes[OK])} night(s), "
        f"{len(outcomes[SKIP])} skipped, {len(outcomes[FAIL])} failed, "
        f"{len(discovery_failures)} discovery failure(s)"
    )
    for day, error in outcomes[FAIL]:
        print(f"  FAIL {day}: {error}")
    for _run_id, error in discovery_failures:
        print(f"  FAIL {error}")


def main() -> None:
    """Rebuild every eligible night and exit non-zero if any of them failed."""
    args = parse_args()
    args.data_directory.mkdir(parents=True, exist_ok=True)
    config = config_from_args(args)
    runs = resolve_runs(args, config)
    nights, discovery_failures = select_nights(
        runs, args.repository, args.since, args.until
    )
    skip = existing_days(config.data_directory) if args.skip_existing else set()
    work_root = resolve_work_root(args)

    outcomes: dict[str, list] = defaultdict(list)
    for day in sorted(nights):
        night = nights[day]
        status, detail = process_day(config, night, skip, work_root)
        outcomes[status].append((day, detail))
        print(describe(status, night, detail))

    report(outcomes, discovery_failures)

    if not args.work_directory and not args.dry_run:
        shutil.rmtree(work_root, ignore_errors=True)

    if outcomes[FAIL] or discovery_failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
