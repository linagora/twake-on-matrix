import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/presentation/mixins/event_filter_mixin.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

class MockEventFilterMixin with EventFilterMixin {}

void main() {
  late MockEventFilterMixin eventFilterMixin;
  late Client client;
  late Room room;

  setUpAll(() async {
    client = await getClient();
    room = Room(
      client: client,
      id: '!room:example.com',
      membership: Membership.join,
    );
  });

  setUp(() {
    eventFilterMixin = MockEventFilterMixin();
  });

  group('getAudioEventsUpToClicked', () {
    test(
      'should return events from clicked position onwards for sequential playback',
      () {
        // Arrange - Create mock events in REVERSE chronological order (newest first)
        // This simulates how chat displays events: newest at top, oldest at bottom
        final event5 = Event(
          content: {'body': 'audio5.ogg'},
          type: EventTypes.Message,
          eventId: 'event5',
          senderId: '@user:example.com',
          originServerTs: DateTime.now().subtract(const Duration(minutes: 1)),
          room: room,
        );

        final event4 = Event(
          content: {'body': 'audio4.ogg'},
          type: EventTypes.Message,
          eventId: 'event4',
          senderId: '@user:example.com',
          originServerTs: DateTime.now().subtract(const Duration(minutes: 2)),
          room: room,
        );

        final event3 = Event(
          content: {'body': 'audio3.ogg'},
          type: EventTypes.Message,
          eventId: 'event3',
          senderId: '@user:example.com',
          originServerTs: DateTime.now().subtract(const Duration(minutes: 3)),
          room: room,
        );

        final event2 = Event(
          content: {'body': 'audio2.ogg'},
          type: EventTypes.Message,
          eventId: 'event2',
          senderId: '@user:example.com',
          originServerTs: DateTime.now().subtract(const Duration(minutes: 4)),
          room: room,
        );

        final event1 = Event(
          content: {'body': 'audio1.ogg'},
          type: EventTypes.Message,
          eventId: 'event1',
          senderId: '@user:example.com',
          originServerTs: DateTime.now().subtract(const Duration(minutes: 5)),
          room: room,
        );

        // Chat order: [event5, event4, event3, event2, event1] (newest first)
        final audioEvents = [event5, event4, event3, event2, event1];

        // Act - User clicks on event3 (middle event in chat)
        final result = eventFilterMixin.getAudioEventsUpToClicked(
          audioEvents,
          event3,
        );

        expect(result.length, 3);
        expect(result[0].eventId, 'event3'); // Oldest (plays first)
        expect(result[1].eventId, 'event4'); // Middle
        expect(result[2].eventId, 'event5'); // Clicked event (plays last)
      },
    );

    test('should return single event when clicked on oldest event', () {
      final event1 = Event(
        content: {'body': 'audio1.ogg'},
        type: EventTypes.Message,
        eventId: 'event1',
        senderId: '@user:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 3)),
        room: room,
      );

      final event2 = Event(
        content: {'body': 'audio2.ogg'},
        type: EventTypes.Message,
        eventId: 'event2',
        senderId: '@user:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 2)),
        room: room,
      );

      final event3 = Event(
        content: {'body': 'audio3.ogg'},
        type: EventTypes.Message,
        eventId: 'event3',
        senderId: '@user:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 1)),
        room: room,
      );

      final audioEvents = [event3, event2, event1];

      final result = eventFilterMixin.getAudioEventsUpToClicked(
        audioEvents,
        event1,
      );

      expect(result.length, 3);
      expect(result[0].eventId, 'event1');
      expect(result[1].eventId, 'event2');
      expect(result[2].eventId, 'event3');
    });

    test('should return single event when clicked on newest event', () {
      // Arrange - Chronological order: oldest first
      final event1 = Event(
        content: {'body': 'audio1.ogg'},
        type: EventTypes.Message,
        eventId: 'event1',
        senderId: '@user:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 3)),
        room: room,
      );

      final event2 = Event(
        content: {'body': 'audio2.ogg'},
        type: EventTypes.Message,
        eventId: 'event2',
        senderId: '@user:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 2)),
        room: room,
      );

      final event3 = Event(
        content: {'body': 'audio3.ogg'},
        type: EventTypes.Message,
        eventId: 'event3',
        senderId: '@user:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 1)),
        room: room,
      );

      final audioEvents = [event3, event2, event1];

      final result = eventFilterMixin.getAudioEventsUpToClicked(
        audioEvents,
        event3,
      );

      expect(result.length, 1);
      expect(result[0].eventId, 'event3'); // Newest (only this plays)
    });

    test('should return empty list when clicked event is not found', () {
      // Arrange
      final event1 = Event(
        content: {'body': 'audio1.ogg'},
        type: EventTypes.Message,
        eventId: 'event1',
        senderId: '@user:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 3)),
        room: room,
      );

      final event2 = Event(
        content: {'body': 'audio2.ogg'},
        type: EventTypes.Message,
        eventId: 'event2',
        senderId: '@user:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 2)),
        room: room,
      );

      final clickedEvent = Event(
        content: {'body': 'audio_not_in_list.ogg'},
        type: EventTypes.Message,
        eventId: 'event_not_found',
        senderId: '@user:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 1)),
        room: room,
      );

      final audioEvents = [event1, event2];

      // Act - User clicks on event that's not in the list
      final result = eventFilterMixin.getAudioEventsUpToClicked(
        audioEvents,
        clickedEvent,
      );

      // Assert - Should return empty list
      expect(result, []);
    });

    test('should handle single event list', () {
      // Arrange
      final singleEvent = Event(
        content: {'body': 'audio1.ogg'},
        type: EventTypes.Message,
        eventId: 'event1',
        senderId: '@user:example.com',
        originServerTs: DateTime.now(),
        room: room,
      );

      final audioEvents = [singleEvent];

      // Act
      final result = eventFilterMixin.getAudioEventsUpToClicked(
        audioEvents,
        singleEvent,
      );

      // Assert
      expect(result.length, 1);
      expect(result[0].eventId, 'event1');
    });

    test('should handle empty event list', () {
      // Arrange
      final clickedEvent = Event(
        content: {'body': 'audio1.ogg'},
        type: EventTypes.Message,
        eventId: 'event1',
        senderId: '@user:example.com',
        originServerTs: DateTime.now(),
        room: room,
      );

      final audioEvents = <Event>[];

      // Act
      final result = eventFilterMixin.getAudioEventsUpToClicked(
        audioEvents,
        clickedEvent,
      );

      // Assert
      expect(result, []);
    });

    test('should maintain chronological order for sequential playback', () {
      final now = DateTime.now();
      final event1 = Event(
        content: {'body': 'audio1.ogg'},
        type: EventTypes.Message,
        eventId: 'event1',
        senderId: '@user:example.com',
        originServerTs: now.subtract(const Duration(minutes: 10)),
        room: room,
      );

      final event2 = Event(
        content: {'body': 'audio2.ogg'},
        type: EventTypes.Message,
        eventId: 'event2',
        senderId: '@user:example.com',
        originServerTs: now.subtract(const Duration(minutes: 8)),
        room: room,
      );

      final event3 = Event(
        content: {'body': 'audio3.ogg'},
        type: EventTypes.Message,
        eventId: 'event3',
        senderId: '@user:example.com',
        originServerTs: now.subtract(const Duration(minutes: 6)),
        room: room,
      );

      final event4 = Event(
        content: {'body': 'audio4.ogg'},
        type: EventTypes.Message,
        eventId: 'event4',
        senderId: '@user:example.com',
        originServerTs: now.subtract(const Duration(minutes: 4)),
        room: room,
      );

      final audioEvents = [event4, event3, event2, event1];

      final result = eventFilterMixin.getAudioEventsUpToClicked(
        audioEvents,
        event2,
      );

      expect(result.length, 3);
      expect(result[0].eventId, 'event2'); // Clicked event
      expect(result[1].eventId, 'event3');
      expect(result[2].eventId, 'event4'); // Newest

      expect(
        result[0].originServerTs.isBefore(result[1].originServerTs),
        true,
      );
      expect(
        result[1].originServerTs.isBefore(result[2].originServerTs),
        true,
      );
    });

    test('should work correctly with events from different senders', () {
      // Arrange - Chronological order: oldest first
      final event1 = Event(
        content: {'body': 'audio1.ogg'},
        type: EventTypes.Message,
        eventId: 'event1',
        senderId: '@alice:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 5)),
        room: room,
      );

      final event2 = Event(
        content: {'body': 'audio2.ogg'},
        type: EventTypes.Message,
        eventId: 'event2',
        senderId: '@bob:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 4)),
        room: room,
      );

      final event3 = Event(
        content: {'body': 'audio3.ogg'},
        type: EventTypes.Message,
        eventId: 'event3',
        senderId: '@alice:example.com',
        originServerTs: DateTime.now().subtract(const Duration(minutes: 3)),
        room: room,
      );

      final audioEvents = [event3, event2, event1];

      final result = eventFilterMixin.getAudioEventsUpToClicked(
        audioEvents,
        event2,
      );

      expect(result.length, 2);
      expect(result[0].eventId, 'event2');
      expect(result[0].senderId, '@bob:example.com');
      expect(result[1].eventId, 'event3');
      expect(result[1].senderId, '@alice:example.com');
    });

    test('should handle large list of events efficiently', () {
      // Arrange - Create 100 events in REVERSE CHRONOLOGICAL ORDER (newest first, like UI)
      final now = DateTime.now();
      final audioEvents = List.generate(
        100,
        (index) => Event(
          content: {'body': 'audio$index.ogg'},
          type: EventTypes.Message,
          eventId: 'event$index',
          senderId: '@user:example.com',
          // Event 0 (newest) has smallest time offset
          originServerTs: now.subtract(Duration(minutes: index + 1)),
          room: room,
        ),
      );

      // Click on event at index 49 (which is event49)
      final clickedEvent = audioEvents[49];

      // Act
      final result = eventFilterMixin.getAudioEventsUpToClicked(
        audioEvents,
        clickedEvent,
      );
      expect(result.length, 50);
      expect(result.first.eventId, 'event49');
      expect(result.last.eventId, 'event0');
    });
  });
}
