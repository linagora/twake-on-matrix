#!/bin/bash

# Setup AppImageTool for packaging
echo "Setting up AppImageTool"
curl -o appimagetool -L "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x appimagetool
sudo mv appimagetool /usr/local/bin/

echo "Packaging."
flutter pub global run flutter_distributor:main.dart package --platform linux --targets appimage --skip-clean --flutter-build-args="profile"
