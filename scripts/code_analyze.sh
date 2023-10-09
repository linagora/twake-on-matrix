#!/bin/sh -ve
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib/ test/
dart run dart_code_metrics:metrics check-unused-files lib
dart run dependency_validator && flutter analyze
