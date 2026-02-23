#!/usr/bin/env bash
set -e

flutter pub get
flutter pub run sqflite_common_ffi_web:setup --dir=web

rm -rf .vodozemac

version=$(yq ".dependencies.flutter_vodozemac" < pubspec.yaml)
version=$(expr "$version" : '\^*\(.*\)')
git clone https://github.com/famedly/dart-vodozemac.git -b ${version} .vodozemac
cd .vodozemac
rustup component add rust-src --toolchain nightly-aarch64-apple-darwin
rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen build-web --dart-root dart --rust-root $(readlink -f rust) --release --verbose
cd ..
rm -rf ./web/pkg
mv .vodozemac/dart/web/pkg ./web/
rm -rf .vodozemac