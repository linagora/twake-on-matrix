import 'package:matrix/matrix.dart';

class ThreadRepliesPage {
  const ThreadRepliesPage({required this.replies, this.nextBatch});

  /// Oldest first.
  final List<Event> replies;

  final String? nextBatch;

  bool get canLoadMore => nextBatch != null;
}

/// Loads the replies of a thread by pages, going up its history
/// (`/relations/<root>/m.thread`).
final class GetThreadRepliesInteractor {
  const GetThreadRepliesInteractor();

  static const int pageSize = 30;

  Future<ThreadRepliesPage> execute({
    required Room room,
    required String rootEventId,
    String? from,
    int limit = pageSize,
  }) async {
    final response = await room.client.getRelatingEventsWithRelType(
      room.id,
      rootEventId,
      RelationshipTypes.thread,
      from: from,
      limit: limit,
      dir: Direction.b,
    );
    final replies = [
      for (final event in response.chunk.reversed)
        Event.fromMatrixEvent(event, room),
    ];
    // /relations returns the events as stored: decrypt them.
    if (room.encrypted && room.client.encryptionEnabled) {
      for (var i = 0; i < replies.length; i++) {
        if (replies[i].type == EventTypes.Encrypted) {
          replies[i] = await room.client.encryption!.decryptRoomEvent(
            replies[i],
          );
        }
      }
    }
    return ThreadRepliesPage(replies: replies, nextBatch: response.nextBatch);
  }
}
