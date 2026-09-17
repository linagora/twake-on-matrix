#!/usr/bin/env python3
"""Injects the precache manifest into build/web/push_sw.js.

Run from the repository root, as the LAST step that touches build/web: anything
mutating the output afterwards (sentry_dart_plugin injects Debug IDs into
main.dart.js) would leave the manifest describing bytes that are never served.

Flutter does not content-hash its output filenames, so comparing content is the
only way to know a resource changed between two deploys.

config.json is excluded because it is injected at deploy time from Helm values:
precached, it would pin the app to a stale homeserver or VAPID key whenever the
config changes without an image rebuild. Source maps are excluded because
main.dart.js.map alone is ~10 MB.
"""

import hashlib
import json
import pathlib
import re
import sys

BUILD_DIR = pathlib.Path("build/web")
WORKER = BUILD_DIR / "push_sw.js"

EXCLUDED_NAMES = {"config.json", "push_sw.js", "flutter_service_worker.js"}
EXCLUDED_SUFFIXES = (".map", ".gz")

CORE_CANDIDATES = [
    "main.dart.js",
    "index.html",
    "flutter_bootstrap.js",
    "assets/AssetManifest.bin.json",
    "assets/FontManifest.json",
]

ASSET_REFERENCE = re.compile(r"""\b(?:src|href)=["']([^"']+)["']""")


def is_excluded(relative):
    if relative in EXCLUDED_NAMES or relative.endswith(EXCLUDED_SUFFIXES):
        return True
    return any(part.startswith(".") for part in relative.split("/"))


def collect_resources():
    resources = {}
    for path in sorted(BUILD_DIR.rglob("*")):
        relative = path.relative_to(BUILD_DIR).as_posix()
        if path.is_file() and not is_excluded(relative):
            resources[relative] = hashlib.md5(path.read_bytes()).hexdigest()
    return resources


def referenced_by_index(index_html):
    for reference in ASSET_REFERENCE.findall(index_html):
        if reference.startswith(("http://", "https://", "//", "/", "#", "data:")):
            continue
        yield reference.split("?", 1)[0].split("#", 1)[0]


def build_core(resources):
    """CORE also holds what index.html pulls in: those load during the initial
    HTML parse, before a first-visit worker exists, so leaving them out delays
    the full benefit by one load."""
    core = list(CORE_CANDIDATES)
    core.extend(referenced_by_index((BUILD_DIR / "index.html").read_text()))
    return [name for name in dict.fromkeys(core) if name in resources]


def placeholder_for(token):
    empty = "{}" if token.endswith("RESOURCES") else "[]"
    return f"/*{{{{{token}}}}}*/ {empty}"


def inject(source, values_by_token):
    for token, value in values_by_token.items():
        placeholder = placeholder_for(token)
        if placeholder not in source:
            sys.exit(f"error: placeholder for {token} not found in {WORKER}")
        source = source.replace(placeholder, json.dumps(value, sort_keys=True), 1)
    return source


def main():
    if not WORKER.is_file():
        sys.exit(f"error: {WORKER} not found, run 'flutter build web' first")

    resources = collect_resources()
    if "index.html" not in resources:
        sys.exit("error: index.html missing from the build output")
    resources["/"] = resources["index.html"]

    core = build_core(resources)
    WORKER.write_text(
        inject(
            WORKER.read_text(),
            {"TWAKE_PRECACHE_RESOURCES": resources, "TWAKE_PRECACHE_CORE": core},
        )
    )
    print(f"precache manifest: {len(resources)} resources, {len(core)} in CORE")


if __name__ == "__main__":
    main()
