#!/usr/bin/env bash
set -e

rm -rf .vodozemac

version=$(yq ".dependencies.flutter_vodozemac" < pubspec.yaml)
version=$(expr "$version" : '\^*\(.*\)')
git clone https://github.com/famedly/dart-vodozemac.git -b ${version} .vodozemac
cd .vodozemac
OS_NAME=$(uname -s)
ARCH_NAME=$(uname -m)

if [ "$ARCH_NAME" = "x86_64" ]; then
    RUST_ARCH="x86_64"
elif [ "$ARCH_NAME" = "arm64" ] || [ "$ARCH_NAME" = "aarch64" ]; then
    RUST_ARCH="aarch64"
else
    echo "Unsupported architecture: $ARCH_NAME"
    exit 1
fi

if [ "$OS_NAME" = "Darwin" ]; then
    RUST_OS="apple-darwin"
elif [ "$OS_NAME" = "Linux" ]; then
    RUST_OS="unknown-linux-gnu"
else
    echo "Unsupported OS: $OS_NAME"
    exit 1
fi

TOOLCHAIN="nightly-${RUST_ARCH}-${RUST_OS}"
rustup component add rust-src --toolchain "$TOOLCHAIN"
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen build-web --dart-root dart --rust-root $(cd rust && pwd) --release --verbose
cd ..
rm -rf ./web/pkg
mv .vodozemac/dart/web/pkg ./web/
rm -rf .vodozemac