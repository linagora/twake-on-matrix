import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_events.dart';
import 'package:twake_chat/domain/usecase/room/get_thread_replies_interactor.dart';

/// One page of the thread screen, going up its history: the replies and,
/// because of `recurse`, the edits and reactions of those replies
/// (`/relations/<root>?recurse=true&dir=b`, no `rel_type` filter).
final class GetThreadEventsPageInteractor {
  const GetThreadEventsPageInteractor();

  Future<ThreadPage> execute({
    required Room room,
    required String rootEventId,
    String? from,
    int limit = GetThreadRepliesInteractor.pageSize,
  }) async {
    final response = await room.client.getRelatingEvents(
      room.id,
      rootEventId,
      from: from,
      limit: limit,
      dir: Direction.b,
      recurse: true,
    );
    final events = [
      for (final event in response.chunk) Event.fromMatrixEvent(event, room),
    ];
    // /relations returns the events as stored: decrypt them.
    if (room.encrypted && room.client.encryptionEnabled) {
      for (var i = 0; i < events.length; i++) {
        if (events[i].type == EventTypes.Encrypted) {
          events[i] = await room.client.encryption!.decryptRoomEvent(events[i]);
        }
      }
    }
    return (events: events, nextBatch: response.nextBatch);
  }
}
