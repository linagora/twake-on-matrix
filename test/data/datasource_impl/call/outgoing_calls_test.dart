import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource_impl/call/outgoing_calls.dart';

final _startedAt = DateTime.fromMillisecondsSinceEpoch(1000);
final _answeredAt = DateTime.fromMillisecondsSinceEpoch(4000);
final _laterAnswer = DateTime.fromMillisecondsSinceEpoch(6000);
final _endedAt = DateTime.fromMillisecondsSinceEpoch(10000);

void main() {
  late OutgoingCalls calls;

  setUp(() => calls = OutgoingCalls());

  Map<String, Object?>? end(DateTime at) {
    calls.close('!room', at);
    return calls.end('!room');
  }

  void start({bool isVideo = false}) => calls.rang(
    calls.start('!room', isVideo: isVideo, startedAt: _startedAt),
    r'$ring',
  );

  test('an answered call ends with its answer, its end and its ring', () {
    start(isVideo: true);
    calls.answer('!room', _answeredAt);

    expect(end(_endedAt), {
      'intent': 'video',
      'started_ts': 1000,
      'answered_ts': 4000,
      'ended_ts': 10000,
      'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$ring'},
    });
  });

  test('a call nobody answered ends without an answer', () {
    start();

    expect(end(_endedAt), {
      'intent': 'audio',
      'started_ts': 1000,
      'ended_ts': 10000,
      'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$ring'},
    });
  });

  test('the first answer counts', () {
    start();
    calls.answer('!room', _answeredAt);
    calls.answer('!room', _laterAnswer);

    expect(end(_endedAt)?['answered_ts'], 4000);
  });

  test('a call ends once', () {
    start();
    end(_endedAt);

    expect(end(_endedAt), isNull);
  });

  test('a call this device did not ring has no line', () {
    calls.answer('!room', _answeredAt);

    expect(calls.isRinging('!room'), isFalse);
    expect(end(_endedAt), isNull);
  });

  test('a forgotten call has no line', () {
    start();
    calls.forget('!room');

    expect(end(_endedAt), isNull);
  });

  test('a call ended before its ring was sent ends once the ring is', () {
    final call = calls.start('!room', isVideo: false, startedAt: _startedAt);

    expect(end(_endedAt), isNull);
    calls.answer('!room', _answeredAt);

    expect(calls.rang(call, r'$ring'), {
      'intent': 'audio',
      'started_ts': 1000,
      'ended_ts': 10000,
      'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$ring'},
    });
    expect(calls.isRinging('!room'), isFalse);
  });

  test('an answer during the ring send counts', () {
    final call = calls.start('!room', isVideo: false, startedAt: _startedAt);
    calls.answer('!room', _answeredAt);

    expect(calls.rang(call, r'$ring'), isNull);
    expect(end(_endedAt)?['answered_ts'], 4000);
  });

  test('a late ring of a hung-up call leaves the redial alone', () {
    final first = calls.start('!room', isVideo: false, startedAt: _startedAt);
    end(_answeredAt);
    final redial = calls.start('!room', isVideo: true, startedAt: _laterAnswer);

    expect(calls.rang(first, r'$first')?['ended_ts'], 4000);
    expect(calls.rang(redial, r'$redial'), isNull);
    expect(end(_endedAt)?['m.relates_to'], {
      'rel_type': 'm.reference',
      'event_id': r'$redial',
    });
  });

  test('a late failed ring of a hung-up call leaves the redial alone', () {
    final first = calls.start('!room', isVideo: false, startedAt: _startedAt);
    end(_answeredAt);
    final redial = calls.start('!room', isVideo: true, startedAt: _laterAnswer);

    calls.dropRing('!room', first);

    expect(calls.isRinging('!room'), isTrue);
    expect(calls.rang(first, r'$first'), isNull);
    calls.rang(redial, r'$redial');
    expect(end(_endedAt)?['intent'], 'video');
  });

  test('an answer after the hang-up does not count', () {
    start();
    calls.close('!room', _answeredAt);
    calls.answer('!room', _laterAnswer);

    expect(calls.end('!room'), {
      'intent': 'audio',
      'started_ts': 1000,
      'ended_ts': 4000,
      'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$ring'},
    });
  });
}
