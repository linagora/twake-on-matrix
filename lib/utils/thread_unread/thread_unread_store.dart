import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';

/// Unread counters of the threads, kept in memory: the SDK keeps only the
/// counters of the room. Filled from the raw sync response, so a restart
/// waits for the next sync that carries them.
class ThreadUnreadStore extends ChangeNotifier {
  Client? _client;

  final Map<String, Map<String, ThreadCounts>> _counts = {};
  final Map<String, bool> _followed = {};
  final Map<String, DateTime> _activity = {};

  // ponytail: in memory only, persist if a cold start must show them at once
  void attach(Client client) => _client = client;

  void apply(Map<String, Map<String, ThreadCounts>> roomCounts) {
    if (roomCounts.isEmpty) return;
    for (final entry in roomCounts.entries) {
      final before = _counts[entry.key] ?? const {};
      for (final thread in entry.value.entries) {
        if (thread.value != before[thread.key]) {
          _activity['${entry.key}|${thread.key}'] = DateTime.now();
        }
        if (thread.value.notificationCount > 0) {
          _resolveFollowed(entry.key, thread.key);
        }
      }
      _counts[entry.key] = entry.value;
    }
    notifyListeners();
  }

  /// The user wrote in this thread: it is followed from now on.
  void markFollowed(String roomId, String rootId) {
    if (_followed['$roomId|$rootId'] == true) return;
    _followed['$roomId|$rootId'] = true;
    notifyListeners();
  }

  int unreadCount(String roomId, String rootId) =>
      _counts[roomId]?[rootId]?.notificationCount ?? 0;

  List<ThreadUnread> threadsOf(String roomId) => [
    for (final entry
        in (_counts[roomId] ?? const <String, ThreadCounts>{}).entries)
      ThreadUnread(
        rootEventId: entry.key,
        notificationCount: entry.value.notificationCount,
        highlightCount: entry.value.highlightCount,
        followed: _followed['$roomId|${entry.key}'] ?? false,
        lastActivity: _activity['$roomId|${entry.key}'],
      ),
  ];

  /// Participation as the server tells it: the user wrote the root or
  /// replied (P1; the explicit follow choice comes with P2).
  Future<void> _resolveFollowed(String roomId, String rootId) async {
    final key = '$roomId|$rootId';
    if (_followed.containsKey(key)) return;
    _followed[key] = false;
    try {
      final room = _client?.getRoomById(roomId);
      final root = await room?.getEventById(rootId);
      if (root == null) return;
      final participated =
          (((root.unsigned?['m.relations'] as Map?)?['m.thread']
              as Map?)?['current_user_participated']) ==
          true;
      if (participated || root.senderId == _client?.userID) {
        _followed[key] = true;
        notifyListeners();
      }
    } catch (e, s) {
      Logs().w('Unable to tell if the thread is followed', e, s);
      _followed.remove(key);
    }
  }
}

extension ThreadUnreadRoomExtension on Room {
  /// Room badge: main timeline, followed threads and mentions of any thread.
  int get unreadBadgeCount {
    final store = client is ThreadUnreadStoreOwner
        ? (client as ThreadUnreadStoreOwner).threadUnread
        : null;
    return store == null
        ? notificationCount
        : roomUnreadBadge(
            mainNotificationCount: notificationCount,
            threads: store.threadsOf(id),
          );
  }
}

/// A client that keeps the thread counters ([TwakeClient]).
abstract interface class ThreadUnreadStoreOwner {
  ThreadUnreadStore get threadUnread;
}
