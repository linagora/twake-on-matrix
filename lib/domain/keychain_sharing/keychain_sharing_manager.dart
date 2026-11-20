import 'dart:convert';

import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';

class KeychainSharingManager {
  static FlutterSecureStorage get _secureStorage => const FlutterSecureStorage(
    iOptions: IOSOptions(
      groupId: AppConfig.iOSKeychainSharingId,
      accountName: AppConfig.iOSKeychainSharingAccount,
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _ssssRecoveryKeyPrefix = 'ssss_recovery_';

  static Future<void> saveRecoveryKey({
    required String? userId,
    required String recoveryKey,
  }) async {
    if (!PlatformInfos.isIOS || userId == null) return;
    try {
      await _secureStorage.write(
        key: '$_ssssRecoveryKeyPrefix$userId',
        value: recoveryKey,
      );
      Logs().d('[KeychainSharing] Saved SSSS recovery key for $userId');
    } catch (e, s) {
      Logs().wtf('[KeychainSharing] Unable to save SSSS recovery key', e, s);
    }
  }

  static Future<void> deleteRecoveryKey({required String? userId}) async {
    if (!PlatformInfos.isIOS || userId == null) return;
    try {
      await _secureStorage.delete(key: '$_ssssRecoveryKeyPrefix$userId');
      Logs().d('[KeychainSharing] Deleted SSSS recovery key for $userId');
    } catch (e, s) {
      Logs().wtf('[KeychainSharing] Unable to delete SSSS recovery key', e, s);
    }
  }

  static const String _httpSessionPrefix = 'http_';

  /// The app's own token for a notification extension that only does HTTP.
  /// It has no `session` field and its own key, so [read] never returns it
  /// and [removeAppSession] never purges it.
  static Future<void> saveHttpSession(Client client) async {
    final userId = client.userID;
    final accessToken = client.accessToken;
    final homeserver = client.homeserver;
    if (!PlatformInfos.isIOS ||
        userId == null ||
        accessToken == null ||
        homeserver == null) {
      return;
    }
    try {
      await _secureStorage.write(
        key: '$_httpSessionPrefix$userId',
        value: jsonEncode({
          'accessToken': accessToken,
          'userId': userId,
          'homeserverUrl': homeserver.toString(),
          'pusherNotificationClientIdentifier': userId.sha256Hash,
        }),
      );
    } catch (e, s) {
      Logs().wtf('[KeychainSharing] Unable to save HTTP session', e, s);
    }
  }

  static Future<void> deleteHttpSession(String userId) async {
    if (!PlatformInfos.isIOS) return;
    try {
      await _secureStorage.delete(key: '$_httpSessionPrefix$userId');
    } catch (e, s) {
      Logs().wtf('[KeychainSharing] Unable to delete HTTP session', e, s);
    }
  }

  /// Written by the NSE: the ed25519 key it generated for its device.
  static const String _nseDeviceKeyPrefix = 'nse_ed25519_';

  /// The app cross-signs the extension's device, so it needs the
  /// self-signing key in cache. Without cross-signing, senders share keys with
  /// every device anyway.
  static Future<bool> notificationPreviewsLocked(Client client) async {
    final cached = await client.encryption?.crossSigning.isCached() ?? false;
    return client.userDeviceKeys[client.userID]?.masterKey != null && !cached;
  }

  /// Whether the extension has its own device for [client].
  static Future<bool> hasNotificationSession(Client client) async {
    final userId = client.userID;
    if (!PlatformInfos.isIOS || userId == null) return false;
    final token = await read(userId: userId);
    return token?.dedicated == true &&
        token?.session.deviceId != client.deviceID;
  }

  /// Removes a keychain session that is not a dedicated extension session.
  ///
  /// Older versions stored the app's own session there, which made the
  /// extension take over the app's device.
  static Future<void> removeAppSession(Client client) async {
    final userId = client.userID;
    if (!PlatformInfos.isIOS || userId == null) return;
    final token = await read(userId: userId);
    if (token == null) return;
    if (token.dedicated != true || token.session.deviceId == client.deviceID) {
      Logs().i('[KeychainSharing] Removing the app session of $userId');
      await delete(userId: userId);
    }
  }

  /// Keeps the extension's device usable: forgets it once revoked, and
  /// cross-signs it so senders that share keys only with cross-signed
  /// devices (Dart SDK `crossVerifiedIfEnabled`) reach it.
  ///
  /// The device publishes its keys on its first push, so signing waits for
  /// a later call (startup or own device list change).
  static Future<void> checkNotificationDevice(Client client) async {
    final userId = client.userID;
    final homeserver = client.homeserver;
    if (!PlatformInfos.isIOS || userId == null || homeserver == null) return;
    final token = await read(userId: userId);
    if (token?.dedicated != true) return;
    final session = token!.session;
    try {
      await MatrixApi(
        homeserver: homeserver,
        accessToken: session.accessToken,
        httpClient: client.httpClient,
      ).getTokenOwner();
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_UNKNOWN_TOKEN) {
        Logs().i('[KeychainSharing] Notification device revoked for $userId');
        await delete(userId: userId);
      }
      return;
    } catch (_) {
      return; // offline: try again later
    }
    final encryption = client.encryption;
    if (encryption == null || !await encryption.crossSigning.isCached()) {
      return;
    }
    try {
      await client.updateUserDeviceKeys();
      final device =
          client.userDeviceKeys[userId]?.deviceKeys[session.deviceId];
      // Same check as a sender's `ShareKeysWith.crossVerifiedIfEnabled`.
      if (device == null ||
          device.hasValidSignatureChain(verifiedByTheirMasterKey: true)) {
        return;
      }
      // Sign only the keys the extension generated, never keys the server
      // published for that device id.
      final nseKey = await _secureStorage.read(
        key: '$_nseDeviceKeyPrefix${session.deviceId}',
      );
      if (nseKey == null || nseKey != device.ed25519Key) {
        Logs().w(
          '[KeychainSharing] Keys of ${device.deviceId} do not match the NSE',
        );
        return;
      }
      await encryption.crossSigning.sign([device]);
      Logs().i(
        '[KeychainSharing] Signed notification device ${device.deviceId}',
      );
    } catch (e, s) {
      Logs().w('[KeychainSharing] Unable to sign notification device', e, s);
    }
  }

  static const String _ownKeysCheckedPrefix = 'own_keys_checked_';

  /// Older versions let the notification extension upload its identity keys
  /// over the app's device. Checks the server copy once per device: missing
  /// keys are uploaded again. Returns true when they differ: other clients
  /// pinned the extension's keys for this device id, so only a new login
  /// (new device) restores a working identity.
  static Future<bool> isDeviceIdentityOverwritten(Client client) async {
    final userId = client.userID;
    final deviceId = client.deviceID;
    final encryption = client.encryption;
    if (!PlatformInfos.isIOS ||
        userId == null ||
        deviceId == null ||
        encryption == null ||
        // Olm account not loaded yet: check again on the next launch.
        client.fingerprintKey.isEmpty) {
      return false;
    }
    final checkedKey = '$_ownKeysCheckedPrefix$deviceId';
    try {
      if (await _secureStorage.read(key: checkedKey) != null) return false;
      final response = await client.queryKeys({
        userId: [deviceId],
      });
      final serverKey =
          response.deviceKeys?[userId]?[deviceId]?.keys['ed25519:$deviceId'];
      if (serverKey == null) {
        await encryption.olmManager.uploadKeys(uploadDeviceKeys: true);
      } else if (serverKey != client.fingerprintKey) {
        Logs().w('[KeychainSharing] Device $deviceId identity overwritten');
        return true;
      }
      await _secureStorage.write(key: checkedKey, value: 'true');
    } catch (e, s) {
      Logs().w('[KeychainSharing] Unable to check device identity', e, s);
    }
    return false;
  }

  /// Logs the notification device out and forgets its session.
  static Future<void> logoutNotificationSession(Client client) async {
    final userId = client.userID;
    if (!PlatformInfos.isIOS || userId == null) return;
    // userId is kept: the client may have been cleared while waiting.
    await _logoutNotificationSession(client, userId);
  }

  /// Forgets the session before the network call, so the extension stops
  /// using it even if the logout request hangs.
  static Future<void> _logoutNotificationSession(
    Client client,
    String userId,
  ) async {
    if (!PlatformInfos.isIOS) return;
    try {
      final session = (await read(userId: userId))?.session;
      await delete(userId: userId);
      if (session != null && session.deviceId != client.deviceID) {
        await MatrixApi(
          homeserver: Uri.parse(session.homeserverUrl),
          accessToken: session.accessToken,
          httpClient: client.httpClient,
        ).logout();
      }
    } catch (e, s) {
      Logs().w('[KeychainSharing] Unable to log out notification device', e, s);
    }
  }

  static Future save(KeychainSharingRestoreToken token) => _secureStorage.write(
    key: token.session.userId,
    value: jsonEncode(token.toJson()),
  );

  static Future<KeychainSharingRestoreToken?> read({
    required String userId,
  }) async {
    try {
      final token = await _secureStorage.read(key: userId);
      if (token != null) {
        return KeychainSharingRestoreToken.fromJson(jsonDecode(token));
      }
    } catch (e, s) {
      Logs().wtf('Unable to read token from Secure storage', e, s);
      return null;
    }
    return null;
  }

  static Future delete({required String? userId}) {
    if (userId != null) {
      return _secureStorage.delete(key: userId);
    } else {
      return _secureStorage.deleteAll();
    }
  }
}
