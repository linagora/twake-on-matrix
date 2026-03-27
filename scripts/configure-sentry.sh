#!/usr/bin/env sh
# Injects all Sentry config from environment variables into pubspec.yaml.
# Must be called from the repository root BEFORE running flutter build.
#
# Required : SENTRY_PROJECT, SENTRY_ORG
# Optional : SENTRY_RELEASE    (default: left side of pubspec version e.g. 2.19.7)
#            SENTRY_DIST       (default: right side of pubspec version e.g. 2330)
#            TWAKECHAT_BASE_HREF (default: /web/) — used to set url_prefix so Sentry maps
#                               stack frames to the correct source map path (e.g. ~/web/)
# Auth     : SENTRY_AUTH_TOKEN — consumed by sentry_dart_plugin directly; not written here

set -eu

_pubspec_ver=$(grep "^version:" pubspec.yaml | tr -d ' ' | cut -d: -f2)
SENTRY_RELEASE="${SENTRY_RELEASE:-$(echo "${_pubspec_ver}" | cut -d'+' -f1)}"
SENTRY_DIST="${SENTRY_DIST:-$(echo "${_pubspec_ver}" | cut -s -d'+' -f2)}"
SENTRY_DSN="${SENTRY_DSN:-}"
SENTRY_ENVIRONMENT="${SENTRY_ENVIRONMENT:-}"

# Derive url_prefix from TWAKECHAT_BASE_HREF (e.g. /web/ → ~/web/).
# Sentry uses ~ as a placeholder for scheme+host, so ~/web/ matches
# https://example.com/web/main.dart.js in stack frames.
_base_href="${TWAKECHAT_BASE_HREF:-/web/}"
SENTRY_URL_PREFIX="~${_base_href}"

# perl -pi does targeted line replacement without reformatting the rest of the file.
# Each command rewrites only the matching key line; all other content is untouched.
perl -pi -e "s|^  project:.*|  project: ${SENTRY_PROJECT}|" pubspec.yaml
perl -pi -e "s|^  org:.*|  org: ${SENTRY_ORG}|" pubspec.yaml
perl -pi -e "s|^  release:.*|  release: ${SENTRY_RELEASE}|" pubspec.yaml
perl -pi -e "s|^  dist:.*|  dist: \"${SENTRY_DIST}\"|" pubspec.yaml
perl -pi -e "s|^  url_prefix:.*|  url_prefix: ${SENTRY_URL_PREFIX}|" pubspec.yaml

if [ -n "$SENTRY_DSN" ]; then
  # Inject the SENTRY_DSN into the config.sample.json if it's available
  perl -pi -e 's|"sentry_dsn":.*|"sentry_dsn": "$ENV{SENTRY_DSN}",|' config.sample.json
fi

if [ -n "$SENTRY_ENVIRONMENT" ]; then
  # Inject the SENTRY_ENVIRONMENT into the config.sample.json if it's available
  perl -pi -e 's|"sentry_environment":.*|"sentry_environment": "$ENV{SENTRY_ENVIRONMENT}"|' config.sample.json
fi
