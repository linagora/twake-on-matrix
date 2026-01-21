#!/bin/sh
# Validates the full Sentry pipeline for Web.
# Builds a release web bundle with source maps and uploads to Sentry.
# Does NOT deploy to any server.
#
# Required env: SENTRY_PROJECT, SENTRY_ORG, SENTRY_AUTH_TOKEN
# Optional env: SENTRY_RELEASE (default: pubspec version left of +)
#               SENTRY_DIST   (default: pubspec build number right of +)
#               TWAKECHAT_BASE_HREF (default: /web/)

set -eu

for _var in SENTRY_PROJECT SENTRY_ORG SENTRY_AUTH_TOKEN; do
  eval "_val=\${${_var}:-}"
  [ -n "$_val" ] || { echo "ERROR: ${_var} is not set" >&2; exit 1; }
done

./scripts/configure-sentry.sh

TWAKECHAT_BASE_HREF=${TWAKECHAT_BASE_HREF:-/web/}
flutter config --enable-web
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build web --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" --release --source-maps --base-href="$TWAKECHAT_BASE_HREF"

./scripts/run-sentry.sh

echo "Sentry Web pipeline: OK"
