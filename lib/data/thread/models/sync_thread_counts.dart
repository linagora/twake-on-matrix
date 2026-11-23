import 'package:twake_chat/domain/model/thread/thread_unread.dart';

/// Reads `unread_thread_notifications` of a joined room of the sync response.
/// Malformed entries are ignored.
Map<String, ThreadCounts> parseUnreadThreadNotifications(Object? json) {
  final counts = <String, ThreadCounts>{};
  if (json is! Map) return counts;
  for (final entry in json.entries) {
    final key = entry.key;
    final parsed = _parseThreadCounts(entry.value);
    if (key is String && parsed != null) counts[key] = parsed;
  }
  return counts;
}

ThreadCounts? _parseThreadCounts(Object? value) {
  if (value is! Map) return null;
  final notifications = value['notification_count'] ?? 0;
  final highlights = value['highlight_count'] ?? 0;
  if (notifications is! int || highlights is! int) return null;
  return (notificationCount: notifications, highlightCount: highlights);
}

/// Per-thread counters of every joined room of a raw `/sync` response, for
/// the rooms whose update carries counters (their map replaces the old one).
/// The SDK does not parse `unread_thread_notifications`.
Map<String, Map<String, ThreadCounts>> parseSyncUnreadThreadNotifications(
  Map<String, Object?> sync,
) {
  final result = <String, Map<String, ThreadCounts>>{};
  final rooms = ((sync['rooms'] as Map?)?['join']) as Map?;
  if (rooms == null) return result;
  for (final entry in rooms.entries) {
    final room = entry.value;
    if (entry.key is! String || room is! Map) continue;
    final threads =
        room['unread_thread_notifications'] ??
        room['org.matrix.msc3773.unread_thread_notifications'];
    if (_carriesCounters(room, threads)) {
      result[entry.key as String] = parseUnreadThreadNotifications(threads);
    }
  }
  return result;
}

bool _carriesCounters(Map room, Object? threads) =>
    threads != null || room['unread_notifications'] != null;
