import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/call/call_line.dart';

Map<String, Object?> _content({
  Object? intent = 'audio',
  Object? answeredTs,
  Object? endedTs = 10000,
}) => {
  'intent': ?intent,
  'started_ts': 1000,
  'answered_ts': ?answeredTs,
  'ended_ts': ?endedTs,
  'm.relates_to': {'rel_type': 'm.reference', 'event_id': r'$ring'},
};

void main() {
  group('CallLine.fromContent', () {
    test('an answered call of someone else is incoming, with its duration', () {
      final line = CallLine.fromContent(
        _content(answeredTs: 4000),
        isOwn: false,
      );

      expect(
        line,
        const CallLine(
          isOutgoing: false,
          isVideo: false,
          outcome: CallLineOutcome.answered,
          duration: Duration(seconds: 6),
        ),
      );
    });

    test('an answered call of the user is outgoing, with its duration', () {
      final line = CallLine.fromContent(
        _content(intent: 'video', answeredTs: 4000),
        isOwn: true,
      );

      expect(
        line,
        const CallLine(
          isOutgoing: true,
          isVideo: true,
          outcome: CallLineOutcome.answered,
          duration: Duration(seconds: 6),
        ),
      );
    });

    test('a call nobody answered is missed for the others', () {
      final line = CallLine.fromContent(_content(), isOwn: false);

      expect(line?.outcome, CallLineOutcome.missed);
      expect(line?.duration, isNull);
    });

    test('a call nobody answered is canceled for the caller', () {
      final line = CallLine.fromContent(_content(), isOwn: true);

      expect(line?.outcome, CallLineOutcome.canceled);
      expect(line?.duration, isNull);
    });

    final invalid = <String, Map<String, Object?>>{
      'no intent': _content(intent: null),
      'an unknown intent': _content(intent: 'screen'),
      'no end': _content(endedTs: null),
      'an end that is not a date': _content(endedTs: '10000'),
      'an answer that is not a date': _content(answeredTs: '4000'),
      'an answer after the end': _content(answeredTs: 20000),
    };

    invalid.forEach((name, content) {
      test('$name is no call line', () {
        expect(CallLine.fromContent(content, isOwn: false), isNull);
      });
    });
  });
}
