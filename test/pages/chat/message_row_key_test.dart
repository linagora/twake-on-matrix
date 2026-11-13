import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/pages/chat/chat.dart';

import '../../fake_client.dart';

void main() {
  late Room room;

  setUpAll(() async {
    room = Room(
      client: await getClient(),
      id: '!test:example.com',
      membership: Membership.join,
    );
  });

  Event eventWithId(String id) => Event(
    senderId: '@user:example.com',
    type: EventTypes.Message,
    room: room,
    eventId: id,
    content: {'msgtype': MessageTypes.Text, 'body': 'hello'},
    originServerTs: DateTime.utc(2026, 11, 11),
  );

  // An id equal to the event's but another String object, as decoded from a
  // link or a URL query.
  String sameIdOtherObject(String id) => String.fromCharCodes(id.codeUnits);

  testWidgets('finds the row of an event from an id decoded elsewhere', (
    tester,
  ) async {
    final event = eventWithId(r'$target:example.com');
    final decodedId = sameIdOtherObject(event.eventId);
    expect(identical(decodedId, event.eventId), isFalse);

    // Rows are keyed like ChatEventListItem: GlobalObjectKey(event.eventId).
    await tester.pumpWidget(SizedBox(key: GlobalObjectKey(event.eventId)));

    expect(messageRowKey(decodedId, [event]).currentContext, isNotNull);
  });

  testWidgets('keeps the given id when the timeline does not hold it', (
    tester,
  ) async {
    const missingId = r'$missing:example.com';

    expect(
      messageRowKey(missingId, [eventWithId(r'$other:example.com')]),
      const GlobalObjectKey(missingId),
    );
  });
}
