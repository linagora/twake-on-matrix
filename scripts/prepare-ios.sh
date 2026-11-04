#!/usr/bin/env bash
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
# Swift Package Manager: wire the Xcode project to the plugin Swift packages and
# generate the Flutter config before fastlane runs xcodebuild directly. Without it
# xcodebuild fails with "Module 'app_links' not found".
flutter build ios --config-only --no-codesign || exit 1
cd ios
pod install && pod update
