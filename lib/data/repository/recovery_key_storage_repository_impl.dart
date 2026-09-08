import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twake_chat/domain/repository/recovery_key_storage_repository.dart';

/// [RecoveryKeyStorageRepository] backed by [FlutterSecureStorage].
///
/// Keys are namespaced per user so multiple accounts on one device don't
/// collide.
class RecoveryKeyStorageRepositoryImpl implements RecoveryKeyStorageRepository {
  const RecoveryKeyStorageRepositoryImpl(this._storage);

  final FlutterSecureStorage _storage;

  static String _storageKey(String userId) => 'ssss_recovery_key_$userId';

  @override
  Future<void> write({required String userId, required String recoveryKey}) =>
      _storage.write(key: _storageKey(userId), value: recoveryKey);

  @override
  Future<String?> read({required String userId}) =>
      _storage.read(key: _storageKey(userId));
}
