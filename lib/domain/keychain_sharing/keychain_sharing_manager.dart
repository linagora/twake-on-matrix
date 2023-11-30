import 'dart:convert';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeychainSharingManager {
  static FlutterSecureStorage get _secureStorage => const FlutterSecureStorage(
        iOptions: IOSOptions(
          groupId: AppConfig.iOSKeychainSharingId,
          accountName: AppConfig.iOSKeychainSharingAccount,
        ),
      );

  static Future save(KeychainSharingRestoreToken token) => _secureStorage.write(
        key: token.session.userId,
        value: jsonEncode(token.toJson()),
      );

  static Future delete({required String? userId}) {
    if (userId != null) {
      return _secureStorage.delete(key: userId);
    } else {
      return _secureStorage.deleteAll();
    }
  }
}
