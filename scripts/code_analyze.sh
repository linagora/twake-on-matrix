#!/bin/sh -ve
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
# Format generated files without causing CI failure
dart format lib/generated/l10n/
# Format and check developer-written files for changes, failing CI if necessary
dart format --set-exit-if-changed lib/ test/ integration_test/
flutter analyze
