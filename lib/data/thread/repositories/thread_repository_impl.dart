import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';
import 'package:twake_chat/domain/thread/repositories/thread_repository.dart';

typedef _RelationsChunk = ({List<MatrixEvent> chunk, String? nextBatch});

class ThreadRepositoryImpl implements ThreadRepository<Event> {
  const ThreadRepositoryImpl(this._client);

  final Client _client;

  @override
  Future<ThreadRepliesPage<Event>> getReplies(
    String roomId,
    ThreadRepliesRequest request,
  ) async {
    final room = _client.getRoomById(roomId);
    // A room the client does not know (left, not synced yet): nothing to show.
    if (room == null) return const ThreadRepliesPage(replies: []);
    final response = await _fetch(roomId, request);
    final replies = [
      for (final event in response.chunk.reversed)
        Event.fromMatrixEvent(event, room),
    ];
    // /relations returns the events as stored: decrypt them.
    if (request.decrypt && _canDecrypt(room)) {
      await _decryptInPlace(room, replies);
    }
    return ThreadRepliesPage(replies: replies, nextBatch: response.nextBatch);
  }

  Future<void> _decryptInPlace(Room room, List<Event> replies) async {
    for (var i = 0; i < replies.length; i++) {
      if (replies[i].type == EventTypes.Encrypted) {
        replies[i] = await _client.encryption!.decryptRoomEvent(replies[i]);
      }
    }
  }

  Future<_RelationsChunk> _fetch(
    String roomId,
    ThreadRepliesRequest request,
  ) async {
    if (request.withRelations) {
      final r = await _client.getRelatingEvents(
        roomId,
        request.rootEventId,
        from: request.from,
        limit: request.limit,
        dir: Direction.b,
        recurse: true,
      );
      return (chunk: r.chunk, nextBatch: r.nextBatch);
    }
    final r = await _client.getRelatingEventsWithRelType(
      roomId,
      request.rootEventId,
      RelationshipTypes.thread,
      from: request.from,
      limit: request.limit,
      dir: Direction.b,
    );
    return (chunk: r.chunk, nextBatch: r.nextBatch);
  }

  bool _canDecrypt(Room room) => room.encrypted && _client.encryptionEnabled;
}
