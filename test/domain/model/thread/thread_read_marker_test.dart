import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/thread/thread_read_marker.dart';

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

    expect(_sent, [_replyA]);
  });

  test(
    'the same reply read again once the server took it: no receipt',
    () async {
      final first = _marker.read(_replyA);
      _pending[_replyA]!.complete();
      await first;

      await _readNow(_replyA);

      expect(_sent, [_replyA]);
    },
  );

  test('the same reply read again after a failure: sent again', () async {
    final first = _marker.read(_replyA);
    _pending[_replyA]!.completeError(Exception('offline'));
    await first.catchError((Object _) {});

    await _readNow(_replyA);

    expect(_sent, [_replyA, _replyA]);
  });

  test('a newer reply while the receipt of the previous one is on its '
      'way: sent', () async {
    unawaited(_marker.read(_replyA));
    await _readNow(_replyB);

    expect(_sent, [_replyA, _replyB]);
  });
}

const _replyA = r'$replyA';
const _replyB = r'$replyB';

late List<String> _sent;

/// The receipts on their way, by event id: each test answers them.
late Map<String, Completer<void>> _pending;
late ThreadReadMarker _marker;

Future<void> _send(String eventId) {
  _sent.add(eventId);
  return (_pending[eventId] = Completer<void>()).future;
}

/// Reads [eventId] and lets what it sends start, without waiting for the
/// server.
Future<void> _readNow(String eventId) async {
  unawaited(_marker.read(eventId).catchError((Object _) {}));
  await pumpEventQueue();
}
