#!/usr/bin/env sh

set -eux

# Derive version from git tag and configure Sentry BEFORE the build
version=$(git describe --tags --exact-match)
export SENTRY_RELEASE="${SENTRY_RELEASE:-${version}}"
./scripts/configure-sentry.sh

flutter build apk --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" --release --obfuscate --split-debug-info=build/app/outputs/symbols --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json
./scripts/run-sentry.sh
cp build/app/outputs/apk/release/app-release.apk twake-"$version"-android.apk
