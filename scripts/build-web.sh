#!/bin/sh -ve
flutter config --enable-web
flutter clean
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
flutter build web --release --verbose --source-maps
# bug of the Flutter engine
chmod +r -R build/web