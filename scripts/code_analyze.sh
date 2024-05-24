#!/bin/sh -ve
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib/ test/
flutter pub get # In flutter 3.22, flutter gen-l10n is not working properly, so we need to run flutter pub get again
flutter analyze
