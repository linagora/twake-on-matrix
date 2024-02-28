#!/usr/bin/env sh

set -eux

flutter build apk --release
version=$(git describe --tags --exact-match)
cp build/app/outputs/apk/release/app-release.apk twake-"$version"-android.apk
