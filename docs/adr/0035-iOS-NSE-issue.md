# 35. Fix iOS NSE Decryption Issue

Date: 2026-03-06

## Status

Accepted

## Context

iOS background notification only shows as "You have 1 encrypted message", whether the message is encrypted or not.

### Problem 1: Session stopped syncing

- Before Matrix Dart SDK migration, We was using FlutterHiveCollectionsDatabase as database, and it was using \_updateIOSKeychainSharingRestoreToken to sync session to iOS keychain.
- After Matrix Dart SDK migration, We are using MatrixSdkDatabase as database, and FlutterHiveCollectionsDatabase now only exist to migrate old data, so \_updateIOSKeychainSharingRestoreToken is never called.

### Problem 2: Twake Chat was never confirmed to decrypt notification successfully

- From https://github.com/linagora/twake-on-matrix/issues/1049, only unencrypted notification was successfully shown.
- Matrix Rust SDK implementation was 100% copied from Element X iOS repo to NSE. However, Element X iOS also use Matrix Rust SDK in their main app, so the database where keys live is the same.
- We never properly set up Matrix Rust SDK database in NSE, so even though Matrix Rust SDK has the ability to decrypt encrypted messages, it doesn't have the keys to do so.

## Solution

### 1. Resync the session

To ensure the Notification Service Extension (NSE) has the latest session context, we actively synchronize the session to the iOS keychain.

- Added `KeychainSharingManager.saveSession()` to save `accessToken`, `userId`, `homeserverUrl`, and `deviceId` to the shared secure storage.
- Added a listener in `BackgroundPush._setupKeychainSyncListener` to intercept `client.onSync` events and save the session to the keychain.
- Added `_syncKeychainForClient` in `ClientManager` to save the session whenever a client is initialized.

### 2. Push the recovery key from Flutter side to iOS side

In order to allow the Matrix Rust SDK within the NSE to decrypt messages, it must have access to the recovery key.

- Implemented `BackgroundPush._syncRecoveryKeyToKeychain` to fetch the recovery words via `GetRecoveryWordsInteractor` and push them to the iOS keychain using `KeychainSharingManager.saveRecoveryKey`.
- Added logic to `SettingsController._logoutActions` to delete this recovery key from the keychain upon logout.

## Consequences

### Benefits

- **Successful Decryption**: The NSE now has the necessary session details and keys to instantiate the Matrix Rust SDK and decrypt incoming messages in the background.
- **Improved UX**: Users will see the actual message content rather than a generic "You have 1 encrypted message" notification.

### Risks and Mitigations

- **Security**: Storing the recovery key in the shared keychain increases exposure slightly, but it is necessary for background decryption and is limited to the app's secure app group.
- **State consistency**: Session tokens and recovery keys are correctly cleared upon user logout to prevent unauthorized background process access.
