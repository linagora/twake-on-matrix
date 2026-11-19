import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twake_chat/utils/secure_storage.dart';

/// Keeps one random SQLCipher key per database in the secure storage.
class SqliteKeyStore {
  SqliteKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? secureStorage;

  final FlutterSecureStorage _storage;

  static String _entry(String dbName) => 'sqlite_key_$dbName';

  /// The key of [dbName], created (32 random bytes, 64 hex chars) if missing.
  Future<String> keyFor(String dbName) async {
    final existing = await _storage.read(key: _entry(dbName));
    if (existing != null) return existing;
    final random = Random.secure();
    final key = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _storage.write(key: _entry(dbName), value: key);
    return key;
  }

  Future<void> delete(String dbName) => _storage.delete(key: _entry(dbName));
}
