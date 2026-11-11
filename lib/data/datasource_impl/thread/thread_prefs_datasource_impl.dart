import 'dart:async';

import 'package:async/async.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/thread/thread_prefs_datasource.dart';
import 'package:twake_chat/domain/exception/thread/thread_change_exception.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_resolved.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_resolved.dart';
import 'package:twake_chat/domain/model/thread/thread_status.dart';
import 'package:twake_chat/utils/thread_unread/thread_prefs_local_writes.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

/// The save failed and the rule needs no restore: it follows the server.
class _RuleSettled implements Exception {
  const _RuleSettled();
}

class ThreadPrefsDatasourceImpl implements ThreadPrefsDatasource {
  const ThreadPrefsDatasourceImpl(this._client);

  final Client? _client;

  /// Push rule of the web that silences one thread.
  static String _ruleId(ThreadRef thread) =>
      'app.twake.chat.thread.${thread.rootEventId}';

  @override
  Stream<ThreadStatus> watchThread(ThreadRef thread) async* {
    final client = _client;
    if (client == null) throw const ThreadChangeFailedException();
    // The choices stored on the device may be unreadable: none then.
    await client.accountDataLoading?.then((_) {}, onError: _logUnreadable);
    await client.roomsLoading;
    yield _statusOf(client, thread);
    // Whether the user took part is asked of the server once, when unknown
    // (never when the user chose: the choice decides).
    final store = client.threadUnread;
    final lookup = store?.followOnceKnown(thread);
    yield* StreamGroup.merge([
      client.onSync.stream.where((update) => _touches(update, thread)),
      ?store?.localWrites.changes,
      if (lookup != null) Stream.fromFuture(lookup),
    ]).map((_) => _statusOf(client, thread)).distinct();
  }

  void _logUnreadable(Object exception, StackTrace stackTrace) =>
      Logs().w('Unable to read the thread choices', exception, stackTrace);

  bool _touches(SyncUpdate update, ThreadRef thread) =>
      (update.accountData?.any(
            (data) => data.type == threadPrefsAccountDataType,
          ) ??
          false) ||
      update.rooms?.join?[thread.roomId] != null;

  ThreadStatus _statusOf(Client client, ThreadRef thread) {
    final room = client.getRoomById(thread.roomId);
    return ThreadStatus(
      follow:
          client.threadUnread?.followOf(thread) ??
          ThreadFollow.resolve(participated: false),
      isResolved: room?.isThreadResolved(thread.rootEventId) ?? false,
      canResolve: room?.canResolveThreads ?? false,
    );
  }

  @override
  Future<void> saveThreadPref(ThreadRef thread, ThreadPref pref) {
    final client = _client;
    if (client == null) throw const ThreadChangeFailedException();
    final writes = client.threadUnread?.localWrites ?? ThreadPrefsLocalWrites();
    return writes.serialize((ticket) => _save(client, thread, pref, ticket));
  }

  /// The push rule first, then the choice written over the list the server
  /// holds right now: what the device holds may be old, unreadable or the echo
  /// of an earlier write, and another client may have written meanwhile. The
  /// rule follows the final list.
  Future<void> _save(
    Client client,
    ThreadRef thread,
    ThreadPref pref,
    ThreadSaveTicket ticket,
  ) async {
    final known = client.threadUnread?.prefOf(thread);
    try {
      await _setRule(client, thread, muted: pref == ThreadPref.mute);
      final before = await _orRestoreRule(client, thread, known, () {
        _checkNotStale(ticket);
        return _readServerPrefs(client);
      });
      final after = before.withChoice(thread, pref);
      await _orRestoreRule(
        client,
        thread,
        before.of(thread),
        () => _writeList(client, thread, after),
      );
      ticket.record(after);
    } on Exception catch (exception, stackTrace) {
      _fail('saveThreadPref', exception, stackTrace);
    }
  }

  /// A logout came since the save started: it never touches the account of
  /// whoever logged in since.
  void _checkNotStale(ThreadSaveTicket ticket) {
    if (ticket.isStale) throw const _RuleSettled();
  }

  /// A lost answer (timeout, network) tells nothing: the list the server
  /// holds does. With the choice the save went through; else the rule follows
  /// that list, which another client may have written.
  Future<void> _writeList(
    Client client,
    ThreadRef thread,
    ThreadPrefs list,
  ) async {
    try {
      await client.setAccountData(
        _userId(client),
        threadPrefsAccountDataType,
        list.toAccountData(),
      );
    } on MatrixException {
      rethrow;
    } on Exception {
      final now = await _readServerPrefs(client);
      if (now.of(thread) == list.of(thread)) return;
      await _restoreRule(client, thread, now.of(thread));
      throw const _RuleSettled();
    }
  }

  /// Gone with the session (logout): there is no one to save for.
  String _userId(Client client) =>
      client.userID ?? (throw const ThreadChangeFailedException());

  /// A thread list never written is not found: empty.
  Future<ThreadPrefs> _readServerPrefs(Client client) async {
    try {
      final content = await client.getAccountData(
        _userId(client),
        threadPrefsAccountDataType,
      );
      return ThreadPrefs.fromAccountData(content);
    } on MatrixException catch (exception) {
      if (exception.error != MatrixError.M_NOT_FOUND) rethrow;
      return const ThreadPrefs.empty();
    }
  }

  /// When [run] fails the rule goes back to [pref], so the server does not
  /// stay silenced (or not) against every client.
  Future<T> _orRestoreRule<T>(
    Client client,
    ThreadRef thread,
    ThreadPref? pref,
    Future<T> Function() run,
  ) async {
    try {
      return await run();
    } on _RuleSettled {
      rethrow;
    } on Exception {
      await _restoreRule(client, thread, pref);
      rethrow;
    }
  }

  /// Best effort.
  Future<void> _restoreRule(
    Client client,
    ThreadRef thread,
    ThreadPref? before,
  ) async {
    try {
      await _setRule(client, thread, muted: before == ThreadPref.mute);
    } on Exception catch (exception, stackTrace) {
      Logs().e('ThreadPrefsDatasourceImpl::restoreRule', exception, stackTrace);
    }
  }

  Future<void> _setRule(
    Client client,
    ThreadRef thread, {
    required bool muted,
  }) => muted ? _addRule(client, thread) : _removeRule(client, thread);

  Never _fail(String where, Object exception, StackTrace stackTrace) {
    Logs().e('ThreadPrefsDatasourceImpl::$where', exception, stackTrace);
    throw const ThreadChangeFailedException();
  }

  /// Override rule without any action, for the replies of this thread.
  Future<void> _addRule(Client client, ThreadRef thread) => client.setPushRule(
    PushRuleKind.override,
    _ruleId(thread),
    const [],
    conditions: [
      PushCondition(
        kind: 'event_match',
        key: 'room_id',
        pattern: thread.roomId,
      ),
      PushCondition(
        kind: 'event_property_is',
        key: r'content.m\.relates_to.rel_type',
        value: 'm.thread',
      ),
      PushCondition(
        kind: 'event_property_is',
        key: r'content.m\.relates_to.event_id',
        value: thread.rootEventId,
      ),
    ],
  );

  /// A thread that was never muted has no rule: not found is fine.
  Future<void> _removeRule(Client client, ThreadRef thread) async {
    try {
      await client.deletePushRule(PushRuleKind.override, _ruleId(thread));
    } on MatrixException catch (exception) {
      if (exception.error != MatrixError.M_NOT_FOUND) rethrow;
    }
  }

  @override
  Future<void> saveThreadResolved(
    ThreadRef thread, {
    required bool resolved,
  }) async {
    final client = _client;
    if (client == null) throw const ThreadChangeFailedException();
    try {
      await client.setRoomStateWithKey(
        thread.roomId,
        threadResolvedStateType,
        thread.rootEventId,
        {'resolved': resolved},
      );
    } on Exception catch (exception, stackTrace) {
      _fail('saveThreadResolved', exception, stackTrace);
    }
  }
}
