import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_list_extension.dart';

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

  Event messageFrom(String senderId, String eventId) => Event(
    senderId: senderId,
    type: EventTypes.Message,
    room: room,
    eventId: eventId,
    content: {'msgtype': MessageTypes.Text, 'body': 'hello'},
    originServerTs: DateTime.utc(2026, 11, 27),
  );

  test('own messages in an active room can all be deleted', () {
    final events = [
      messageFrom('@admin:fakeServer', r'$own1'),
      messageFrom('@admin:fakeServer', r'$own2'),
    ];

    expect(events.canDeleteAll(isArchived: false), isTrue);
  });

  test('nothing can be deleted in an archived room', () {
    final events = [messageFrom('@admin:fakeServer', r'$own')];

    expect(events.canDeleteAll(isArchived: true), isFalse);
  });

  test('an empty selection cannot be deleted', () {
    expect(<Event>[].canDeleteAll(isArchived: false), isFalse);
  });

  test('one message that cannot be deleted blocks the whole selection', () {
    final others = messageFrom('@other:fakeServer', r'$other');
    final events = [messageFrom('@admin:fakeServer', r'$own'), others];

    expect(others.canDelete, isFalse);
    expect(events.canDeleteAll(isArchived: false), isFalse);
  });
}
