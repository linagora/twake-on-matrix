import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';
import 'package:twake_chat/domain/usecase/room/get_thread_replies_interactor.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';

/// Unread counters of the threads: the SDK keeps only the counters of the
/// room. Filled from the raw sync response, and saved per account so a cold
/// start (or a web reload) shows them before the next sync carries them.
class ThreadUnreadStore extends ChangeNotifier {
  ThreadUnreadStore({required Client client}) : _client = client;

  final Client _client;

  final Map<String, Map<String, ThreadCounts>> _counts = {};
  final Set<String> _followed = {};
  final Set<String> _resolving = {};

  /// Threads the server answered "not participated" for: asked once, the
  /// answer stands until the user writes in the thread (markFollowed).
  final Set<String> _notFollowed = {};
  final Map<String, DateTime> _activity = {};
  final Map<String, int> _badges = {};

  /// Ids of the thread replies seen live, per room: once deleted, a reply
  /// loses its `m.relates_to` and only this tells it was in a thread.
  final Map<String, Set<String>> _threadReplyIds = {};
  final Queue<(String, String)> _threadReplyOrder = Queue();

  // ponytail: a count cap for the account, not a per-room one.
  static const int _maxThreadReplyIds = 4000;

  /// Follow lookups run at most this many at a time (one server request each).
  static const int _maxLookupsInFlight = 3;
  int _lookupsInFlight = 0;
  final Queue<Completer<void>> _lookupWaiters = Queue();

  /// Bumped by [clear]: a lookup started before it must not bring a follow back.
  int _epoch = 0;

  String get _prefsKey => 'thread_unread_${_client.clientName}';

  /// [leftRoomIds]: rooms the sync says the user left; their counters and
  /// follow state go, so a later join starts clean.
  void apply(
    Map<String, Map<String, ThreadCounts>> roomCounts, {
    Iterable<String> leftRoomIds = const [],
  }) {
    var changed = false;
    for (final roomId in leftRoomIds) {
      changed |= _forgetRoom(roomId);
    }
    for (final entry in roomCounts.entries) {
      changed |= _applyRoomCounts(entry.key, entry.value);
    }
    if (!changed) return;
    notifyListeners();
    _persist(immediately: leftRoomIds.isNotEmpty);
  }

  /// True when the room held counters or follows.
  bool _forgetRoom(String roomId) {
    final hadCounts = _counts.remove(roomId) != null;
    final prefix = '$roomId|';
    final hadFollow = _followed.length;
    _followed.removeWhere((key) => key.startsWith(prefix));
    _notFollowed.removeWhere((key) => key.startsWith(prefix));
    _activity.removeWhere((key, _) => key.startsWith(prefix));
    _badges.remove(roomId);
    _threadReplyIds.remove(roomId);
    _threadReplyOrder.removeWhere((e) => e.$1 == roomId);
    return hadCounts || hadFollow != _followed.length;
  }

  /// True when the counters of the room changed.
  bool _applyRoomCounts(String roomId, Map<String, ThreadCounts> counts) {
    final before = _counts[roomId] ?? const <String, ThreadCounts>{};
    for (final thread in counts.entries) {
      final previous = before[thread.key]?.notificationCount ?? 0;
      if (thread.value.notificationCount > previous) {
        final ref = ThreadRef(roomId, thread.key);
        _activity[ref.key] = DateTime.now();
        _resolveFollowed(ref);
      }
    }
    if (mapEquals(before, counts)) return false;
    _counts[roomId] = counts;
    _refreshBadge(roomId);
    return true;
  }

  /// The user wrote in this thread: it is followed from now on.
  void markFollowed(String roomId, String rootId) =>
      _markFollowed(ThreadRef(roomId, rootId));

  void _markFollowed(ThreadRef thread) {
    if (!_followed.add(thread.key)) return;
    _refreshBadge(thread.roomId);
    notifyListeners();
    _persist();
  }

  bool isFollowed(String roomId, String rootId) =>
      _followed.contains(ThreadRef(roomId, rootId).key);

  /// A thread reply of the live timeline (any sender); the oldest ids go
  /// when the account holds more than [_maxThreadReplyIds].
  void rememberThreadReply(String roomId, String eventId) {
    if (!_addThreadReplyId(roomId, eventId)) return;
    while (_threadReplyOrder.length > _maxThreadReplyIds) {
      final oldest = _threadReplyOrder.removeFirst();
      _threadReplyIds[oldest.$1]?.remove(oldest.$2);
    }
    _persist();
  }

  Set<String> knownThreadReplyIds(String roomId) =>
      _threadReplyIds[roomId] ?? const {};

  bool _addThreadReplyId(String roomId, String eventId) {
    final ids = _threadReplyIds.putIfAbsent(roomId, () => {});
    if (!ids.add(eventId)) return false;
    _threadReplyOrder.add((roomId, eventId));
    return true;
  }

  /// Loads what [_persist] saved; a sync that came first wins.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      _restoreFrom(jsonDecode(raw) as Map<String, Object?>);
      notifyListeners();
    } catch (e, s) {
      Logs().w('Unable to restore the thread counters', e, s);
    }
  }

  void _restoreFrom(Map<String, Object?> json) {
    _restoreCounts(json['counts'] as Map? ?? const {});
    _followed.addAll((json['followed'] as List? ?? const []).cast<String>());
    _restoreReplyIds(json['replies'] as Map? ?? const {});
    _counts.keys.toList().forEach(_refreshBadge);
  }

  void _restoreCounts(Map saved) {
    for (final room in saved.entries) {
      _counts.putIfAbsent(room.key as String, () => _decodeThreads(room.value));
    }
  }

  Map<String, ThreadCounts> _decodeThreads(Object? saved) => {
    for (final thread in (saved as Map).entries)
      thread.key as String: (
        notificationCount: (thread.value as List)[0] as int,
        highlightCount: (thread.value as List)[1] as int,
      ),
  };

  void _restoreReplyIds(Map saved) {
    for (final room in saved.entries) {
      for (final id in (room.value as List).cast<String>()) {
        _addThreadReplyId(room.key as String, id);
      }
    }
  }

  /// Logout: forgets everything, in memory and saved, also when a save is
  /// still running (it runs first, then the key goes).
  Future<void> clear() async {
    _epoch++;
    _persistTimer?.cancel();
    _persistTimer = null;
    _dirty = false;
    _counts.clear();
    _followed.clear();
    _notFollowed.clear();
    _activity.clear();
    _badges.clear();
    _threadReplyIds.clear();
    _threadReplyOrder.clear();
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

  // ponytail: fixed window; a save per change is what a catch-up sync broke.
  static const Duration _persistWindow = Duration(seconds: 1);

  /// Saves in a zero-delay task (a burst of calls in a row is one save),
  /// then at most once per [_persistWindow]. Leaving a room is rare and must
  /// not wait: [immediately] saves now.
  void _persist({bool immediately = false}) {
    if (immediately) {
      _persistTimer?.cancel();
      _persistTimer = null;
      _dirty = false;
      _save();
      return;
    }
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

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_toJson()));
    } catch (e, s) {
      Logs().w('Unable to save the thread counters', e, s);
    }
  }

  Map<String, Object?> _toJson() => {
    'counts': {
      for (final room in _counts.entries)
        room.key: {
          for (final thread in room.value.entries)
            thread.key: [
              thread.value.notificationCount,
              thread.value.highlightCount,
            ],
        },
    },
    'followed': _followed.toList(),
    'replies': {
      for (final room in _threadReplyIds.entries)
        if (room.value.isNotEmpty) room.key: room.value.toList(),
    },
  };

  void _refreshBadge(String roomId) {
    _badges[roomId] = roomUnreadBadge(
      mainNotificationCount: 0,
      threads: threadsOf(roomId),
    );
  }

  /// Badge of the threads of the room (without its main timeline).
  int badgeOf(String roomId) => _badges[roomId] ?? 0;

  int unreadCount(String roomId, String rootId) =>
      _counts[roomId]?[rootId]?.notificationCount ?? 0;

  List<ThreadUnread> threadsOf(String roomId) => [
    for (final entry
        in (_counts[roomId] ?? const <String, ThreadCounts>{}).entries)
      ThreadUnread(
        rootEventId: entry.key,
        notificationCount: entry.value.notificationCount,
        highlightCount: entry.value.highlightCount,
        followed: _followed.contains(ThreadRef(roomId, entry.key).key),
        lastActivity: _activity[ThreadRef(roomId, entry.key).key],
      ),
  ];

  /// Participation as the server tells it: the user wrote the root or
  /// replied (P1; the explicit follow choice comes with P2). The root stored
  /// in the database keeps the aggregate of the day it was stored, so unless
  /// it already says "participated" the server is asked. A "no" is kept (the
  /// user's own event turns it into a follow); a failed call is asked again
  /// on the next increase of the counter.
  Future<void> _resolveFollowed(ThreadRef thread) async {
    if (!_claimLookup(thread)) return;
    final epoch = _epoch;
    await _acquireLookupSlot();
    try {
      await _lookupAndRecord(thread, epoch);
    } catch (e, s) {
      Logs().w('Unable to tell if the thread is followed', e, s);
    } finally {
      _releaseLookupSlot();
      _resolving.remove(thread.key);
    }
  }

  /// True when no answer is known and no lookup runs for the thread.
  bool _claimLookup(ThreadRef thread) =>
      !_isSettled(thread) && _resolving.add(thread.key);

  bool _isSettled(ThreadRef thread) =>
      _followed.contains(thread.key) || _notFollowed.contains(thread.key);

  Future<void> _lookupAndRecord(ThreadRef thread, int epoch) async {
    if (epoch != _epoch) return;
    final follow = await _lookupFollow(thread, epoch);
    if (follow == null || epoch != _epoch) return;
    if (follow) {
      _markFollowed(thread);
    } else {
      _notFollowed.add(thread.key);
    }
  }

  /// Local store first (no network), then at most one server request; null
  /// when the account was cleared meanwhile.
  Future<bool?> _lookupFollow(ThreadRef thread, int epoch) async {
    final stored = await _storedRoot(thread);
    if (epoch != _epoch) return null;
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

  bool _isParticipant(MatrixEvent event) =>
      event.senderId == _client.userID || _participated(event.unsigned) == true;

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

  bool? _participated(Map<String, Object?>? unsigned) =>
      ((unsigned?['m.relations'] as Map?)?['m.thread']
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
    final store = client.threadUnread;
    return notificationCount + (store?.badgeOf(id) ?? 0);
  }
}

/// One decision for every consumer of the room counters: the server stops
/// counting thread notifications in the room's own counters.
extension RoomUnreadWithThreads on Room {
  bool get isUnreadWithThreads => isUnread || unreadBadgeCount > 0;

  bool get isUnreadOrInvitedWithThreads =>
      isUnreadOrInvited || unreadBadgeCount > 0;

  /// Mentions of the room and of any of its threads.
  int get highlightCountWithThreads {
    final store = client.threadUnread;
    return highlightCount +
        (store?.threadsOf(id).fold<int>(0, (n, t) => n + t.highlightCount) ??
            0);
  }
}

extension MarkRoomAndThreadsRead on Room {
  /// Stored events, newest first, paged: the newest ones can all be replies
  /// of a busy thread. ponytail: gives up after [_mainEventSearchLimit].
  Future<Event?> _newestMainTimelineEvent() async {
    const pageSize = 50;
    for (var start = 0; start < _mainEventSearchLimit; start += pageSize) {
      final page = await client.database.getEventList(
        this,
        start: start,
        limit: pageSize,
      );
      final found = ThreadRules.newestMainTimelineEvent(page);
      if (found != null || page.length < pageSize) return found;
    }
    return null;
  }

  Future<Map<String, String>> _lastReplyOfUnreadThreads(
    List<ThreadUnread> threads,
  ) async {
    final lastByRoot = <String, String>{};
    for (final thread in threads.where((t) => t.notificationCount > 0)) {
      final page = await const GetThreadRepliesInteractor().execute(
        room: this,
        request: ThreadRepliesRequest(
          rootEventId: thread.rootEventId,
          limit: 1,
          decrypt: false,
        ),
      );
      final last = page.replies.lastOrNull;
      if (last != null) lastByRoot[thread.rootEventId] = last.eventId;
    }
    return lastByRoot;
  }

  /// "Mark as read": the main timeline and every thread with unread messages.
  Future<void> markRoomAndAllThreadsRead() async {
    final mainEvent = await _newestMainTimelineEvent();
    final store = client.threadUnread;
    final lastEventIdByThreadRootId = await _lastReplyOfUnreadThreads(
      store?.threadsOf(id) ?? const <ThreadUnread>[],
    );
    if (mainEvent != null) {
      await markRoomAndThreadsRead(
        mainEventId: mainEvent.eventId,
        lastEventIdByThreadRootId: lastEventIdByThreadRootId,
      );
      return;
    }
    for (final entry in lastEventIdByThreadRootId.entries) {
      await setThreadReadMarker(threadRootId: entry.key, eventId: entry.value);
    }
  }
}

const int _mainEventSearchLimit = 300;

/// A client that keeps the thread counters ([TwakeClient]).
abstract interface class ThreadUnreadStoreOwner {
  ThreadUnreadStore get threadUnread;
}
