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

/// What the store saves per account. Its JSON format is in
/// `data/thread/models/thread_unread_snapshot_json.dart`.
class ThreadUnreadSnapshot {
  const ThreadUnreadSnapshot({
    required this.counts,
    required this.followed,
    required this.replies,
  });

  final Map<String, Map<String, ThreadCounts>> counts;
  final Set<ThreadRef> followed;
  final Map<String, Set<String>> replies;
}
