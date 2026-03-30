import 'package:fluffychat/utils/logging/sentry_tracked_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SentryTrackedEvents', () {
    group('enum values', () {
      test('should contain missingLastMessage event', () {
        expect(
          SentryTrackedEvents.values,
          contains(SentryTrackedEvents.missingLastMessage),
        );
      });

      test('should contain wrongMemberCount event', () {
        expect(
          SentryTrackedEvents.values,
          contains(SentryTrackedEvents.wrongMemberCount),
        );
      });

      test('should contain failedToLoadTimeline event', () {
        expect(
          SentryTrackedEvents.values,
          contains(SentryTrackedEvents.failedToLoadTimeline),
        );
      });
    });

    group('message strings', () {
      test('missingLastMessage has correct message string', () {
        expect(
          SentryTrackedEvents.missingLastMessage.message,
          'Missing-last-message',
        );
      });

      test('wrongMemberCount has correct message string', () {
        expect(
          SentryTrackedEvents.wrongMemberCount.message,
          'Wrong-member-count',
        );
      });

      test('failedToLoadTimeline has correct message string', () {
        expect(
          SentryTrackedEvents.failedToLoadTimeline.message,
          'Failed to load timeline',
        );
      });
    });

    group('isExample flag', () {
      test('missingLastMessage is not an example event', () {
        expect(SentryTrackedEvents.missingLastMessage.isExample, isFalse);
      });

      test('wrongMemberCount is not an example event', () {
        expect(SentryTrackedEvents.wrongMemberCount.isExample, isFalse);
      });

      test('failedToLoadTimeline is an example event', () {
        expect(SentryTrackedEvents.failedToLoadTimeline.isExample, isTrue);
      });
    });

    group('active getter', () {
      test('should exclude example events', () {
        final active = SentryTrackedEvents.active.toList();
        expect(
          active,
          isNot(contains(SentryTrackedEvents.failedToLoadTimeline)),
        );
      });

      test('should include missingLastMessage', () {
        expect(
          SentryTrackedEvents.active,
          contains(SentryTrackedEvents.missingLastMessage),
        );
      });

      test('should include wrongMemberCount', () {
        expect(
          SentryTrackedEvents.active,
          contains(SentryTrackedEvents.wrongMemberCount),
        );
      });

      test('should return only non-example events', () {
        final allValues = SentryTrackedEvents.values;
        final exampleCount = allValues.where((e) => e.isExample).length;
        final activeCount = SentryTrackedEvents.active.length;
        expect(activeCount, allValues.length - exampleCount);
      });

      // Boundary/regression: active is an Iterable, not a fixed list;
      // calling it twice should yield the same events.
      test('active is stable across multiple calls', () {
        final first = SentryTrackedEvents.active.toList();
        final second = SentryTrackedEvents.active.toList();
        expect(first, equals(second));
      });
    });
  });
}