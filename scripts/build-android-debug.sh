#!/usr/bin/env bash
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --debug
