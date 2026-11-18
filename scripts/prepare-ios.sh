#!/usr/bin/env bash
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
# Swift Package Manager: wire the Xcode project to the plugin Swift packages and
# generate the Flutter config before fastlane runs xcodebuild directly. Without it
# xcodebuild fails with "Module 'app_links' not found".
# The dart-defines must be passed here: fastlane's xcodebuild takes them from the
# generated ios/Flutter/Generated.xcconfig, so without them the release has no Sentry DSN.
flutter build ios --config-only --no-codesign \
  --dart-define=SENTRY_DSN="${SENTRY_DSN:-}" \
  --dart-define=SENTRY_ENVIRONMENT="${SENTRY_ENVIRONMENT:-}" || exit 1
cd ios
pod install && pod update
