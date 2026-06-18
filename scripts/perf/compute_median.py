#!/usr/bin/env python3
"""
Parses PERF_METRIC lines from multiple logcat files (one per FTL run),
groups values by (scenario, label, metric_key), and outputs a JSON file
containing the median value of each metric across all runs.

Usage:
    python3 compute_median.py logcat1.txt logcat2.txt logcat3.txt output.json
"""
import json
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path
from typing import Iterator


_PERF_RE = re.compile(r'PERF_METRIC \| ([^|]+) \| ([^|]+) \| (.+)')
# Keys present on every PERF_METRIC line that carry no measurement value.
_SKIP_KEYS: frozenset[str] = frozenset({'scenario', 'label', 'run', 'seq', 'ts'})


def _parse_kv_pairs(raw: str) -> dict:
    """Parse a ' | '-separated string of 'key=value' pairs into a dict."""
    kv: dict = {}
    for part in raw.split(' | '):
        if '=' in part:
            k, v = part.split('=', 1)
            kv[k.strip()] = v.strip()
    return kv


def parse_logcat(path: str) -> list[dict]:
    """Return a list of metric dicts parsed from PERF_METRIC lines."""
    metrics = []
    for line in Path(path).read_text(errors='replace').splitlines():
        m = _PERF_RE.search(line)
        if not m:
            continue
        metrics.append({
            'scenario': m.group(1).strip(),
            'label': m.group(2).strip(),
            **_parse_kv_pairs(m.group(3)),
        })
    return metrics


def _entry_metrics(entry: dict) -> Iterator[tuple[str, str, str, float]]:
    """Yield (scenario, label, key, float_value) for each numeric metric in an entry.

    Skips keys in _SKIP_KEYS and non-numeric values silently.
    Extracted to keep _aggregate_groups flat and to allow isolated unit testing
    of the filtering and conversion logic.
    """
    scenario = entry['scenario']
    label = entry['label']
    for k, v in entry.items():
        if k in _SKIP_KEYS:
            continue
        try:
            yield scenario, label, k, float(v)
        except ValueError:
            pass


def _aggregate_groups(
    logcat_files: list[str],
) -> tuple[dict[tuple, list[float]], int]:
    """Parse all logcat files and collect numeric values grouped by (scenario, label, key).

    Returns (groups, total_parsed_lines).
    """
    groups: dict[tuple, list[float]] = defaultdict(list)
    total_lines = 0
    for f in logcat_files:
        entries = parse_logcat(f)
        total_lines += len(entries)
        for entry in entries:
            for scenario, label, k, v in _entry_metrics(entry):
                groups[(scenario, label, k)].append(v)
    return groups, total_lines


def _build_checkpoints(
    groups: dict[tuple, list[float]],
) -> tuple[list[dict], dict[tuple, dict[str, int]]]:
    """Compute medians and variance indicators for each (scenario, label) checkpoint.

    Returns (checkpoints_list, cp_key_counts) where cp_key_counts is used to
    detect partial runs (diverging sample counts across metric keys).

    Invariant: each PERF_METRIC line emits *all* metrics for a checkpoint in one
    shot, so all metric keys for a given (scenario, label) should share the same
    len(values) across runs. sample_count takes the min as a safety net for partial
    runs (logcat truncated or timeout mid-flush).
    """
    checkpoints: dict[tuple, dict] = {}
    cp_key_counts: dict[tuple, dict[str, int]] = defaultdict(dict)

    for (scenario, label, key), values in groups.items():
        cp_key = (scenario, label)
        cp_key_counts[cp_key][key] = len(values)
        cp = checkpoints.setdefault(
            cp_key,
            {'scenario': scenario, 'label': label, 'sample_count': len(values)},
        )
        cp['sample_count'] = min(cp['sample_count'], len(values))
        cp[key] = statistics.median(values)
        if len(values) >= 2:
            cp[f'{key}_stddev'] = round(statistics.stdev(values), 2)
            cp[f'{key}_range'] = round(max(values) - min(values), 2)

    return list(checkpoints.values()), cp_key_counts


def _emit_warnings(
    output: list[dict],
    cp_key_counts: dict[tuple, dict[str, int]],
) -> None:
    """Print warnings to stderr for partial runs and low sample counts."""
    # Warn when metric counts diverge within a checkpoint — signals a partial run.
    for cp_key, key_counts in cp_key_counts.items():
        if len(set(key_counts.values())) > 1:
            scenario, label = cp_key
            print(
                f"WARNING: partial run detected — metric sample counts diverge for"
                f" {scenario}/{label}: { {k: v for k, v in key_counts.items()} }",
                file=sys.stderr,
            )

    # Warn when fewer than 3 samples: median is a single value, not a real median.
    low_sample_cps = [
        f"{cp['scenario']}/{cp['label']}"
        for cp in output
        if cp.get('sample_count', 0) < 3
    ]
    if low_sample_cps:
        print(
            f"WARNING: {len(low_sample_cps)} checkpoint(s) have fewer than 3 samples"
            f" — median may not be representative: {', '.join(low_sample_cps[:5])}"
            + (" ..." if len(low_sample_cps) > 5 else ""),
            file=sys.stderr,
        )


def compute_median(logcat_files: list[str], output_file: str) -> None:
    groups, total_lines = _aggregate_groups(logcat_files)
    output, cp_key_counts = _build_checkpoints(groups)
    output.sort(key=lambda x: (x['scenario'], x.get('seq', 0)))

    with open(output_file, 'w') as fh:
        json.dump(output, fh, indent=2)

    _emit_warnings(output, cp_key_counts)

    print(
        f"Parsed {total_lines} PERF_METRIC lines from {len(logcat_files)} run(s)."
        f" Wrote {len(output)} checkpoints to {output_file}."
    )


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: compute_median.py <logcat1> [logcat2 ...] <output.json>")
        sys.exit(1)
    compute_median(sys.argv[1:-1], sys.argv[-1])
