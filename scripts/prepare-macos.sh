#!/usr/bin/env bash
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
# Generate the Flutter config and install the pods before fastlane runs xcodebuild directly.
flutter build macos --config-only --release
