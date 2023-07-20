#!/bin/sh -ve
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run import_sorter:main --no-comments
flutter format lib/ test/
flutter pub get
flutter analyze
dart format lib --set-exit-if-changed
flutter pub run dart_code_metrics:metrics lib -r github || true
