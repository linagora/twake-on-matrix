import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat/chat.dart';

import '../../fake_client.dart';

void main() {
  const me = '@me:example.com';
  const other = '@other:example.com';
  const fullyRead = r'$fullyRead:example.com';
  late Room room;

  setUpAll(() async {
    room = Room(
      client: await getClient(),
      id: '!test:example.com',
      membership: Membership.join,
    );
  });

  Event message(String id, {String sender = other}) => Event(
    senderId: sender,
    type: EventTypes.Message,
    room: room,
    eventId: id,
    content: {'msgtype': MessageTypes.Text, 'body': 'hello'},
    originServerTs: DateTime.utc(2026, 11, 20),
  );

  Event reaction(String id) => Event(
    senderId: other,
    type: EventTypes.Reaction,
    room: room,
    eventId: id,
    content: {
      'm.relates_to': {
        'rel_type': RelationshipTypes.reaction,
        'event_id': fullyRead,
        'key': '👍',
      },
    },
    originServerTs: DateTime.utc(2026, 11, 20),
  );

  Event edit(String id) => Event(
    senderId: other,
    type: EventTypes.Message,
    room: room,
    eventId: id,
    content: {
      'msgtype': MessageTypes.Text,
      'body': '* hello',
      'm.new_content': {'msgtype': MessageTypes.Text, 'body': 'hello'},
      'm.relates_to': {'rel_type': RelationshipTypes.edit, 'event_id': r'$a'},
    },
    originServerTs: DateTime.utc(2026, 11, 20),
  );

  Event redaction(String id) => Event(
    senderId: other,
    type: EventTypes.Redaction,
    room: room,
    eventId: id,
    redacts: r'$a',
    content: const {},
    originServerTs: DateTime.utc(2026, 11, 20),
  );

  test('skips events that have no row in the list', () {
    final events = [
      message(r'$newest'),
      message(r'$first'),
      edit(r'$edit'),
      redaction(r'$redaction'),
      reaction(r'$reaction'),
      message(fullyRead, sender: me),
    ];

    expect(
      firstUnreadReceivedEventId(events, fullyRead: fullyRead, userId: me),
      r'$first',
    );
  });

  test('skips messages sent by the user', () {
    final events = [
      message(r'$first'),
      message(r'$mine', sender: me),
      message(fullyRead),
    ];

    expect(
      firstUnreadReceivedEventId(events, fullyRead: fullyRead, userId: me),
      r'$first',
    );
  });

  test('returns null when only hidden events follow fullyRead', () {
    final events = [reaction(r'$reaction'), message(fullyRead)];

    expect(
      firstUnreadReceivedEventId(events, fullyRead: fullyRead, userId: me),
      isNull,
    );
  });

  test('returns null when fullyRead is the newest or missing', () {
    final events = [message(fullyRead), message(r'$older')];

    expect(
      firstUnreadReceivedEventId(events, fullyRead: fullyRead, userId: me),
      isNull,
    );
    expect(
      firstUnreadReceivedEventId(events, fullyRead: r'$gone', userId: me),
      isNull,
    );
  });
}
