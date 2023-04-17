#!/usr/bin/env bash
# git apply ../scripts/enable-android-google-services.patch
# echo "$GOOGLE_SERVICES_JSON" > app/google-services.json
echo "$ANDROID_KEYSTORE" | base64 --decode --ignore-garbage > android.jks
echo "storePassword=${ANDROID_STORE_PASS}" >> key.properties
echo "keyPassword=${ANDROID_KEY_PASS}" >> key.properties
echo "keyAlias=${ANDROID_KEY_ALIAS}" >> key.properties
echo "storeFile=../android.jks" >> key.properties
echo "$PLAYSTORE_DEPLOY_KEY" >> keys.json
