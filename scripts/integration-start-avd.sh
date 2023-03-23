#!/usr/bin/env bash
echo "y" | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --install "system-images;android-31;default;x86_64"
echo "no" | $ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd -n test -k "system-images;android-31;default;x86_64"
"$ANDROID_HOME"/platform-tools/adb start-server
"$ANDROID_HOME"/emulator/emulator -avd test -wipe-data  -no-audio -no-boot-anim -no-window -accel auto -gpu swiftshader_indirect
