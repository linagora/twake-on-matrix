import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/thread/datasources/thread_datasource.dart';
import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';
import 'package:twake_chat/domain/thread/exceptions/thread_exception.dart';

class ThreadDatasourceImpl implements ThreadDatasource {
  const ThreadDatasourceImpl(this._client);

  final Client _client;

  @override
  Future<ThreadRepliesPage<Event>> getReplies(
    String roomId,
    ThreadRepliesRequest request,
  ) async {
    final room = _client.getRoomById(roomId);
    if (room == null) throw ThreadRoomNotFoundException(roomId);
    try {
      // https://spec.matrix.org/v1.16/client-server-api/#get_matrixclientv1roomsroomidrelationseventid
      // `recurse` adds the indirect relations; a server without `recurse`
      // only returns the direct ones.
      final response = await _client.getRelatingEvents(
        roomId,
        request.rootEventId,
        from: request.from,
        limit: request.limit,
        dir: Direction.b,
        recurse: true,
      );
      final replies = [
        for (final event in _threadEvents(
          response.chunk,
          request.rootEventId,
        ).reversed)
          Event.fromMatrixEvent(event, room),
      ];
      // /relations returns the events as stored: decrypt them.
      if (room.encrypted && _client.encryptionEnabled) {
        await _decryptInPlace(replies);
      }
      return ThreadRepliesPage(replies: replies, nextBatch: response.nextBatch);
    } on Exception catch (e, s) {
      Logs().e('ThreadDatasourceImpl::getReplies() failed', e, s);
      throw ThreadLoadFailedException(roomId);
    }
  }

  /// Keeps the thread replies and the edits and reactions that target them.
  /// With `recurse`, the root's own edits and reactions come back too.
  /// `m.relates_to` stays in clear in encrypted events.
  List<MatrixEvent> _threadEvents(List<MatrixEvent> chunk, String rootId) {
    Map<String, Object?>? relatesTo(MatrixEvent e) =>
        e.content['m.relates_to'] as Map<String, Object?>?;
    final threadIds = {
      for (final e in chunk)
        if (relatesTo(e)?['rel_type'] == RelationshipTypes.thread &&
            relatesTo(e)?['event_id'] == rootId)
          e.eventId,
    };
    return [
      for (final e in chunk)
        if (threadIds.contains(e.eventId) ||
            threadIds.contains(relatesTo(e)?['event_id']))
          e,
    ];
  }

  Future<void> _decryptInPlace(List<Event> replies) async {
    for (var i = 0; i < replies.length; i++) {
      if (replies[i].type == EventTypes.Encrypted) {
        replies[i] = await _client.encryption!.decryptRoomEvent(replies[i]);
      }
    }
  }
}
