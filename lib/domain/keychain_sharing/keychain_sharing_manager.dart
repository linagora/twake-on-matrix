import 'dart:convert';

import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_session.dart';
import 'package:twake_chat/utils/platform_infos.dart';
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

  static const String _notificationDeviceName = 'Twake Chat notifications';

  static final Map<String, Future<void>> _notificationSessionSyncs = {};

  /// Gives the iOS notification extension its own device.
  ///
  /// The extension runs its own crypto engine. Sharing the app's device with
  /// it makes it upload its own identity keys over the app's ones and consume
  /// the app's to-device messages. A dedicated device is minted through a
  /// login token (MSC3882) and kept in the shared keychain.
  static Future<void> syncNotificationSession(Client client) {
    final userId = client.userID;
    if (!PlatformInfos.isIOS || !client.isLogged() || userId == null) {
      return Future.value();
    }
    return _notificationSessionSyncs[userId] ??= _syncNotificationSession(
      client,
      userId,
    ).whenComplete(() => _notificationSessionSyncs.remove(userId));
  }

  static Future<void> _syncNotificationSession(
    Client client,
    String userId,
  ) async {
    final homeserver = client.homeserver;
    if (homeserver == null) return;
    try {
      final current = await read(userId: userId);
      final session = current?.session;
      if (session != null &&
          session.deviceId.isNotEmpty &&
          session.deviceId != client.deviceID &&
          session.homeserverUrl == homeserver.toString()) {
        return;
      }
      final loginToken = await client.generateLoginToken();
      final login =
          await MatrixApi(
            homeserver: homeserver,
            httpClient: client.httpClient,
          ).login(
            LoginType.mLoginToken,
            token: loginToken.loginToken,
            initialDeviceDisplayName: _notificationDeviceName,
          );
      await save(
        KeychainSharingRestoreToken(
          session: KeychainSharingSession(
            accessToken: login.accessToken,
            userId: userId,
            deviceId: login.deviceId,
            homeserverUrl: homeserver.toString(),
          ),
        ),
      );
      Logs().i(
        '[KeychainSharing] Notification device ${login.deviceId} for $userId',
      );
    } catch (e, s) {
      // Never fall back to the app's own session: the extension would take
      // over its E2EE identity. Without a session it shows the generic text.
      Logs().w('[KeychainSharing] No notification device for $userId', e, s);
      await delete(userId: userId);
    }
  }

  /// Logs the notification device out and forgets its session.
  static Future<void> logoutNotificationSession(Client client) async {
    final userId = client.userID;
    if (!PlatformInfos.isIOS || userId == null) return;
    try {
      final session = (await read(userId: userId))?.session;
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
    await delete(userId: userId);
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
