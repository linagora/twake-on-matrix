#!/usr/bin/env bash
set -e

rm -rf .vodozemac

# Get the version of flutter_vodozemac from pubspec.yaml.
version=$(yq ".dependencies.flutter_vodozemac" < pubspec.yaml)
# Clean the version string to make it suitable for use as a Git branch or tag name.
# This regex extracts the first occurrence of a semantic version number (MAJOR.MINOR.PATCH)
# followed by any alphanumeric, dot, or hyphen characters (e.g., for pre-release identifiers).
cleaned_version=$(echo "${version}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+([a-zA-Z0-9.-]*)?' | head -n 1)

# Clone the dart-vodozemac repository using the cleaned version as a branch/tag.
git clone https://github.com/famedly/dart-vodozemac.git -b "${cleaned_version}" --single-branch .vodozemac
cd .vodozemac

echo "Successfully cloned dart-vodozemac at version: ${cleaned_version}"

# Add stable Rust toolchains for necessary targets.
rustup component add rust-src --toolchain stable

cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen build-web --dart-root dart --rust-root "$(readlink -f rust)" --release --verbose
cd ..
rm -rf ./web/pkg
mv .vodozemac/dart/web/pkg ./web/
rm -rf .vodozemac
# Ensure the file ends with a newline character.
