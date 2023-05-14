#!/bin/sh -ve
flutter config --enable-macos-desktop
flutter clean
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
cd macos
pod install
pod update
cd ..
flutter build macos --release
