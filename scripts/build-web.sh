#!/bin/sh -ve
./scripts/configure-sentry.sh
TWAKECHAT_BASE_HREF=${TWAKECHAT_BASE_HREF:-/web/}
flutter config --enable-web
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
# --no-web-resources-cdn keeps CanvasKit on our own origin. Without it Flutter
# points the app at gstatic.com, while shipping an unused local copy anyway.
flutter build web --release --verbose --source-maps --no-web-resources-cdn --base-href="$TWAKECHAT_BASE_HREF"
cp config.sample.json ./build/web/config.json
./scripts/run-sentry.sh
