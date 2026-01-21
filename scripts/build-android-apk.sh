#!/usr/bin/env bash
./scripts/configure-sentry.sh
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" --release --obfuscate --split-debug-info=build/app/outputs/symbols --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json
./scripts/run-sentry.sh
mkdir -p build/android
cp build/app/outputs/apk/release/app-release.apk build/android/
