#!/usr/bin/env bash
echo "$ANDROID_KEYSTORE" | base64 --decode --ignore-garbage > android.jks
echo "storePassword=${ANDROID_STORE_PASS}" >> key.properties
echo "keyPassword=${ANDROID_KEY_PASS}" >> key.properties
echo "keyAlias=${ANDROID_KEY_ALIAS}" >> key.properties
echo "storeFile=../android.jks" >> key.properties
echo "$PLAYSTORE_DEPLOY_KEY" >> keys.json
bundle exec fastlane set_build_code_internal
