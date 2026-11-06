typedef ThreadCounts = ({int notificationCount, int highlightCount});

/// Unread counters of one thread of a room.
class ThreadUnread {
  const ThreadUnread({
    required this.rootEventId,
    required this.notificationCount,
    required this.highlightCount,
    required this.followed,
    this.lastActivity,
  });

  final String rootEventId;
  final int notificationCount;
  final int highlightCount;
  final bool followed;
  final DateTime? lastActivity;

  /// highlight_count is part of notification_count: a followed thread counts
  /// all of it, another one only its mentions.
  int get badgeCount => followed ? notificationCount : highlightCount;
}

/// Reads `unread_thread_notifications` of a joined room of the sync response.
/// Malformed entries are ignored.
Map<String, ThreadCounts> parseUnreadThreadNotifications(Object? json) {
  final counts = <String, ThreadCounts>{};
  if (json is! Map) return counts;
  for (final entry in json.entries) {
    final value = entry.value;
    if (entry.key is! String || value is! Map) continue;
    final notifications = value['notification_count'] ?? 0;
    final highlights = value['highlight_count'] ?? 0;
    if (notifications is! int || highlights is! int) continue;
    counts[entry.key as String] = (
      notificationCount: notifications,
      highlightCount: highlights,
    );
  }
  return counts;
}

int roomUnreadBadge({
  required int mainNotificationCount,
  required Iterable<ThreadUnread> threads,
}) => threads.fold(
  mainNotificationCount,
  (total, thread) => total + thread.badgeCount,
);

/// Root of the thread the "New replies in a thread" banner opens, or null.
String? unreadThreadBannerTarget({
  required int mainNotificationCount,
  required Iterable<ThreadUnread> threads,
}) {
  if (mainNotificationCount > 0) return null;
  ThreadUnread? target;
  for (final thread in threads.where((t) => t.badgeCount > 0)) {
    final activity = thread.lastActivity;
    final best = target?.lastActivity;
    if (target == null ||
        (activity != null && (best == null || activity.isAfter(best)))) {
      target = thread;
    }
  }
  return target?.rootEventId;
}
