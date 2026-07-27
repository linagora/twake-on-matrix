#!/usr/bin/env bash

set -euo pipefail

readonly prefix="docs/flutter-guidelines"
readonly upstream="https://github.com/linagora/twake-flutter-guidelines.git"

git subtree pull \
  --prefix="$prefix" \
  "$upstream" \
  main \
  --squash
