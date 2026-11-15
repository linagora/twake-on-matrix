import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

const threadRoomId = '!room:example.com';
const threadRootId = r'$root';

/// Decrypts every event into the text message [decryptedBody].
class FakeEncryption extends Fake implements Encryption {
  static const decryptedBody = 'decrypted reply';

  @override
  Future<Event> decryptRoomEvent(
    Event event, {
    bool store = false,
    EventUpdateType updateType = EventUpdateType.timeline,
  }) async => Event(
    type: EventTypes.Message,
    content: const {'msgtype': 'm.text', 'body': decryptedBody},
    eventId: event.eventId,
    senderId: event.senderId,
    originServerTs: event.originServerTs,
    room: event.room,
  );
}

Map<String, Object?> _threadRelation() => {
  'rel_type': RelationshipTypes.thread,
  'event_id': threadRootId,
};

/// A plain text reply of the thread, sent at 10:[minute].
MatrixEvent threadReply(String eventId, int minute) => MatrixEvent(
  type: EventTypes.Message,
  content: {
    'msgtype': 'm.text',
    'body': 'reply $eventId',
    'm.relates_to': _threadRelation(),
  },
  eventId: eventId,
  senderId: '@bob:example.com',
  originServerTs: DateTime.utc(2026, 11, 6, 10, minute),
);

/// A reply stored encrypted: `/relations` returns it as is.
MatrixEvent encryptedThreadReply(String eventId, int minute) => MatrixEvent(
  type: EventTypes.Encrypted,
  content: {
    'algorithm': 'm.megolm.v1.aes-sha2',
    'ciphertext': 'AwgA',
    'm.relates_to': _threadRelation(),
  },
  eventId: eventId,
  senderId: '@bob:example.com',
  originServerTs: DateTime.utc(2026, 11, 6, 10, minute),
);
