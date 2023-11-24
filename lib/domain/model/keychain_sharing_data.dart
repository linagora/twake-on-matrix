import 'dart:convert';

import 'package:fluffychat/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:json_annotation/json_annotation.dart';

part 'keychain_sharing_data.g.dart';

@JsonSerializable()
class KeychainSharingData {
  static const _keychainKey = 'keychain_sharing_data';

  final String homeserverUrl;
  final String token;
  final String userId;
  final String? deviceId;
  final String? deviceName;
  final String? prevBatch;
  final String? olmAccount;

  KeychainSharingData({
    required this.homeserverUrl,
    required this.token,
    required this.userId,
    this.deviceId,
    this.deviceName,
    this.prevBatch,
    this.olmAccount,
  });

  factory KeychainSharingData.fromJson(Map<String, dynamic> json) =>
      _$KeychainSharingDataFromJson(json);

  Map<String, dynamic> toJson() => _$KeychainSharingDataToJson(this);

  static FlutterSecureStorage get _secureStorage => const FlutterSecureStorage(
        iOptions: IOSOptions(groupId: AppConfig.iOSKeychainSharingId),
      );

  Future saveToKeychain() =>
      _secureStorage.write(key: _keychainKey, value: jsonEncode(toJson()));

  static Future deleteFromKeychain() =>
      _secureStorage.delete(key: _keychainKey);
}
