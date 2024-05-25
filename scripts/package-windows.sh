#!/bin/bash
# Setting up Inno Setup
echo "Downloading and installing Inno Setup."
curl -OL "https://files.jrsoftware.org/is/6/innosetup-6.2.2.exe"
./innosetup-6.2.2.exe //verysilent

echo "Packaging."
flutter pub get
flutter pub global run flutter_distributor:main.dart package --platform windows --targets exe --skip-clean --flutter-build-args="release"
