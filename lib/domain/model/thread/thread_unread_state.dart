import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';

/// A room of the account.
class RoomId {
  const RoomId(this.value);

  final String value;

  bool owns(ThreadRef thread) => thread.roomId == value;

  bool ownsReply(ReplyRef reply) => reply.roomId == value;
}

/// An event seen as a thread reply, with its room.
class ReplyRef {
  const ReplyRef(this.roomId, this.eventId);

  final String roomId;
  final String eventId;
}

/// The counters of the threads of one room, as the sync carries them.
class RoomCounts {
  const RoomCounts(this.id, this.threads);

  final RoomId id;
  final Map<String, ThreadCounts> threads;
}

/// What one sync says about the threads: counters per room, rooms left.
class SyncThreadUpdate {
  const SyncThreadUpdate({required this.counts, required this.leftRoomIds});

  final Map<String, Map<String, ThreadCounts>> counts;
  final Iterable<String> leftRoomIds;

  bool get hasLeft => leftRoomIds.isNotEmpty;

  Iterable<RoomId> get leftRooms => leftRoomIds.map(RoomId.new);

  Iterable<RoomCounts> get rooms => [
    for (final room in counts.entries) RoomCounts(RoomId(room.key), room.value),
  ];
}

/// What the store saves per account. The JSON format is part of the saved
/// data: counts as [notification, highlight], follows as `room|root` keys.
class ThreadUnreadSnapshot {
  const ThreadUnreadSnapshot({
    required this.counts,
    required this.followed,
    required this.replies,
  });

  factory ThreadUnreadSnapshot.fromJson(Map<String, Object?> json) =>
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

  final Map<String, Map<String, ThreadCounts>> counts;
  final Set<ThreadRef> followed;
  final Map<String, Set<String>> replies;

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
