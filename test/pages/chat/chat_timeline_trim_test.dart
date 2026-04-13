import 'package:fluffychat/pages/chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

/// Unit tests for [trimEventsIfNeeded], the pure helper that backs
/// `ChatController._trimTimelineIfNeeded()`. The per-room timeline cap
/// (500 events by default) was introduced to prevent unbounded memory
/// growth during long scroll sessions — see PR #2927.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Client client;
  late Room room;

  setUpAll(() async {
    client = await getClient();
    room = Room(
      client: client,
      id: '!trim:test.abc',
      membership: Membership.join,
      prev_batch: '',
    );
  });

  Event makeEvent(int index) => Event(
    senderId: '@alice:test.abc',
    type: 'm.room.message',
    room: room,
    eventId: '\$event_$index',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(index),
    content: {'msgtype': 'm.text', 'body': 'msg $index'},
  );

  List<Event> makeEvents(int count) => List<Event>.generate(count, makeEvent);

  group('trimEventsIfNeeded', () {
    test('keepsAllEventsWhenBelowCap', () {
      final events = makeEvents(499);
      trimEventsIfNeeded(events, 500);
      expect(events.length, 499);
    });

    test('keepsAllEventsWhenExactlyAtCap', () {
      final events = makeEvents(500);
      trimEventsIfNeeded(events, 500);
      expect(events.length, 500);
    });

    test('trimsToExactlyCapWhenOneOver', () {
      final events = makeEvents(501);
      trimEventsIfNeeded(events, 500);
      expect(events.length, 500);
    });

    test('keepsNewestEventsAndDropsOldestWhenAboveCap', () {
      // Timeline events are ordered newest-first: index 0 is the most
      // recent message. After trimming, the head must be preserved.
      final events = makeEvents(650);
      final newestEventId = events.first.eventId;
      final boundaryEventId = events[499].eventId;
      final firstDroppedEventId = events[500].eventId;

      trimEventsIfNeeded(events, 500);

      expect(events.length, 500);
      expect(events.first.eventId, newestEventId);
      expect(events.last.eventId, boundaryEventId);
      expect(
        events.any((e) => e.eventId == firstDroppedEventId),
        isFalse,
        reason: 'The oldest events must be removed, not the newest.',
      );
    });

    test('simulatesRequestHistoryGrowthFrom450By200YieldsExactlyCap', () {
      // Mirrors the real flow: a timeline already holds 450 events, then
      // requestHistory() appends 200 older events to the tail (list now
      // 650 long). Trimming must bring it back to exactly 500.
      final events = makeEvents(450);
      events.addAll(List<Event>.generate(200, (i) => makeEvent(10000 + i)));
      expect(events.length, 650);

      trimEventsIfNeeded(events, 500);

      expect(events.length, 500);
    });

    test('isNoOpOnEmptyList', () {
      final events = <Event>[];
      trimEventsIfNeeded(events, 500);
      expect(events, isEmpty);
    });

    test('respectsCustomCap', () {
      final events = makeEvents(10);
      trimEventsIfNeeded(events, 3);
      expect(events.length, 3);
      expect(events.first.eventId, '\$event_0');
      expect(events.last.eventId, '\$event_2');
    });
  });
}
