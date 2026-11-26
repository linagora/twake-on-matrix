import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';

import '../../../domain/model/room/room_extension_test.mocks.dart';

/// Clément, 2026-11-26 (reverses THR-M-04, "the thread screen has no quote
/// reply"): a message of a thread offers "Reply" as a message of the room
/// does, to a member allowed to send messages. One rule for every place that
/// offers "Reply": the button of the selection row (chat_input_row), the web
/// context menu and the hover menu (chat.dart), the mobile context menu.
void main() {
  late MockRoom room;

  setUp(() {
    room = MockRoom();
    when(room.id).thenReturn('!room:example.com');
    when(room.canSendDefaultMessages).thenReturn(true);
  });

  Event message() => Event(
    type: EventTypes.Message,
    content: const {'msgtype': 'm.text', 'body': 'hello'},
    eventId: r'$message',
    senderId: '@alice:example.com',
    originServerTs: DateTime.utc(2026, 11, 6),
    room: room,
  );

  // The same rule on the thread screen and in the room: it does not know
  // which screen asks.
  test('"Reply" is offered to a member who can send messages', () {
    expect(ThreadRules.canQuoteReply(message()), isTrue);
  });

  test('"Reply" is not offered to a member who cannot send messages', () {
    when(room.canSendDefaultMessages).thenReturn(false);

    expect(ThreadRules.canQuoteReply(message()), isFalse);
  });
}
