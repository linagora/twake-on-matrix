#!/bin/bash

# Install appdmg for packaging
echo "Installing appdmg."
npm install -g appdmg

echo "Packaging."
# Change code signing identity
sed -i .bak "s/@@IDENTITY@@/Developer ID Application: Linagora/" macos/packaging/dmg/make_config.yaml
flutter pub global run flutter_distributor:main.dart package --platform macos --target dmg --skip-clean --flutter-build-args="release"
