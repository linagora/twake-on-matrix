import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

/// An event deleted by [sender]: no content left, so no `m.relates_to`.
Event deletedEvent({
  required String eventId,
  required String sender,
  required Room room,
  required DateTime sentAt,
}) => Event(
  type: EventTypes.Message,
  content: const {},
  eventId: eventId,
  senderId: sender,
  originServerTs: sentAt,
  unsigned: {
    'redacted_because': {
      'type': EventTypes.Redaction,
      'event_id': '${eventId}_redaction',
      'sender': sender,
      'origin_server_ts': sentAt
          .add(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
      'content': const {},
      'redacts': eventId,
    },
  },
  room: room,
);

/// Stored events of a room, newest first, paged like the SDK database.
class StoredEvents extends MockDatabase {
  StoredEvents(this.events);

  final List<Event> events;

  @override
  Future<List<Event>> getEventList(
    Room room, {
    int start = 0,
    bool onlySending = false,
    int? limit,
  }) async {
    final stored = events.skip(start);
    return (limit == null ? stored : stored.take(limit)).toList();
  }
}
