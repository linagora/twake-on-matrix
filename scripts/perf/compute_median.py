#!/usr/bin/env python3
"""
Parses PERF_METRIC lines from multiple logcat files (one per FTL run),
groups values by (scenario, label, metric_key), and outputs a JSON file
containing the median value of each metric across all runs.

Usage:
    python3 compute_median.py [--include-values] [--expected-samples N]
        [--requirements FILE]
        logcat1.txt logcat2.txt logcat3.txt output.json
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


def _load_requirements(path: str) -> dict[tuple[str, str], set[str]]:
    """Load common and checkpoint-specific required metrics from JSON."""
    data = json.loads(Path(path).read_text(encoding='utf-8'))
    common_metrics = set(data.get('common_metrics', []))
    requirements: dict[tuple[str, str], set[str]] = {}
    for checkpoint in data.get('checkpoints', []):
        key = (checkpoint['scenario'], checkpoint['label'])
        if key in requirements:
            raise ValueError(f"duplicate required checkpoint {key[0]}/{key[1]}")
        requirements[key] = (
            common_metrics | set(checkpoint.get('extra_metrics', []))
        ) - set(checkpoint.get('excluded_metrics', []))
    return requirements


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
    *,
    identity_by_source: bool = False,
) -> tuple[dict[tuple, dict[tuple[int, str], float]], dict[tuple, set], int]:
    """Parse all logcat files and collect numeric values grouped by (scenario, label, key).

    Returns (groups, checkpoint_counts, total_parsed_lines).

    A checkpoint can legitimately omit frame-derived metrics when no frame is
    rendered during its measurement window. Count PERF_METRIC lines separately
    so sample_count represents completed runs rather than the least common
    optional metric.
    """
    groups: dict[tuple, dict[tuple[int, str], float]] = defaultdict(dict)
    checkpoint_samples: dict[tuple, set[tuple[int, str]]] = defaultdict(set)
    total_lines = 0
    for source_index, f in enumerate(logcat_files):
        entries = parse_logcat(f)
        total_lines += len(entries)
        for entry in entries:
            checkpoint = (entry['scenario'], entry['label'])
            sample = (
                source_index,
                '' if identity_by_source else entry.get('run', ''),
            )
            if sample in checkpoint_samples[checkpoint]:
                raise ValueError(
                    f"duplicate sample for {checkpoint[0]}/{checkpoint[1]} "
                    f"from source {source_index}, run={sample[1] or '<missing>'}"
                )
            checkpoint_samples[checkpoint].add(sample)
            for scenario, label, k, v in _entry_metrics(entry):
                groups[(scenario, label, k)][sample] = v
    return groups, checkpoint_samples, total_lines


def _build_checkpoints(
    groups: dict[tuple, dict[tuple[int, str], float]],
    checkpoint_samples: dict[tuple, set],
    *,
    include_values: bool = False,
) -> list[dict]:
    """Compute medians and variance indicators for each (scenario, label) checkpoint.

    Optional frame metrics may have fewer values than checkpoint occurrences.
    The checkpoint sample count therefore comes from PERF_METRIC line
    occurrences, while each aggregate uses the values available for that metric.
    """
    checkpoints: dict[tuple, dict] = {}

    for (scenario, label, key), samples in groups.items():
        values = list(samples.values())
        cp_key = (scenario, label)
        cp = checkpoints.setdefault(
            cp_key,
            {
                'scenario': scenario,
                'label': label,
                'sample_count': len(checkpoint_samples[cp_key]),
            },
        )
        cp[key] = statistics.median(values)
        cp[f'{key}_sample_count'] = len(values)
        if include_values:
            cp[f'{key}_values'] = values
        if len(values) >= 2:
            cp[f'{key}_stddev'] = round(statistics.stdev(values), 2)
            cp[f'{key}_range'] = round(max(values) - min(values), 2)

    return list(checkpoints.values())


def _emit_warnings(output: list[dict]) -> None:
    """Print warnings for checkpoints missing from one or more expected runs."""
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


def _validate_expected_samples(
    groups: dict[tuple, dict[tuple[int, str], float]],
    checkpoint_samples: dict[tuple, set],
    expected_samples: int,
) -> None:
    """Reject checkpoints or metrics absent from any expected repetition."""
    for (scenario, label), samples in sorted(checkpoint_samples.items()):
        count = len(samples)
        if count != expected_samples:
            raise ValueError(
                f"{scenario}/{label} has {count} checkpoint sample(s); "
                f"expected {expected_samples}"
            )
    for (scenario, label, metric), samples in sorted(groups.items()):
        if len(samples) != expected_samples:
            raise ValueError(
                f"{scenario}/{label}/{metric} has {len(samples)} sample(s); "
                f"expected {expected_samples}"
            )


def _validate_requirements(
    groups: dict[tuple, dict[tuple[int, str], float]],
    checkpoint_samples: dict[tuple, set],
    requirements: dict[tuple[str, str], set[str]],
) -> None:
    """Reject required checkpoints or metrics absent from every repetition."""
    for (scenario, label), metrics in sorted(requirements.items()):
        if (scenario, label) not in checkpoint_samples:
            raise ValueError(f"required checkpoint {scenario}/{label} is missing")
        for metric in sorted(metrics):
            if (scenario, label, metric) not in groups:
                raise ValueError(f"{scenario}/{label}/{metric} is missing")


def compute_median(
    logcat_files: list[str],
    output_file: str,
    *,
    include_values: bool = False,
    expected_samples: int | None = None,
    requirements: dict[tuple[str, str], set[str]] | None = None,
) -> None:
    if expected_samples is not None and len(logcat_files) not in (1, expected_samples):
        raise ValueError(
            f"received {len(logcat_files)} logcat file(s); expected either one "
            f"combined log or {expected_samples} repetition files"
        )
    groups, checkpoint_samples, total_lines = _aggregate_groups(
        logcat_files,
        identity_by_source=(
            expected_samples is not None and len(logcat_files) == expected_samples
        ),
    )
    if requirements is not None:
        _validate_requirements(groups, checkpoint_samples, requirements)
    if expected_samples is not None:
        _validate_expected_samples(groups, checkpoint_samples, expected_samples)
    output = _build_checkpoints(
        groups,
        checkpoint_samples,
        include_values=include_values,
    )
    output.sort(key=lambda x: (x['scenario'], x.get('seq', 0)))

    with open(output_file, 'w') as fh:
        json.dump(output, fh, indent=2)

    _emit_warnings(output)

    print(
        f"Parsed {total_lines} PERF_METRIC lines from {len(logcat_files)} run(s)."
        f" Wrote {len(output)} checkpoints to {output_file}."
    )


if __name__ == '__main__':
    arguments = sys.argv[1:]
    include_values = False
    expected_samples = None
    requirements_file = None
    if '--include-values' in arguments:
        arguments.remove('--include-values')
        include_values = True
    if '--expected-samples' in arguments:
        option_index = arguments.index('--expected-samples')
        try:
            expected_samples = int(arguments[option_index + 1])
        except (IndexError, ValueError):
            print("--expected-samples requires a positive integer", file=sys.stderr)
            sys.exit(1)
        if expected_samples < 1:
            print("--expected-samples requires a positive integer", file=sys.stderr)
            sys.exit(1)
        del arguments[option_index:option_index + 2]
    if '--requirements' in arguments:
        option_index = arguments.index('--requirements')
        try:
            requirements_file = arguments[option_index + 1]
        except IndexError:
            print("--requirements requires a JSON file", file=sys.stderr)
            sys.exit(1)
        del arguments[option_index:option_index + 2]
    if len(arguments) < 2:
        print(
            "Usage: compute_median.py [--include-values] [--expected-samples N]"
            " [--requirements FILE]"
            " <logcat1> [logcat2 ...] <output.json>"
        )
        sys.exit(1)
    compute_median(
        arguments[:-1],
        arguments[-1],
        include_values=include_values,
        expected_samples=expected_samples,
        requirements=(
            _load_requirements(requirements_file)
            if requirements_file is not None
            else None
        ),
    )
