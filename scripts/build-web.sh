#!/bin/sh -ve
TWAKECHAT_BASE_HREF=${TWAKECHAT_BASE_HREF:-/web/}
flutter config --enable-web
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build web --release --verbose --source-maps --base-href="$TWAKECHAT_BASE_HREF"
cp config.sample.json ./build/web/config.json
