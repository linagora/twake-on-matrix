import 'dart:async';

import 'package:collection/collection.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';

/// The lists of `app.twake.chat.thread_prefs` this client wrote and the sync
/// did not echo yet, oldest first, as the web keeps them (`#prefsHere` of
/// MatrixAccountPrefs). The newest one is what the user chose, whatever the
/// account data still says; the echo of a write drops it and the ones before
/// it, a list nobody here wrote (another client) drops them all.
class ThreadPrefsLocalWrites {
  /// Saves of the account run one at a time, wherever they come from: the
  /// list a save reads from the server must include the one before it.
  Future<void> _saving = Future.value();

  /// Changes at logout: the saves started before it are stale.
  _SaveEpoch _epoch = _SaveEpoch();

  final List<(Map<String, Object?>, ThreadPrefs)> _pending = [];
  final StreamController<void> _changes = StreamController.broadcast(
    sync: true,
  );

  /// The newest list written here, null once the sync superseded them all.
  ThreadPrefs? get latest => _pending.lastOrNull?.$2;

  /// Told when [latest] may have changed because of a write or a clear.
  Stream<void> get changes => _changes.stream;

  void record(ThreadPrefs prefs) {
    _pending.add((prefs.toAccountData(), prefs));
    _changes.add(null);
  }

  /// The account data now holds [synced]; the caller tells whoever shows
  /// the choices.
  void supersededBy(Map<String, Object?>? synced) {
    final echoed = _pending.lastIndexWhere(
      (write) => const DeepCollectionEquality().equals(write.$1, synced),
    );
    _pending.removeRange(0, echoed < 0 ? _pending.length : echoed + 1);
  }

  /// Runs [save] once the saves before it are over.
  Future<T> serialize<T>(Future<T> Function(ThreadSaveTicket ticket) save) {
    final ticket = ThreadSaveTicket._(this);
    final run = _saving.then((_) => save(ticket));
    _saving = run.then((_) {}, onError: (_) {});
    return run;
  }

  /// Logout: the next account sees none of these, and does not wait for the
  /// saves of the user before.
  void clear() {
    _epoch = _SaveEpoch();
    _saving = Future.value();
    _pending.clear();
    _changes.add(null);
  }
}

class _SaveEpoch {}

/// What a save holds: it records its list only while no logout came since it
/// started.
class ThreadSaveTicket {
  ThreadSaveTicket._(this._writes) : _epoch = _writes._epoch;

  final ThreadPrefsLocalWrites _writes;
  final _SaveEpoch _epoch;

  bool get isStale => !identical(_epoch, _writes._epoch);

  void record(ThreadPrefs prefs) {
    if (!isStale) _writes.record(prefs);
  }
}
