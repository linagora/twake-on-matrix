import 'dart:convert';

import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/utils/famedlysdk_store.dart';

/// The ids of the accounts whose removal did not finish, so the app retries
/// them after a restart. Only client names are stored. The same source keeps
/// the accounts whose pusher deletion failed, under [pushKey], and the
/// candidates of a rolled-back login whose storage is still there, under
/// [candidateKey].
class PendingRemovalsSource {
  static const String key = 'pending_account_removals';
  static const String pushKey = 'pending_pusher_removals';
  static const String candidateKey = 'pending_candidate_discards';

  PendingRemovalsSource(this._store, {this.storeKey = key});

  final Store _store;
  final String storeKey;

  Future<Set<String>> read() async {
    final raw = await _store.getItem(storeKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } on FormatException catch (e, s) {
      return _dropUnreadable(e, s);
    } on TypeError catch (e, s) {
      return _dropUnreadable(e, s);
    }
  }

  /// A value that cannot be decoded would make every later read throw, and with
  /// it every mark and clear of the ids: it is dropped.
  Future<Set<String>> _dropUnreadable(Object error, StackTrace stack) async {
    Logs().w(
      'Dropping the unreadable ids stored under $storeKey',
      error,
      stack,
    );
    await _store.deleteItem(storeKey);
    return {};
  }

  Future<void> write(Set<String> ids) => ids.isEmpty
      ? _store.deleteItem(storeKey)
      : _store.setItem(storeKey, jsonEncode(ids.toList()));
}
