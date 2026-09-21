#!/usr/bin/env bash
# Generates build/web/assets/sw-manifest.json, the precache manifest for
# web/push_sw.js.
#
# Run from the repository root, as the LAST step that touches build/web: anything
# mutating the output afterwards (sentry_dart_plugin injects Debug IDs into
# main.dart.js) would leave the manifest describing bytes that are never served.
#
# Flutter does not content-hash its output filenames, so comparing content is the
# only way to know a resource changed between two deploys. The service worker
# fetches this manifest fresh at every boot (nginx serves it with
# Cache-Control: no-store) and evicts whatever whose hash changed.
#
# config.json, version.json and the manifest itself are deliberately excluded:
# they are injected at deploy time or are the version source of truth, so they
# are never cached (nginx sends Cache-Control: no-store and the worker never
# intercepts them). Source maps are excluded because main.dart.js.map alone is
# ~10 MB. The manifest never describes itself.
#
# The output is JSON but assembled with a minimal, guarded serializer: every
# key is a scope-relative path and every value an MD5 hex string, so the only
# characters that can appear are ordinary printable ASCII. A path containing a
# quote, backslash, tab, newline or control byte fails the build instead of
# producing malformed JSON.
#
# Usage: scripts/generate-sw-manifest.sh [BUILD_DIR=build/web]

set -euo pipefail

BUILD_DIR="${1:-build/web}"
MANIFEST="assets/sw-manifest.json"
MANIFEST_PATH="$BUILD_DIR/$MANIFEST"

CORE_CANDIDATES="main.dart.js index.html flutter_bootstrap.js assets/AssetManifest.bin.json assets/FontManifest.json"
# Deployed but never described by the manifest (always-fetch, no-store).
EXCLUDED_NAMES="config.json version.json push_sw.js flutter_service_worker.js $MANIFEST"

die() {
    printf 'generate-sw-manifest.sh: error: %s\n' "$*" >&2
    exit 1
}

[ -d "$BUILD_DIR" ] || die "$BUILD_DIR not found, run 'flutter build web' first"
[ -f "$BUILD_DIR/index.html" ] || die "index.html missing from $BUILD_DIR"
mkdir -p "$BUILD_DIR/assets"

# Fail-fast guard: the JSON emitter quotes keys/values verbatim, so reject any
# path that would need escaping.
assert_safe_path() {
    case "$1" in
        *'"'* | *'\\'* | *$'\t'* | *$'\n'*)
            die "unsafe path in build output: $1"
            ;;
    esac
}

# Is this relative path excluded from the manifest?
is_excluded() {
    local rel="$1" part
    case "$rel" in
        *"/."* | .*) return 0 ;; # any path segment starting with a dot
    esac
    case "$rel" in
        *.map | *.gz) return 0 ;;
    esac
    for part in $EXCLUDED_NAMES; do
        [ "$rel" = "$part" ] && return 0
    done
    return 1
}

# Collect the precache core: explicit candidates plus whatever index.html pulls
# in with src=/href= during the initial HTML parse (those load before a
# first-visit worker exists, so leaving them out delays the benefit by one load).
core_list=""
for candidate in $CORE_CANDIDATES; do
    [ -f "$BUILD_DIR/$candidate" ] && core_list="$core_list $candidate"
done
while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    case "$ref" in
        http://* | https://* | //* | /* | '#'* | data:*) continue ;;
    esac
    ref="${ref%%\?*}"
    ref="${ref%%\#*}"
    [ -f "$BUILD_DIR/$ref" ] && core_list="$core_list $ref"
done < <(grep -oE '(src|href)="[^"]+"' "$BUILD_DIR/index.html" | sed -E 's/^[a-z]+="([^"]+)"/\1/' || true)

# Deduplicate, preserving order.
core_dedup=""
for candidate in $core_list; do
    case " $core_dedup " in
        *" $candidate "*) ;; # already present
        *) core_dedup="$core_dedup $candidate" ;;
    esac
done

# One "<kind>|<rel>|<md5>" line per deployable resource, sorted by path.
rows=""
index_md5=""
resource_count=0
core_count=0
while IFS= read -r -d '' file; do
    rel="${file#"$BUILD_DIR"/}"
    [ -n "$rel" ] || continue
    is_excluded "$rel" && continue
    assert_safe_path "$rel"

    md5=$(md5sum <"$file")
    md5=${md5%% *}

    kind="R"
    case " $core_dedup " in
        *" $rel "*) kind="C"; core_count=$((core_count + 1)) ;;
    esac
    [ "$rel" = "index.html" ] && index_md5="$md5"

    rows="$rows$kind|$rel|$md5
"
    resource_count=$((resource_count + 1))
done < <(find "$BUILD_DIR" -type f -print0 | sort -z)

[ -n "$index_md5" ] || die "index.html missing from the build output"

# The root navigation is the shell; store it under both URL keys so the fetch
# handler and the offline fallback can look it up.
rows="$rows
R|/|$index_md5"
resource_count=$((resource_count + 1))

mkdir -p "$BUILD_DIR/assets"

{
    printf '{\n'
    printf '  "core": [\n'
    first=1
    for candidate in $core_dedup; do
        if [ "$first" -eq 1 ]; then first=0; else printf ',\n'; fi
        printf '    "%s"' "$candidate"
    done
    printf '\n  ],\n'
    printf '  "resources": {\n'
    first=1
    while IFS='|' read -r kind rel md5; do
        [ -n "$kind" ] || continue
        if [ "$first" -eq 1 ]; then first=0; else printf ',\n'; fi
        printf '    "%s": "%s"' "$rel" "$md5"
    done <<< "$rows"
    printf '\n  }\n}\n'
} > "$MANIFEST_PATH"

[ -s "$MANIFEST_PATH" ] || die "empty manifest written to $MANIFEST_PATH"

printf 'precache manifest: %s resources, %s in CORE\n' "$resource_count" "$core_count"