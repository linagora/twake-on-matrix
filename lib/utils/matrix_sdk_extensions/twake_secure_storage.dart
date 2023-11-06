import 'dart:async';

import 'package:fluffychat/utils/famedlysdk_store.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';

class TwakeSecureStorage {
  final String _databaseBuiltKey = 'db_built_key';

  TwakeSecureStorage._();

  static final TwakeSecureStorage _instance = TwakeSecureStorage._();

  factory TwakeSecureStorage() => _instance;

  Store? _store;

  Store get store => _store ??= Store();

  final FlutterSecureStorage _flutterSecureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> markDatabaseBuilt() {
    return store.setItemBool(_databaseBuiltKey, true);
  }

  Future<void> markDatabaseNotBuilt() {
    return store.setItemBool(_databaseBuiltKey, false);
  }

  Future<bool> isDatabaseBuilt() async {
    return await store.getItemBool(_databaseBuiltKey, false);
  }

  Future<void> deleteEncryptionKey({
    required String key,
  }) async {
    await markDatabaseNotBuilt();
    await _flutterSecureStorage.delete(key: key);
  }

  Future<void> writeEncryptionKey({
    required String key,
    required String value,
  }) async {
    await _flutterSecureStorage.write(key: key, value: value);
    await markDatabaseBuilt();
  }

  Future<bool> containsEncryptionKey(String key) async {
    final dbBuilt = await isDatabaseBuilt();
    if (dbBuilt) {
      return await _platformContainsEncryptionKey(key);
    } else {
      return false;
    }
  }

  Future<bool> _platformContainsEncryptionKey(String key) async {
    if (PlatformInfos.isIOS) {
      final isAvailable =
          await _flutterSecureStorage.isCupertinoProtectedDataAvailable();
      if (isAvailable) {
        final value = await _flutterSecureStorage.read(key: key);
        return value != null;
      }

      Logs().wtf('Cupertino protected data is not available');
      final completer = Completer<String?>();
      late StreamSubscription<bool> subscription;
      subscription = _flutterSecureStorage
          .onCupertinoProtectedDataAvailabilityChanged
          .listen((protectedDataAvailable) {
        Logs().wtf(
            'onCupertinoProtectedDataAvailabilityChanged: $protectedDataAvailable');
        if (protectedDataAvailable) {
          completer.complete(_flutterSecureStorage.read(key: key));
          subscription.cancel();
        }
      });
      final value = await completer.future;
      Logs().wtf('onCupertinoProtectedDataAvailabilityChanged: done');
      return value != null;
    } else {
      final value = await _flutterSecureStorage.read(key: key);
      return value != null;
    }
  }

  Future<String?> read({
    required String key,
  }) async {
    return _flutterSecureStorage.read(key: key);
  }

  Future<void> write({
    required String key,
    required String? value,
  }) async {
    await _flutterSecureStorage.write(key: key, value: value);
  }

  Future<void> delete({
    required String key,
  }) async {
    await _flutterSecureStorage.delete(key: key);
  }
}
