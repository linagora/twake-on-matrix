import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_read_marker.dart';

import '../../usecase/room/send_text_message_interactor_test.mocks.dart';

/// Review 5829198697 « Minor » (chat.dart 767-784): the thread screen reads
/// its last reply on every scroll. The last read id was kept only once the
/// server took the receipt, so each scroll while it was on its way sent the
/// same receipt again. One receipt per reply: none while the same one is on
/// its way or already taken; a failed one is sent again on the next read.
void main() {
  setUp(() {
    _sent = [];
    _pending = {};
    _marker = ThreadReadMarker(_send);
  });

  test('the same reply read twice while its receipt is on its way: one '
      'receipt', () async {
    unawaited(_marker.read(_replyA));
    unawaited(_marker.read(_replyA));
    await pumpEventQueue();

    expect(_sent, [_replyA.eventId]);
  });

  test(
    'the same reply read again once the server took it: no receipt',
    () async {
      final first = _marker.read(_replyA);
      _pending[_replyA.eventId]!.complete();
      await first;

      await _readNow(_replyA);

      expect(_sent, [_replyA.eventId]);
    },
  );

  test('the same reply read again after a failure: sent again', () async {
    final first = _marker.read(_replyA);
    _pending[_replyA.eventId]!.completeError(Exception('offline'));
    await first.catchError((Object _) {});

    await _readNow(_replyA);

    expect(_sent, [_replyA.eventId, _replyA.eventId]);
  });

  test('a newer reply while the receipt of the previous one is on its '
      'way: sent', () async {
    unawaited(_marker.read(_replyA));
    await _readNow(_replyB);

    expect(_sent, [_replyA.eventId, _replyB.eventId]);
  });
}

final _room = MockRoom();
final _replyA = _reply(r'$replyA');
final _replyB = _reply(r'$replyB');

Event _reply(String eventId) => Event(
  type: EventTypes.Message,
  content: {'msgtype': 'm.text', 'body': 'reply'},
  eventId: eventId,
  senderId: '@bob:example.com',
  originServerTs: DateTime.utc(2026, 11, 6, 10),
  room: _room,
);

/// The ids of the replies whose receipt was sent, in order.
late List<String> _sent;

/// The receipts on their way, by event id: each test answers them.
late Map<String, Completer<void>> _pending;
late ThreadReadMarker _marker;

Future<void> _send(Event reply) {
  _sent.add(reply.eventId);
  return (_pending[reply.eventId] = Completer<void>()).future;
}

/// Reads [reply] and lets what it sends start, without waiting for the
/// server.
Future<void> _readNow(Event reply) async {
  unawaited(_marker.read(reply).catchError((Object _) {}));
  await pumpEventQueue();
}
