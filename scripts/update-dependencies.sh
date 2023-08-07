#!/bin/sh -ve
flutter pub upgrade --major-versions
flutter pub get
dart fix --apply
dart format lib test
flutter pub run import_sorter:main --no-comments