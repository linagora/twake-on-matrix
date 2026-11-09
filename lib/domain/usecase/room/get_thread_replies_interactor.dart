import 'package:matrix/matrix.dart';

class ThreadRepliesPage {
  const ThreadRepliesPage({required this.replies, this.nextBatch});

  /// Oldest first.
  final List<Event> replies;

  final String? nextBatch;

  bool get canLoadMore => nextBatch != null;
}

/// Loads the replies of a thread by pages, going up its history.
///
/// [withRelations]: the thread screen also needs the edits and reactions of
/// the replies, so it reads `/relations/<root>?recurse=true` with no
/// `rel_type` filter (they come in [ThreadRepliesPage.replies] too); without
/// it, `/relations/<root>/m.thread` gives the replies only.
/// [decrypt]: false when only ids are read (mark as read).
final class GetThreadRepliesInteractor {
  const GetThreadRepliesInteractor();

  static const int pageSize = 30;

  Future<ThreadRepliesPage> execute({
    required Room room,
    required String rootEventId,
    String? from,
    int limit = pageSize,
    bool withRelations = false,
    bool decrypt = true,
  }) async {
    final ({List<MatrixEvent> chunk, String? nextBatch}) response;
    if (withRelations) {
      final r = await room.client.getRelatingEvents(
        room.id,
        rootEventId,
        from: from,
        limit: limit,
        dir: Direction.b,
        recurse: true,
      );
      response = (chunk: r.chunk, nextBatch: r.nextBatch);
    } else {
      final r = await room.client.getRelatingEventsWithRelType(
        room.id,
        rootEventId,
        RelationshipTypes.thread,
        from: from,
        limit: limit,
        dir: Direction.b,
      );
      response = (chunk: r.chunk, nextBatch: r.nextBatch);
    }
    final replies = [
      for (final event in response.chunk.reversed)
        Event.fromMatrixEvent(event, room),
    ];
    // /relations returns the events as stored: decrypt them.
    if (decrypt && _canDecrypt(room)) {
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

  bool _canDecrypt(Room room) =>
      room.encrypted && room.client.encryptionEnabled;
}
