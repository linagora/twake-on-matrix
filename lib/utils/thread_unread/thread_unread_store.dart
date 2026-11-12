import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/data/thread/models/thread_unread_snapshot_json.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_relation_extension.dart';
import 'package:twake_chat/utils/thread_unread/thread_prefs_local_writes.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';

/// A [ChangeNotifier] that its owner tells from outside.
class _Signal extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Marks the generation of the store: [ThreadUnreadStore.clear] starts a new
/// one, so a lookup started before it must not bring a follow back.
class _LookupEpoch {}

/// Unread counters of the threads: the SDK keeps only the counters of the
/// room. Filled from the raw sync response, and saved per account so a cold
/// start (or a web reload) shows them before the next sync carries them.
// TODO: [transitional] #3599
class ThreadUnreadStore extends ChangeNotifier {
  ThreadUnreadStore({required Client client, ThreadPrefsLocalWrites? writes})
    : _client = client,
      localWrites = writes ?? ThreadPrefsLocalWrites() {
    // What the user just chose here applies at once, without a sync.
    localWrites.changes.listen((_) => _prefsChanged());
  }

  final Client _client;

  /// The choices this client wrote, until the sync echoes them.
  final ThreadPrefsLocalWrites localWrites;

  final Map<String, Map<String, ThreadCounts>> _counts = {};
  final Set<ThreadRef> _followed = {};

  /// Lookups running, by thread: awaited by whoever needs the answer.
  final Map<ThreadRef, Future<void>> _resolving = {};

  /// Threads the server answered "not participated" for: asked once, the
  /// answer stands until the user writes in the thread (markFollowed).
  final Set<ThreadRef> _notFollowed = {};
  final Map<ThreadRef, DateTime> _activity = {};
  final Map<String, int> _badges = {};

  /// Timestamp of the newest main-timeline message of others seen live, per
  /// room. Memory only: a cold start has no such message until one arrives.
  final Map<String, int> _newestMainTs = {};

  /// Ids of the thread replies seen live, per room: once deleted, a reply
  /// loses its `m.relates_to` and only this tells it was in a thread.
  final Map<String, Set<String>> _threadReplyIds = {};
  final Queue<ReplyRef> _threadReplyOrder = Queue();

  /// The newest reply seen live in each thread. Memory only.
  final Map<ThreadRef, Event> _latestReplies = {};

  // A count cap for the account, not a per-room one.
  static const int _maxThreadReplyIds = 4000;

  /// Follow lookups run at most this many at a time (one server request each).
  static const int _maxLookupsInFlight = 3;
  int _lookupsInFlight = 0;
  final Queue<Completer<void>> _lookupWaiters = Queue();

  /// Replaced by [clear]: a lookup started before it is stale.
  _LookupEpoch _epoch = _LookupEpoch();

  String get _prefsKey => 'thread_unread_${_client.clientName}';

  /// Rooms the sync says the user left lose their counters and follow state,
  /// so a later join starts clean.
  void apply(SyncThreadUpdate update) {
    var changed = false;
    for (final room in update.leftRooms) {
      changed |= _forgetRoom(room);
    }
    for (final room in update.rooms) {
      changed |= _applyRoomCounts(room);
    }
    if (!changed) return;
    notifyListeners();
    if (update.hasLeft) {
      _persistNow();
    } else {
      _persist();
    }
  }

  /// True when the room held counters or follows.
  bool _forgetRoom(RoomId room) {
    final hadCounts = _counts.remove(room.value) != null;
    final hadFollow = _followed.length;
    _followed.removeWhere(room.owns);
    _notFollowed.removeWhere(room.owns);
    _activity.removeWhere((thread, _) => room.owns(thread));
    _badges.remove(room.value);
    _newestMainTs.remove(room.value);
    _threadReplyIds.remove(room.value);
    _threadReplyOrder.removeWhere(room.ownsReply);
    _latestReplies.removeWhere((thread, _) => room.owns(thread));
    return hadCounts || hadFollow != _followed.length;
  }

  /// True when the counters of the room changed.
  bool _applyRoomCounts(RoomCounts room) {
    final before = _counts[room.id.value] ?? const <String, ThreadCounts>{};
    for (final thread in room.threads.entries) {
      final previous = before[thread.key]?.notificationCount ?? 0;
      if (thread.value.notificationCount > previous) {
        final ref = ThreadRef(room.id.value, thread.key);
        _activity[ref] = DateTime.now();
        _resolveFollowed(ref);
      }
    }
    if (mapEquals(before, room.threads)) return false;
    _counts[room.id.value] = room.threads;
    _refreshBadge(room.id);
    return true;
  }

  /// The user wrote in this thread: it is followed from now on.
  void markFollowed(ThreadRef thread) {
    if (!_followed.add(thread)) return;
    _refreshBadge(RoomId(thread.roomId));
    notifyListeners();
    _persist();
  }

  /// The one rule: an explicit choice wins over taking part; a muted thread
  /// stays followed.
  ThreadFollow followOf(ThreadRef thread) => ThreadFollow.resolve(
    participated: _followed.contains(thread),
    pref: prefOf(thread),
  );

  bool isFollowed(ThreadRef thread) => followOf(thread).isFollowing;

  bool isMuted(ThreadRef thread) => followOf(thread).isMuted;

  /// The explicit choice of the user about the thread, if any.
  ThreadPref? prefOf(ThreadRef thread) => _prefs.of(thread);

  /// What the user chose here and the sync did not echo yet, else the
  /// choices of `app.twake.chat.thread_prefs` read from the account data of
  /// the client; parsed again only when its content was replaced.
  ThreadPrefs get _prefs => localWrites.latest ?? _syncedPrefs;

  ThreadPrefs get _syncedPrefs {
    final content = _client.accountData[threadPrefsAccountDataType]?.content;
    if (!identical(content, _prefsContent)) {
      _prefsContent = content;
      _parsedPrefs = ThreadPrefs.fromAccountData(content);
    }
    return _parsedPrefs;
  }

  Map<String, Object?>? _prefsContent;
  ThreadPrefs _parsedPrefs = const ThreadPrefs.empty();

  /// What a sync may have changed: when the choices were replaced, the
  /// badges are computed again and the listeners told.
  void refreshPrefs() {
    final content = _client.accountData[threadPrefsAccountDataType]?.content;
    if (identical(content, _announcedPrefsContent)) return;
    _announcedPrefsContent = content;
    _prefsChanged();
  }

  void _prefsChanged() {
    _counts.keys.map(RoomId.new).forEach(_refreshBadge);
    notifyListeners();
  }

  Map<String, Object?>? _announcedPrefsContent;

  final _Signal _resolvedChanges = _Signal();

  /// Told when the resolved state of a thread changed: only the cards redraw,
  /// no badge depends on it.
  Listenable get resolvedChanges => _resolvedChanges;

  void refreshResolved() => _resolvedChanges.notify();

  /// A thread reply of the live timeline (any sender); the oldest ids go
  /// when the account holds more than [_maxThreadReplyIds].
  /// A reply the user sent (synced, live or from a page of the thread) makes
  /// the thread followed.
  void rememberThreadReply(Event reply) {
    _followIfOwnReply(reply);
    _rememberLatestReply(reply);
    if (!_addThreadReplyId(ReplyRef(reply.room.id, reply.eventId))) return;
    while (_threadReplyOrder.length > _maxThreadReplyIds) {
      final oldest = _threadReplyOrder.removeFirst();
      _threadReplyIds[oldest.roomId]?.remove(oldest.eventId);
    }
    _persist();
  }

  void _rememberLatestReply(Event reply) {
    final rootId = reply.threadRootId;
    if (rootId == null || !reply.status.isSynced) return;
    final thread = ThreadRef(reply.room.id, rootId);
    final known = _latestReplies[thread];
    if (known == null || !reply.originServerTs.isBefore(known.originServerTs)) {
      _latestReplies[thread] = reply;
    }
  }

  /// The newest reply of the thread seen live, if any.
  Event? latestReplyOf(ThreadRef thread) => _latestReplies[thread];

  /// The threads the user follows and did not mute.
  Iterable<ThreadRef> get followedThreads => {
    ..._followed,
    ..._prefs.threads,
  }.where((thread) => isFollowed(thread) && !isMuted(thread));

  void _followIfOwnReply(Event reply) {
    final rootId = reply.threadRootId;
    if (rootId == null || reply.senderId != _client.userID) return;
    if (reply.status.isSynced) markFollowed(ThreadRef(reply.room.id, rootId));
  }

  /// A message of the main timeline seen live (any sender but the user): the
  /// room has new messages when the newest one is newer than the read
  /// receipt, even if a thread reply came after it.
  void rememberMainTimelineEvent(Event event) {
    if (event.senderId == _client.userID) return;
    if (!_client.roomPreviewLastEvents.contains(event.type)) return;
    final room = event.room;
    final known = knownThreadReplyIds(room);
    if (ThreadRules.newestMainTimelineEvent([
          event,
        ], knownThreadReplyIds: known) ==
        null) {
      return;
    }
    final ts = event.originServerTs.millisecondsSinceEpoch;
    if (ts > (_newestMainTs[room.id] ?? 0)) _newestMainTs[room.id] = ts;
  }

  int? newestMainMessageTs(Room room) => _newestMainTs[room.id];

  Set<String> knownThreadReplyIds(Room room) =>
      _threadReplyIds[room.id] ?? const {};

  bool _addThreadReplyId(ReplyRef reply) {
    final ids = _threadReplyIds.putIfAbsent(reply.roomId, () => {});
    if (!ids.add(reply.eventId)) return false;
    _threadReplyOrder.add(reply);
    return true;
  }

  /// Loads what [_persist] saved; a sync that came first wins.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      _restoreFrom(
        threadUnreadSnapshotFromJson(jsonDecode(raw) as Map<String, Object?>),
      );
      notifyListeners();
    } catch (e, s) {
      Logs().w('Unable to restore the thread counters', e, s);
    }
  }

  void _restoreFrom(ThreadUnreadSnapshot saved) {
    for (final room in saved.counts.entries) {
      _counts.putIfAbsent(room.key, () => room.value);
    }
    _followed.addAll(saved.followed);
    _restoreReplyIds(saved);
    for (final roomId in _counts.keys.toList()) {
      _refreshBadge(RoomId(roomId));
    }
  }

  void _restoreReplyIds(ThreadUnreadSnapshot saved) {
    for (final room in saved.replies.entries) {
      for (final id in room.value) {
        _addThreadReplyId(ReplyRef(room.key, id));
      }
    }
  }

  /// Logout: forgets everything, in memory and saved, also when a save is
  /// still running (it runs first, then the key goes).
  Future<void> clear() async {
    _epoch = _LookupEpoch();
    _persistTimer?.cancel();
    _persistTimer = null;
    _dirty = false;
    _counts.clear();
    _followed.clear();
    _notFollowed.clear();
    _activity.clear();
    _badges.clear();
    _newestMainTs.clear();
    _threadReplyIds.clear();
    _threadReplyOrder.clear();
    _latestReplies.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e, s) {
      Logs().w('Unable to clear the thread counters', e, s);
    }
  }

  Timer? _persistTimer;
  bool _dirty = false;

  // Fixed window: a save per change is what a catch-up sync broke.
  static const Duration _persistWindow = Duration(seconds: 1);

  /// Saves in a zero-delay task (a burst of calls in a row is one save),
  /// then at most once per [_persistWindow].
  void _persist() {
    _dirty = true;
    if (_persistTimer != null) return;
    _persistTimer = Timer(Duration.zero, () {
      _dirty = false;
      _persistTimer = Timer(_persistWindow, () {
        _persistTimer = null;
        if (_dirty) _persist();
      });
      _save();
    });
  }

  /// Leaving a room is rare and must not wait: saves now.
  void _persistNow() {
    _persistTimer?.cancel();
    _persistTimer = null;
    _dirty = false;
    _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_snapshot.toJson()));
    } catch (e, s) {
      Logs().w('Unable to save the thread counters', e, s);
    }
  }

  ThreadUnreadSnapshot get _snapshot => ThreadUnreadSnapshot(
    counts: _counts,
    followed: _followed,
    replies: _threadReplyIds,
  );

  void _refreshBadge(RoomId room) {
    _badges[room.value] = roomUnreadBadge(
      mainNotificationCount: 0,
      threads: _threadsIn(room),
    );
  }

  /// Badge of the threads of the room (without its main timeline).
  int badgeOf(Room room) => _badges[room.id] ?? 0;

  /// Like the web: a muted thread has none.
  int unreadCount(ThreadRef thread) => isMuted(thread)
      ? 0
      : _counts[thread.roomId]?[thread.rootEventId]?.notificationCount ?? 0;

  List<ThreadUnread> threadsOf(Room room) => _threadsIn(RoomId(room.id));

  List<ThreadUnread> _threadsIn(RoomId room) => [
    for (final entry
        in (_counts[room.value] ?? const <String, ThreadCounts>{}).entries)
      _unreadOf(ThreadRef(room.value, entry.key), entry.value),
  ];

  ThreadUnread _unreadOf(ThreadRef thread, ThreadCounts counts) => ThreadUnread(
    rootEventId: thread.rootEventId,
    notificationCount: counts.notificationCount,
    highlightCount: counts.highlightCount,
    followed: isFollowed(thread),
    muted: isMuted(thread),
    lastActivity: _activity[thread],
  );

  /// Participation as the server tells it: the user wrote the root or
  /// replied (the explicit follow choice applies on top, see [isFollowed]). The root stored
  /// in the database keeps the aggregate of the day it was stored, so unless
  /// it already says "participated" the server is asked. A "no" is kept (the
  /// user's own event turns it into a follow); a failed call is asked again
  /// on the next increase of the counter.
  Future<void> _resolveFollowed(ThreadRef thread) {
    final running = _resolving[thread];
    if (running != null) return running;
    // The choice of the user decides alone: nothing to ask the server.
    if (prefOf(thread) != null || _isSettled(thread)) return Future.value();
    return _resolving[thread] = _runLookup(thread);
  }

  Future<void> _runLookup(ThreadRef thread) async {
    final epoch = _epoch;
    await _acquireLookupSlot();
    try {
      await _lookupAndRecord(thread, epoch);
    } catch (e, s) {
      Logs().w('Unable to tell if the thread is followed', e, s);
    } finally {
      _releaseLookupSlot();
      _resolving.remove(thread);
    }
  }

  /// Whether the user follows the thread, once it is known: at once when it
  /// is, else after the lookup (started when none runs). Null when the
  /// lookup could not tell; nothing is thrown.
  Future<bool?> followOnceKnown(ThreadRef thread) async {
    await _resolveFollowed(thread);
    if (_followed.contains(thread)) return true;
    return _notFollowed.contains(thread) ? false : null;
  }

  /// A lookup runs for a thread of the room with unread replies: its badge
  /// is 0 because the answer is unknown, not because the replies were read.
  bool hasPendingFollowLookup(Room room) => _resolving.keys.any(
    (thread) => thread.roomId == room.id && unreadCount(thread) > 0,
  );

  bool _isSettled(ThreadRef thread) =>
      _followed.contains(thread) || _notFollowed.contains(thread);

  bool _isStale(_LookupEpoch epoch) => !identical(epoch, _epoch);

  Future<void> _lookupAndRecord(ThreadRef thread, _LookupEpoch epoch) async {
    if (_isStale(epoch)) return;
    final follow = await _lookupFollow(thread, epoch);
    if (follow == null || _isStale(epoch)) return;
    if (follow) {
      markFollowed(thread);
    } else {
      _notFollowed.add(thread);
    }
  }

  /// Local store first (no network), then at most one server request; null
  /// when the account was cleared meanwhile.
  Future<bool?> _lookupFollow(ThreadRef thread, _LookupEpoch epoch) async {
    final stored = await _storedRoot(thread);
    if (_isStale(epoch)) return null;
    if (stored != null && _isParticipant(stored)) return true;
    final fresh = await _client.getOneRoomEvent(
      thread.roomId,
      thread.rootEventId,
    );
    return _isParticipant(fresh);
  }

  Future<Event?> _storedRoot(ThreadRef thread) async {
    final room = _client.getRoomById(thread.roomId);
    if (room == null) return null;
    return _client.database.getEventById(thread.rootEventId, room);
  }

  /// The root of a thread, for its last reply: the local database first,
  /// the server when the stored root holds no thread aggregate. Asks the
  /// server like the follow lookups do, at most [_maxLookupsInFlight] at a
  /// time. Null when the room is unknown.
  Future<Event?> threadRoot(ThreadRef thread) async {
    final room = _client.getRoomById(thread.roomId);
    if (room == null) return null;
    await _acquireLookupSlot();
    try {
      final stored = await _storedRoot(thread);
      if (stored != null && _hasThreadAggregate(stored)) return stored;
      final fresh = await _client.getOneRoomEvent(
        thread.roomId,
        thread.rootEventId,
      );
      return Event.fromMatrixEvent(fresh, room);
    } finally {
      _releaseLookupSlot();
    }
  }

  bool _hasThreadAggregate(MatrixEvent event) =>
      (event.unsigned?['m.relations'] as Map?)?['m.thread'] != null;

  bool _isParticipant(MatrixEvent event) =>
      event.senderId == _client.userID || _participated(event) == true;

  Future<void> _acquireLookupSlot() {
    if (_lookupsInFlight < _maxLookupsInFlight) {
      _lookupsInFlight++;
      return Future.value();
    }
    final waiter = Completer<void>();
    _lookupWaiters.add(waiter);
    return waiter.future;
  }

  /// Hands the slot to the next waiter, or frees it.
  void _releaseLookupSlot() {
    if (_lookupWaiters.isEmpty) {
      _lookupsInFlight--;
    } else {
      _lookupWaiters.removeFirst().complete();
    }
  }

  bool? _participated(MatrixEvent event) =>
      ((event.unsigned?['m.relations'] as Map?)?['m.thread']
              as Map?)?['current_user_participated']
          as bool?;
}

/// The one way to reach the thread counters of an account; null for a client
/// that keeps none.
extension ThreadUnreadClientExtension on Client {
  ThreadUnreadStore? get threadUnread {
    final Object self = this;
    return self is ThreadUnreadStoreOwner ? self.threadUnread : null;
  }
}

extension ThreadUnreadRoomExtension on Room {
  /// Room badge: main timeline, followed threads and mentions of any thread.
  int get unreadBadgeCount {
    if (!AppConfig.threadsEnabled) return notificationCount;
    final store = client.threadUnread;
    return notificationCount + (store?.badgeOf(this) ?? 0);
  }
}

extension RoomPendingNotification on Room {
  /// Nothing of the room is waiting in a notification: safe to clear them.
  /// A left room keeps the unread count it had when it was left (synced with
  /// `includeLeave`), so it never blocks. A badge of 0 while a follow lookup
  /// runs is unknown, not read.
  bool get hasNoPendingNotification =>
      membership == Membership.leave ||
      (unreadBadgeCount == 0 &&
          client.threadUnread?.hasPendingFollowLookup(this) != true);
}

/// One decision for every consumer of the room counters: the server stops
/// counting thread notifications in the room's own counters.
extension RoomUnreadWithThreads on Room {
  bool get isUnreadWithThreads => isUnread || unreadBadgeCount > 0;

  bool get isUnreadOrInvitedWithThreads =>
      isUnreadOrInvited || unreadBadgeCount > 0;

  /// Mentions of the room and of any of its threads.
  int get highlightCountWithThreads {
    if (!AppConfig.threadsEnabled) return highlightCount;
    final store = client.threadUnread;
    return highlightCount +
        (store?.threadsOf(this).fold<int>(0, (n, t) => n + t.mentionCount) ??
            0);
  }
}

extension MarkRoomAndThreadsRead on Room {
  /// Stored events, newest first, paged: the newest ones can all be replies
  /// of a busy thread. It gives up after [_mainEventSearchLimit].
  Future<Event?> _newestMainTimelineEvent() async {
    const pageSize = 50;
    for (var start = 0; start < _mainEventSearchLimit; start += pageSize) {
      final page = await client.database.getEventList(
        this,
        start: start,
        limit: pageSize,
      );
      final found = ThreadRules.newestMainTimelineEvent(
        page,
        knownThreadReplyIds:
            client.threadUnread?.knownThreadReplyIds(this) ?? const {},
      );
      if (found != null || page.length < pageSize) return found;
    }
    return null;
  }

  /// The newest event the server has: a thread reply counts, a local echo
  /// still sending does not.
  Future<Event?> _newestSyncedEvent() async {
    final page = await client.database.getEventList(this, start: 0, limit: 50);
    return page.firstWhereOrNull((e) => e.status.isSynced);
  }

  /// "Mark as read": ONE unthreaded receipt on the newest event of the room
  /// (MSC3771: it covers the main timeline and every thread up to it);
  /// `m.fully_read` stays on the newest main timeline event.
  Future<void> markRoomAndAllThreadsRead() async {
    final newest = await _newestSyncedEvent();
    if (newest == null) return;
    final main = await _newestMainTimelineEvent();
    final public = client.receiptsPublicByDefault;
    await client.setReadMarker(
      id,
      mFullyRead: main?.eventId,
      mRead: public ? newest.eventId : null,
      mReadPrivate: public ? null : newest.eventId,
    );
  }
}

const int _mainEventSearchLimit = 300;

/// A client that keeps the thread counters ([TwakeClient]).
abstract interface class ThreadUnreadStoreOwner {
  ThreadUnreadStore get threadUnread;
}
