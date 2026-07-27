#!/usr/bin/env python3
"""Add a deployment version to dashboard assets to avoid stale browser caches."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


ASSETS = (
    "styles.css",
    "vendor/chart.umd.min.js",
    "metrics.js",
    "app.js",
)


def version_dashboard_assets(index_path: Path, version: str) -> None:
    """Append the same cache-busting version to every local dashboard asset."""
    if not re.fullmatch(r"[A-Za-z0-9._-]+", version):
        raise ValueError("Asset version contains unsupported characters")

    html = index_path.read_text(encoding="utf-8")
    for asset in ASSETS:
        pattern = rf'((?:href|src)="{re.escape(asset)})(?:\?v=[^"]*)?(\")'
        html, replacements = re.subn(
            pattern,
            rf"\g<1>?v={version}\g<2>",
            html,
        )
        if replacements != 1:
            raise ValueError(
                f"Expected exactly one dashboard reference to {asset}, "
                f"found {replacements}"
            )
    index_path.write_text(html, encoding="utf-8")


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--index", type=Path, required=True)
    parser.add_argument("--version", required=True)
    return parser.parse_args()


def main() -> None:
    arguments = _arguments()
    version_dashboard_assets(arguments.index, arguments.version)


if __name__ == "__main__":
    main()
