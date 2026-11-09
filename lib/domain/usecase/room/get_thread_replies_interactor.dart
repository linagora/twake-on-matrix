import 'package:matrix/matrix.dart';

class ThreadRepliesPage {
  const ThreadRepliesPage({required this.replies, this.nextBatch});

  /// Oldest first.
  final List<Event> replies;

  final String? nextBatch;

  bool get canLoadMore => nextBatch != null;
}

/// What to load of a thread.
///
/// [withRelations]: the thread screen also needs the edits and reactions of
/// the replies, so it reads `/relations/<root>?recurse=true` with no
/// `rel_type` filter (they come in [ThreadRepliesPage.replies] too); without
/// it, `/relations/<root>/m.thread` gives the replies only.
/// [decrypt]: false when only ids are read (mark as read).
class ThreadRepliesRequest {
  const ThreadRepliesRequest({
    required this.rootEventId,
    this.from,
    this.limit = GetThreadRepliesInteractor.pageSize,
    this.withRelations = false,
    this.decrypt = true,
  });

  final String rootEventId;
  final String? from;
  final int limit;
  final bool withRelations;
  final bool decrypt;
}

/// Loads the replies of a thread by pages, going up its history.
final class GetThreadRepliesInteractor {
  const GetThreadRepliesInteractor();

  static const int pageSize = 30;

  Future<ThreadRepliesPage> execute({
    required Room room,
    required ThreadRepliesRequest request,
  }) async {
    final response = await _fetch(room, request);
    final replies = [
      for (final event in response.chunk.reversed)
        Event.fromMatrixEvent(event, room),
    ];
    // /relations returns the events as stored: decrypt them.
    if (request.decrypt && _canDecrypt(room)) {
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

  Future<({List<MatrixEvent> chunk, String? nextBatch})> _fetch(
    Room room,
    ThreadRepliesRequest request,
  ) async {
    if (request.withRelations) {
      final r = await room.client.getRelatingEvents(
        room.id,
        request.rootEventId,
        from: request.from,
        limit: request.limit,
        dir: Direction.b,
        recurse: true,
      );
      return (chunk: r.chunk, nextBatch: r.nextBatch);
    }
    final r = await room.client.getRelatingEventsWithRelType(
      room.id,
      request.rootEventId,
      RelationshipTypes.thread,
      from: request.from,
      limit: request.limit,
      dir: Direction.b,
    );
    return (chunk: r.chunk, nextBatch: r.nextBatch);
  }

  bool _canDecrypt(Room room) =>
      room.encrypted && room.client.encryptionEnabled;
}
