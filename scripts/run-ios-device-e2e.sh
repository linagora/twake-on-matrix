#!/usr/bin/env bash
# Run Patrol E2E tests on a physical iOS device.
#
# This environment needs three workarounds, all handled here:
#
#  1. Signing: the Xcode "Release" configuration is signed with App Store
#     profiles, which cannot be installed on a device. Patrol forces release
#     mode on physical iOS devices, so every target's Release signing is
#     temporarily switched to automatic and the project is restored on exit.
#  2. Xcode 26.6 does not pass the Swift Package binary target's module map
#     while compiling matrix-rust-components-swift, so the FFI types
#     (RustBuffer, ...) are missing. A small `xcodebuild` wrapper placed first
#     in PATH injects the module map and disables explicit modules.
#  3. Patrol does not pass `-allowProvisioningUpdates`, so the wrapper adds it
#     too (needed for automatic signing to resolve managed profiles).
#
# Prerequisites:
#  - `patrol` CLI in PATH (the version pinned by CI, e.g. 4.3.1).
#  - `integration_test/.env.local.do-not-commit` with a DEVICE= entry.
#  - The device must be unlocked with "Enable UI Automation" turned on
#    (Settings > Developer).
#
# Usage:
#   scripts/run-ios-device-e2e.sh [--device <udid>] [--target <path>] [patrol args...]
#
# Defaults:
#   device: DEVICE= from integration_test/.env.local.do-not-commit
#   target: integration_test/tests/contact/contact_test.dart

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ENV_FILE="integration_test/.env.local.do-not-commit"
PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
DEVICE="${DEVICE:-}"
TARGET="integration_test/tests/contact/contact_test.dart"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    *) break ;;
  esac
done

if [[ -z "$DEVICE" && -f "$ENV_FILE" ]]; then
  DEVICE="$(grep -E '^DEVICE=' "$ENV_FILE" | cut -d= -f2- || true)"
fi
if [[ -z "$DEVICE" ]]; then
  echo "error: no device. Pass --device <udid> or set DEVICE= in $ENV_FILE" >&2
  exit 2
fi
if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: missing $ENV_FILE" >&2
  exit 2
fi
command -v patrol >/dev/null || { echo "error: patrol CLI not found in PATH" >&2; exit 2; }
command -v ruby >/dev/null || { echo "error: ruby not found in PATH" >&2; exit 2; }

# --- temporary xcodebuild wrapper --------------------------------------
WRAP_DIR="$(mktemp -d)"
cleanup() {
  git -C "$ROOT" checkout -- "$PBXPROJ" 2>/dev/null || true
  rm -rf "$WRAP_DIR"
}
trap cleanup EXIT

cat > "$WRAP_DIR/xcodebuild" <<'WRAP'
#!/bin/bash
REAL="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
args=("$@")
dd=""
for ((i=0; i<${#args[@]}; i++)); do
  a="${args[$i]}"
  if [[ "$a" == "-derivedDataPath" ]]; then dd="${args[$((i+1))]}"; fi
  if [[ "$a" == -derivedDataPath=* ]]; then dd="${a#-derivedDataPath=}"; fi
done
if printf '%s\n' "${args[@]}" | grep -q 'build-for-testing'; then
  dd_abs=""
  [[ -n "$dd" ]] && dd_abs="$(cd "$dd" 2>/dev/null && pwd)"
  mmp=""
  if [[ -n "$dd_abs" ]]; then
    for cfg in Release-iphoneos Debug-iphonesimulator Release-iphonesimulator Debug-iphoneos; do
      cand="$dd_abs/Build/Products/$cfg/include/MatrixSDKFFI/module.modulemap"
      [[ -f "$cand" ]] && mmp="$cand" && break
    done
  fi
  if [[ -z "$mmp" ]]; then
    for cand in \
      "$PWD/build/ios_integ/Build/Products/Release-iphoneos/include/MatrixSDKFFI/module.modulemap" \
      "$PWD/build/ios_integ/Build/Products/Debug-iphonesimulator/include/MatrixSDKFFI/module.modulemap" \
      "$PWD/build/ios/Build/Products/Release-iphoneos/include/MatrixSDKFFI/module.modulemap" \
      "$PWD/build/ios/Build/Products/Debug-iphonesimulator/include/MatrixSDKFFI/module.modulemap"; do
      [[ -f "$cand" ]] && mmp="$cand" && break
    done
  fi
  args+=(SWIFT_ENABLE_EXPLICIT_MODULES=NO -allowProvisioningUpdates -allowProvisioningDeviceRegistration)
  # fcm_shared_isolate was compiled with an older Swift toolchain that
  # force-loads compatibility shims no longer shipped by Xcode 26. Treat
  # those symbols as expected-undefined so the RunnerUITests link succeeds.
  args+=("OTHER_LDFLAGS=\$(inherited) -Wl,-U,__swift_FORCE_LOAD_\$_swiftCompatibility51 -Wl,-U,__swift_FORCE_LOAD_\$_swiftCompatibility56 -Wl,-U,__swift_FORCE_LOAD_\$_swiftCompatibilityConcurrency")
  if [[ -n "$mmp" ]]; then
    args+=("OTHER_SWIFT_FLAGS=\$(inherited) -D PATROL_ENABLED -Xcc -fmodule-map-file=$mmp")
  fi
  echo "[xcodebuild-wrapper] injected SWIFT_ENABLE_EXPLICIT_MODULES=NO, module-map=$mmp" >&2
  echo "[xcodebuild-wrapper] dd=$dd dd_abs=$dd_abs" >&2
fi
exec "$REAL" "${args[@]}"
WRAP
chmod +x "$WRAP_DIR/xcodebuild"

# --- temporary signing switch (Release -> automatic) -------------------
ruby -e '
require "xcodeproj"
project = Xcodeproj::Project.open("ios/Runner.xcodeproj")
project.targets.each do |target|
  config = target.build_configurations.find { |c| c.name == "Release" }
  next unless config
  settings = config.build_settings
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings.delete("CODE_SIGN_IDENTITY")
  settings.delete("CODE_SIGN_IDENTITY[sdk=iphoneos*]")
  settings.delete("PROVISIONING_PROFILE_SPECIFIER")
  settings.delete("PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]")
  settings["DEVELOPMENT_TEAM"] = "KUT463DS29"
  settings["DEVELOPMENT_TEAM[sdk=iphoneos*]"] = "KUT463DS29"
end
project.save
'

# --- run ---------------------------------------------------------------
# Patrol forces release mode on physical iOS devices; simulators need debug.
MODE_FLAG="--release"
if [[ "$DEVICE" =~ ^[0-9A-Fa-f]{8}- ]]; then
  MODE_FLAG="--debug"
fi
echo "== patrol test on $DEVICE (target: $TARGET, mode: $MODE_FLAG) =="
PATH="$WRAP_DIR:$PATH" patrol test \
  -d "$DEVICE" \
  "$MODE_FLAG" \
  --target "$TARGET" \
  --dart-define-from-file "$ENV_FILE" \
  "$@"
