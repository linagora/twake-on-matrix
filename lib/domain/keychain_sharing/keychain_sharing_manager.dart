import 'dart:convert';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';

class KeychainSharingManager {
  static FlutterSecureStorage get _secureStorage => const FlutterSecureStorage(
    iOptions: IOSOptions(
      groupId: AppConfig.iOSKeychainSharingId,
      accountName: AppConfig.iOSKeychainSharingAccount,
      synchronizable: true,
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> saveSession({
    required String accessToken,
    required String userId,
    required String homeserverUrl,
    String deviceId = '',
  }) async {
    try {
      final oldToken = await read(userId: userId);
      if (oldToken?.session.accessToken == accessToken &&
          oldToken?.session.userId == userId &&
          oldToken?.session.homeserverUrl == homeserverUrl &&
          oldToken?.session.deviceId == deviceId) {
        return;
      }
      final token = KeychainSharingRestoreToken(
        session: KeychainSharingSession(
          accessToken: accessToken,
          userId: userId,
          deviceId: deviceId,
          homeserverUrl: homeserverUrl,
        ),
      );
      await save(token);
      Logs().d('[KeychainSharing] Saved restore token for $userId');
    } catch (e, s) {
      Logs().w('[KeychainSharing] Unable to save restore token', e, s);
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
