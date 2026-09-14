#!/usr/bin/env sh
# Downloads the third-party web assets served from our own origin.
#
# Run from the repository root, before `flutter build web`, and before serving
# web/ locally with `flutter run -d chrome`.
#
# Taking the published package rather than hand-copying files is what makes this
# correct: dotlottie reaches part of its code through dynamic import(), so
# picking files by reading the imports is easy to get wrong, while the tarball
# carries the whole dist/ by construction.
#
# The version is pinned and the tarball checked against the integrity hash npm
# publishes for it, so a rebuild cannot pull in different code.

set -eu

DOTLOTTIE_VERSION=2.7.12
DOTLOTTIE_INTEGRITY=sha512-oNv/+bVnmBY3DILdY+ehBWk15Q76m8OByq8gPDpyEQwHf0kRJ6GUO074X1m8WPgvPKw0o8dYnz+UrbOFhZmmqA==

VENDOR_DIR=web/vendor/dotlottie
REGISTRY=https://registry.npmjs.org/@dotlottie/player-component/-

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL -o "$tmp/pkg.tgz" \
  "$REGISTRY/player-component-${DOTLOTTIE_VERSION}.tgz"

actual="sha512-$(openssl dgst -sha512 -binary "$tmp/pkg.tgz" | openssl base64 -A)"
if [ "$actual" != "$DOTLOTTIE_INTEGRITY" ]; then
  echo "error: integrity mismatch for @dotlottie/player-component@${DOTLOTTIE_VERSION}" >&2
  echo "  expected $DOTLOTTIE_INTEGRITY" >&2
  echo "  actual   $actual" >&2
  exit 1
fi

rm -rf "$VENDOR_DIR"
mkdir -p "$VENDOR_DIR"
tar -xzf "$tmp/pkg.tgz" -C "$tmp"
# Only the ES modules: the package also ships CommonJS and type definitions the
# browser never asks for.
cp "$tmp"/package/dist/*.mjs "$VENDOR_DIR/"

echo "vendored @dotlottie/player-component@${DOTLOTTIE_VERSION}: $(ls "$VENDOR_DIR" | wc -l | tr -d ' ') modules"
