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

  /// With `recurse`, everything under the root belongs to the thread (replies,
  /// and the edits and reactions that target them) except the relations that
  /// target the root itself and are not thread replies.
  /// `m.relates_to` stays in clear in encrypted events.
  List<MatrixEvent> _threadEvents(List<MatrixEvent> chunk, String rootId) {
    bool targetsRootOutsideThread(MatrixEvent e) {
      final relatesTo = e.content['m.relates_to'] as Map<String, Object?>?;
      return relatesTo?['event_id'] == rootId &&
          relatesTo?['rel_type'] != RelationshipTypes.thread;
    }

    return [
      for (final e in chunk)
        if (!targetsRootOutsideThread(e)) e,
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
