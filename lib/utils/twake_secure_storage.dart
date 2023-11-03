import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TwakeSecureStorage {
  const TwakeSecureStorage();

  final _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<String?> read({required String key}) async {
    return _secureStorage.read(key: key);
  }

  Future<void> write({required String key, required String? value}) async {
    return _secureStorage.write(key: key, value: value);
  }

  Future<void> delete({required String key}) async {
    return _secureStorage.delete(key: key);
  }
}
