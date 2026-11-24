#!/bin/sh -ve
# Called from macos/. Same Sentry flow as the Android release: write the config into
# pubspec.yaml, build (obfuscated, in the fastlane lane), then upload the symbols.
(cd .. && ./scripts/configure-sentry.sh)
bundle exec fastlane beta
(cd .. && ./scripts/run-sentry.sh)
