# 35. Fix iOS NSE notifications with pure-Swift Megolm decryption

Date: 2026-03-05

## Status

Accepted

## Context

The iOS Notification Service Extension (NSE) was forked from Element X iOS and relied on `MatrixRustSDK` to decrypt E2EE messages. The Dart SDK and Rust SDK maintain completely separate crypto stores:

| Layer | Crypto store |
|---|---|
| Dart SDK (main app) | `<AppDocuments>/databases/<clientName>.db` (SQLite) |
| Rust SDK (NSE) | `<AppGroup>/Library/Application Support/.../Sessions/` |

Two failures resulted from this mismatch:

1. **Unencrypted notifications:** Matrix SDK v6.0.0 (SQLite) no longer auto-writes session credentials to the iOS keychain (the old Hive DB did). The NSE could not find credentials, so it fell back to the generic APN string "You have 1 encrypted message".

2. **Encrypted notifications:** Even with valid credentials, the Rust SDK crypto store is empty after a Dart-only login, so `notificationClient.getNotification()` throws and the NSE falls back to "Notification".

## Decision

**Fix 1 — Sync credentials to keychain** so the NSE can authenticate HTTP calls:
- `ClientManager._syncKeychainForClient()` writes credentials after each client init.
- `BackgroundPush._setupKeychainSyncListener()` re-writes on every sync.
- `KeychainSharingManager.saveSession()` is the shared helper for both.
- `NSE/KeychainController` and `RestorationToken` are simplified to pure Swift (no Rust SDK dependency).

**Fix 2 — Replace `MatrixRustSDK` in the NSE entirely** with a self-contained pure-Swift pipeline:

Key-sharing (Dart → NSE via AppGroup):
- `BackgroundPush._setupRoomKeyExportListener()` intercepts `m.room_key` to-device events.
- `IosMegolmSessionWriter` sends them over MethodChannel `megolm_session_store`.
- `AppGroupMegolmPlugin.swift` writes `megolm_sessions.json` atomically (NSLock + `.atomic`).
- `_exportExistingSessionKeys()` seeds all existing sessions on app launch.

NSE notification flow:
```
push received
  → MatrixHTTPFetcher: fetch event from homeserver
  → unencrypted (m.room.message): read body → notify
  → encrypted (m.room.encrypted):
      AppGroupMegolmStore: look up session key
      MegolmDecryptor: decrypt → extract body → notify
      key missing / decrypt fails: discard → original APN content
```

New NSE-only Swift files (no external dependencies):
- `MegolmDecryptor.swift` — HMAC-SHA256 ratchet advance, HKDF-SHA256 key derivation, AES-256-CBC decryption (CryptoKit + CommonCrypto)
- `MatrixHTTPFetcher.swift` — CS API: event, profile, room state, media download
- `MatrixAttachmentDecryptor.swift` — AES-256-CTR for encrypted media
- `AppGroupMegolmStore.swift` — reads `megolm_sessions.json` from AppGroup container

Removed: all `Provider/`, `Proxy/`, `NSEUserSession`, `NotificationContentBuilder`, `RustTracing`.

## Consequences

- Removes `MatrixRustSDK` from the NSE — smaller binary, no Rust FFI complexity.
- Unencrypted messages always show actual content (authenticated HTTP fetch).
- E2EE messages show content for sessions received after app launch.
- Encrypted media (images, video, audio) are decrypted and shown as attachments.
- Keys received before app launch are unavailable until next app start (seeded at startup).
- `megolm_sessions.json` grows indefinitely — no eviction policy yet.
- Session keys are stored plaintext in the AppGroup container (same security boundary as NSE).
