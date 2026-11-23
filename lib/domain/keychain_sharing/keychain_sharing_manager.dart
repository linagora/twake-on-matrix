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
    } on Exception catch (e, s) {
      Logs().wtf('[KeychainSharing] Unable to save HTTP session', e, s);
    }
  }

  static Future<void> deleteHttpSession(String userId) async {
    if (!PlatformInfos.isIOS) return;
    try {
      await _secureStorage.delete(key: '$_httpSessionPrefix$userId');
    } on Exception catch (e, s) {
      Logs().wtf('[KeychainSharing] Unable to delete HTTP session', e, s);
    }
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

  /// Logs out the dedicated notification device that older versions created
  /// through a second login, then forgets its session. Unlike
  /// [logoutNotificationSession], the entry stays when the request fails, so
  /// the next launch tries again.
  static Future<void> removeDedicatedNotificationDevice(Client client) async {
    final userId = client.userID;
    if (!PlatformInfos.isIOS || userId == null) return;
    try {
      final token = await read(userId: userId);
      if (token?.dedicated != true) return;
      final session = token!.session;
      if (session.deviceId != client.deviceID) {
        try {
          await MatrixApi(
            homeserver: Uri.parse(session.homeserverUrl),
            accessToken: session.accessToken,
            httpClient: client.httpClient,
          ).logout();
        } on MatrixException catch (e) {
          // Already revoked: only the entry is left to remove.
          if (e.error != MatrixError.M_UNKNOWN_TOKEN) rethrow;
        }
      }
      await delete(userId: userId);
      Logs().i('[KeychainSharing] Removed the notification device');
    } on Exception catch (e, s) {
      Logs().w('[KeychainSharing] Unable to remove notification device', e, s);
    }
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
