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
    if (target == null || _isMoreRecent(thread, target)) target = thread;
  }
  return target?.rootEventId;
}

bool _isMoreRecent(ThreadUnread thread, ThreadUnread than) {
  final activity = thread.lastActivity;
  final best = than.lastActivity;
  if (activity == null) return false;
  return best == null || activity.isAfter(best);
}
