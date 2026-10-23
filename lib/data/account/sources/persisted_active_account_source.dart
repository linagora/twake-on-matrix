import 'package:twake_chat/utils/famedlysdk_store.dart';

/// The user id of the account that was active last, under the key the app
/// already uses.
class PersistedActiveAccountSource {
  static const String key = 'persist_active_account_key';

  PersistedActiveAccountSource(this._store);

  final Store _store;

  Future<String?> read() => _store.getItem(key);

  Future<void> write(String userId) => _store.setItem(key, userId);

  Future<void> delete() => _store.deleteItem(key);
}
