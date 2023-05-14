#!/bin/sh -ve
flutter config --enable-linux-desktop
flutter clean
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
flutter build linux --release -v
