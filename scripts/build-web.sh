#!/bin/sh -ve
flutter config --enable-web
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build web --release --verbose --source-maps --base-href="/web/"
cp config.sample.json ./build/web/config.json
