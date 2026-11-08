import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Map<String, DateTime> _activity = {};
  final Map<String, int> _badges = {};

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
      final hadCounts = _counts.remove(roomId) != null;
      final prefix = '$roomId|';
      final hadFollow = _followed.length;
      _followed.removeWhere((key) => key.startsWith(prefix));
      _activity.removeWhere((key, _) => key.startsWith(prefix));
      _badges.remove(roomId);
      changed |= hadCounts || hadFollow != _followed.length;
    }
    for (final entry in roomCounts.entries) {
      final before = _counts[entry.key] ?? const <String, ThreadCounts>{};
      for (final thread in entry.value.entries) {
        final previous = before[thread.key]?.notificationCount ?? 0;
        if (thread.value.notificationCount > previous) {
          _activity['${entry.key}|${thread.key}'] = DateTime.now();
          _resolveFollowed(entry.key, thread.key);
        }
      }
      if (!mapEquals(before, entry.value)) {
        _counts[entry.key] = entry.value;
        _refreshBadge(entry.key);
        changed = true;
      }
    }
    if (!changed) return;
    notifyListeners();
    _persist();
  }

  /// The user wrote in this thread: it is followed from now on.
  void markFollowed(String roomId, String rootId) {
    if (!_followed.add('$roomId|$rootId')) return;
    _refreshBadge(roomId);
    notifyListeners();
    _persist();
  }

  /// Loads what [_persist] saved; a sync that came first wins.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, Object?>;
      for (final room in (json['counts'] as Map? ?? const {}).entries) {
        _counts.putIfAbsent(
          room.key as String,
          () => {
            for (final thread in (room.value as Map).entries)
              thread.key as String: (
                notificationCount: (thread.value as List)[0] as int,
                highlightCount: (thread.value as List)[1] as int,
              ),
          },
        );
      }
      _followed.addAll((json['followed'] as List? ?? const []).cast<String>());
      _counts.keys.toList().forEach(_refreshBadge);
      notifyListeners();
    } catch (e, s) {
      Logs().w('Unable to restore the thread counters', e, s);
    }
  }

  /// Logout: forgets everything, in memory and saved, also when a save is
  /// still running (it runs first, then the key goes).
  Future<void> clear() async {
    _epoch++;
    _counts.clear();
    _followed.clear();
    _activity.clear();
    _badges.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e, s) {
      Logs().w('Unable to clear the thread counters', e, s);
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
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
        }),
      );
    } catch (e, s) {
      Logs().w('Unable to save the thread counters', e, s);
    }
  }

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
        followed: _followed.contains('$roomId|${entry.key}'),
        lastActivity: _activity['$roomId|${entry.key}'],
      ),
  ];

  /// Participation as the server tells it: the user wrote the root or
  /// replied (P1; the explicit follow choice comes with P2). A "no" is not
  /// kept: the next increase of the counter asks again.
  Future<void> _resolveFollowed(String roomId, String rootId) async {
    final key = '$roomId|$rootId';
    if (_followed.contains(key) || !_resolving.add(key)) return;
    final epoch = _epoch;
    try {
      final root = await _client.getRoomById(roomId)?.getEventById(rootId);
      if (root == null || epoch != _epoch) return;
      final participated =
          (((root.unsigned?['m.relations'] as Map?)?['m.thread']
              as Map?)?['current_user_participated']) ==
          true;
      if (participated || root.senderId == _client.userID) {
        markFollowed(roomId, rootId);
      }
    } catch (e, s) {
      Logs().w('Unable to tell if the thread is followed', e, s);
    } finally {
      _resolving.remove(key);
    }
  }
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

  /// "Mark as read": the main timeline and every thread with unread messages.
  Future<void> markRoomAndAllThreadsRead() async {
    final mainEvent = await _newestMainTimelineEvent();
    final store = client.threadUnread;
    final lastEventIdByThreadRootId = <String, String>{};
    for (final thread in store?.threadsOf(id) ?? const <ThreadUnread>[]) {
      if (thread.notificationCount == 0) continue;
      final page = await const GetThreadRepliesInteractor().execute(
        room: this,
        rootEventId: thread.rootEventId,
        limit: 1,
      );
      final last = page.replies.lastOrNull;
      if (last != null) {
        lastEventIdByThreadRootId[thread.rootEventId] = last.eventId;
      }
    }
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
