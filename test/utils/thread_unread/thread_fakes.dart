import 'package:matrix/matrix.dart';

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
