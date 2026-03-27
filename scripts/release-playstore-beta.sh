#!/usr/bin/env bash
./scripts/configure-sentry.sh
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
flutter build appbundle --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" --dart-define=SENTRY_ENVIRONMENT="${SENTRY_ENVIRONMENT:-}" --release --obfuscate --split-debug-info=build/app/outputs/symbols --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json
./scripts/run-sentry.sh
cd android
bundle exec fastlane deploy_internal_test
