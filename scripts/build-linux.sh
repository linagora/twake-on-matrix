#!/bin/sh -ve
echo "Setup Linux dependencies"
sudo apt update
sudo apt-get install -y clang cmake ninja-build \
                              pkg-config libgtk-3-dev liblzma-dev \
                              libjsoncpp-dev libfuse-dev \
                              libolm-dev libmpv-dev libsecret-1-dev

flutter config --enable-linux-desktop
flutter clean
flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs
flutter build linux --release -v
