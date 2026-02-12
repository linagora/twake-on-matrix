import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/pages/chat/events/audio_message/audio_play_extension.dart';

void main() {
  group('DurationExtension', () {
    test(
      'minuteSecondString returns correct format for less than 1 minute',
      () {
        const duration = Duration(seconds: 30);
        expect(duration.minuteSecondString, '00:30');
      },
    );

    test('minuteSecondString returns correct format for exactly 1 minute', () {
      const duration = Duration(minutes: 1);
      expect(duration.minuteSecondString, '01:00');
    });

    test(
      'minuteSecondString returns correct format for multiple minutes and seconds',
      () {
        const duration = Duration(minutes: 2, seconds: 5);
        expect(duration.minuteSecondString, '02:05');
      },
    );

    test('minuteSecondString returns correct format for 0 duration', () {
      const duration = Duration(seconds: 0);
      expect(duration.minuteSecondString, '00:00');
    });

    test(
      'minuteSecondString returns correct format for duration over an hour',
      () {
        const duration = Duration(hours: 1, minutes: 5, seconds: 10);
        expect(duration.minuteSecondString, '65:10'); // inMinutes will be 65
      },
    );

    test('minuteSecondString handles seconds padding correctly', () {
      const duration = Duration(seconds: 5);
      expect(duration.minuteSecondString, '00:05');
    });

    test('minuteSecondString handles minutes padding correctly', () {
      const duration = Duration(minutes: 5, seconds: 30);
      expect(duration.minuteSecondString, '05:30');
    });

    test('minuteSecondString returns correct format for 3 hours', () {
      const duration = Duration(hours: 3);
      expect(duration.minuteSecondString, '180:00');
    });
  });
}
