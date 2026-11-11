import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';

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

  Event eventWith(EventStatus status, {Map<String, dynamic>? unsigned}) =>
      Event(
        senderId: '@user:example.com',
        type: EventTypes.Message,
        room: room,
        eventId: r'$event',
        content: {'msgtype': MessageTypes.Text, 'body': 'hello'},
        originServerTs: DateTime.utc(2026, 11, 11),
        status: status,
        unsigned: unsigned,
      );

  test('a sent or synced message can be linked', () {
    expect(eventWith(EventStatus.sent).canCopyLink, isTrue);
    expect(eventWith(EventStatus.synced).canCopyLink, isTrue);
  });

  test('a sending or failed message cannot be linked', () {
    expect(eventWith(EventStatus.sending).canCopyLink, isFalse);
    expect(eventWith(EventStatus.error).canCopyLink, isFalse);
  });

  test('a deleted message cannot be linked', () {
    final deleted = eventWith(
      EventStatus.synced,
      unsigned: {
        'redacted_because': {
          'type': EventTypes.Redaction,
          'event_id': r'$redaction',
          'sender': '@user:example.com',
          'origin_server_ts': 1762819200000,
          'content': <String, dynamic>{},
        },
      },
    );

    expect(deleted.redacted, isTrue);
    expect(deleted.canCopyLink, isFalse);
  });
}
