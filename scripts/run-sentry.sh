#!/usr/bin/env sh

# Runs the Sentry Dart plugin only if all required environment variables are present.

if [ -n "${SENTRY_ORG:-}" ] && [ -n "${SENTRY_PROJECT:-}" ] && [ -n "${SENTRY_AUTH_TOKEN:-}" ]; then
  echo "Sentry configuration found (Org, Project, Auth Token). Running sentry_dart_plugin..."
  dart run sentry_dart_plugin --log-level=debug --ignore-missing
else
  echo "Skipping sentry_dart_plugin: Missing SENTRY_ORG, SENTRY_PROJECT, or SENTRY_AUTH_TOKEN."
fi
