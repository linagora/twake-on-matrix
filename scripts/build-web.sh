#!/bin/sh -ve
TWAKECHAT_BASE_HREF=${TWAKECHAT_BASE_HREF:-/web/}
flutter config --enable-web
flutter clean
flutter pub get
flutter pub run sqflite_common_ffi_web:setup --dir=web
flutter pub run build_runner build --delete-conflicting-outputs
flutter build web --release --verbose --source-maps --base-href="$TWAKECHAT_BASE_HREF"

if [ -f "web/sqflite_sw.js" ] && [ -f "web/sqlite3.wasm" ]; then
  cp web/sqflite_sw.js ./build/web/
  cp web/sqlite3.wasm ./build/web/
else
  echo "ERROR: sqflite web binaries not found"
  exit 1
fi

cp config.sample.json ./build/web/config.json
