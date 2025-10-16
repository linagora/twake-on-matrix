#!/usr/bin/env bash
set -e

rm -rf .vodozemac


# Get the version of flutter_vodozemac from pubspec.yaml.
# This version is used to select the corresponding branch/tag for cloning the dart-vodozemac repository.
version=$(yq ".dependencies.flutter_vodozemac" < pubspec.yaml)
version=$(expr "$version" : '\^*\(.*\)')

# Get the SHA256 checksum from pubspec.lock for flutter_vodozemac.
# The user indicates this SHA256 should be used as the *expected commit hash*
# to verify the cloned dart-vodozemac repository.
expected_commit_hash=$(yq ".packages.flutter_vodozemac.sha256" pubspec.lock)

# Clone the dart-vodozemac repository using the version branch/tag.
git clone https://github.com/famedly/dart-vodozemac.git -b "${version}" .vodozemac
cd .vodozemac

actual_commit_hash=$(git rev-parse HEAD)

# Verify that the actual commit hash matches the expected commit hash from pubspec.lock.
if [ "${actual_commit_hash}" != "${expected_commit_hash}" ]; then
  echo "Error: Cloned dart-vodozemac commit hash (${actual_commit_hash}) does not match expected SHA256 from pubspec.lock (${expected_commit_hash})."
  exit 1
fi
echo "Successfully cloned and verified dart-vodozemac at commit: ${actual_commit_hash}"

# Add stable Rust toolchains for necessary targets.
rustup component add rust-src --toolchain stable

cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen build-web --dart-root dart --rust-root $(readlink -f rust) --release --verbose
cd ..
rm -rf ./web/pkg
mv .vodozemac/dart/web/pkg ./web/
rm -rf .vodozemac
# Ensure the file ends with a newline character.
