#!/bin/sh -ve
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
# Format generated files without causing CI failure
dart format lib/generated/l10n/
flutter analyze
