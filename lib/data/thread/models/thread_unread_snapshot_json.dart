import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';

/// The JSON format is part of the saved data: counts as
/// [notification, highlight], follows as `room|root` keys.
ThreadUnreadSnapshot threadUnreadSnapshotFromJson(Map<String, Object?> json) =>
    ThreadUnreadSnapshot(
      counts: {
        for (final room in (json['counts'] as Map? ?? const {}).entries)
          room.key as String: {
            for (final thread in (room.value as Map).entries)
              thread.key as String: (
                notificationCount: (thread.value as List)[0] as int,
                highlightCount: (thread.value as List)[1] as int,
              ),
          },
      },
      followed: {
        for (final key in (json['followed'] as List? ?? const []))
          ThreadRef(
            (key as String).split('|').first,
            key.substring(key.indexOf('|') + 1),
          ),
      },
      replies: {
        for (final room in (json['replies'] as Map? ?? const {}).entries)
          room.key as String: (room.value as List).cast<String>().toSet(),
      },
    );

extension ThreadUnreadSnapshotJson on ThreadUnreadSnapshot {
  Map<String, Object?> toJson() => {
    'counts': {
      for (final room in counts.entries)
        room.key: {
          for (final thread in room.value.entries)
            thread.key: [
              thread.value.notificationCount,
              thread.value.highlightCount,
            ],
        },
    },
    'followed': [for (final thread in followed) thread.key],
    'replies': {
      for (final room in replies.entries)
        if (room.value.isNotEmpty) room.key: room.value.toList(),
    },
  };
}
