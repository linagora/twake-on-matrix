#!/usr/bin/env sh
# Validates the full Sentry pipeline for iOS.
# Builds a release IPA with debug symbols and uploads to Sentry.
# Does NOT submit to TestFlight or the App Store.
#
# Required env: SENTRY_PROJECT, SENTRY_ORG, SENTRY_AUTH_TOKEN
# Optional env: SENTRY_RELEASE (default: pubspec version left of +)
#               SENTRY_DIST   (default: pubspec build number right of +)

set -eu

for _var in SENTRY_PROJECT SENTRY_ORG SENTRY_AUTH_TOKEN; do
  eval "_val=\${${_var}:-}"
  [ -n "$_val" ] || { echo "ERROR: ${_var} is not set" >&2; exit 1; }
done

./scripts/configure-sentry.sh

flutter pub get
flutter build ios --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" --dart-define=SENTRY_ENVIRONMENT="${SENTRY_ENVIRONMENT:-}" --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json

./scripts/run-sentry.sh

echo "Sentry iOS pipeline: OK"
