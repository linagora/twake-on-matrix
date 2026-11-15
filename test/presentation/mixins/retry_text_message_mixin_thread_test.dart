import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/presentation/mixins/retry_text_message_mixin.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';

class _Retrier with RetryTextMessageMixin {}

/// Retrying a failed text must resend it with the same relation: a failed
/// thread reply goes back to its thread (root + last event, no quote), a
/// failed classic reply reloads its quote.
void main() {
  const rootId = r'$root';
  const lastId = r'$last';
  const quotedId = r'$quoted';
  const txid = 'txid-1';

  late MockRoom room;
  late _Retrier retrier;

  Event failed(Map<String, Object?>? relatesTo) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': MessageTypes.Text,
      'body': 'hello',
      'm.relates_to': ?relatesTo,
    },
    eventId: r'$local',
    senderId: '@alice:example.org',
    originServerTs: DateTime.utc(2026, 11, 15),
    room: room,
    status: EventStatus.error,
    unsigned: {'transaction_id': txid},
  );

  Future<String?> verifySentOnce({
    Event? inReplyTo,
    String? threadRootEventId,
    String? threadLastEventId,
  }) async {
    verify(
      room.sendTextEvent(
        'hello',
        txid: txid,
        inReplyTo: inReplyTo,
        editEventId: null,
        threadRootEventId: threadRootEventId,
        threadLastEventId: threadLastEventId,
      ),
    ).called(1);
    return null;
  }

  setUp(() {
    room = MockRoom();
    when(room.id).thenReturn('!room:example.org');
    when(
      room.sendTextEvent(
        any,
        txid: anyNamed('txid'),
        inReplyTo: anyNamed('inReplyTo'),
        editEventId: anyNamed('editEventId'),
        threadRootEventId: anyNamed('threadRootEventId'),
        threadLastEventId: anyNamed('threadLastEventId'),
      ),
    ).thenAnswer((_) async => r'$sent');
    retrier = _Retrier();
  });

  test(
    'a failed thread reply is resent to its thread, without a quote',
    () async {
      final event = failed({
        'rel_type': RelationshipTypes.thread,
        'event_id': rootId,
        'is_falling_back': true,
        'm.in_reply_to': {'event_id': lastId},
      });

      await retrier.retryTextMessage(event);

      await verifySentOnce(
        threadRootEventId: rootId,
        threadLastEventId: lastId,
      );
      verifyNever(room.getEventById(any));
    },
  );

  test(
    'a failed classic reply reloads its quote and is not threaded',
    () async {
      final quoted = Event(
        type: EventTypes.Message,
        content: {'msgtype': MessageTypes.Text, 'body': 'original'},
        eventId: quotedId,
        senderId: '@bob:example.org',
        originServerTs: DateTime.utc(2026, 11, 15),
        room: room,
      );
      when(room.getEventById(quotedId)).thenAnswer((_) async => quoted);
      final event = failed({
        'm.in_reply_to': {'event_id': quotedId},
      });

      await retrier.retryTextMessage(event);

      await verifySentOnce(inReplyTo: quoted);
      verify(room.getEventById(quotedId)).called(1);
    },
  );

  test('a failed plain message is resent without any relation', () async {
    await retrier.retryTextMessage(failed(null));

    await verifySentOnce();
    verifyNever(room.getEventById(any));
  });
}
