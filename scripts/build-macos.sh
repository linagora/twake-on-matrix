#!/bin/sh -ve
flutter config --enable-macos-desktop
flutter clean
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
flutter pub get
cd macos
bundle exec fastlane sync_dev_id
pod install --repo-update
pod update
flutter build macos --release -v
