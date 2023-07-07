#!/bin/sh -ve
echo "Setup Linux dependencies"
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libjsoncpp-dev locate libfuse-dev libolm-dev

# Updating database of locate
sudo updatedb

flutter config --enable-linux-desktop
flutter clean
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
flutter build linux --profile -v
