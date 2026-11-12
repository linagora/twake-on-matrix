#!/bin/bash
#
# Builds what start.sh installs, from the working tree: the debug APK of the Android app
# (Dockerfile.android), in the image twake-chat-mobile-qa-apk: it survives a cleaning of the working
# tree, for start.sh after a build skipped. Synapse is pulled by start.sh.
#
#   scripts/qa-environment/build.sh    # once, and whenever the code under test changes
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# host network: pub get and cargo fail from the default bridge network on some hosts
DOCKER_BUILDKIT=1 docker build --network host -t twake-chat-mobile-qa-apk \
  -f "$SCRIPT_DIR/Dockerfile.android" "$REPO_DIR"
