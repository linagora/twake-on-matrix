#!/bin/sh -ve
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
# Ensure generated localization files are formatted correctly
dart format --set-exit-if-changed lib/generated/l10n/
dart format --set-exit-if-changed lib/ test/
flutter analyze
