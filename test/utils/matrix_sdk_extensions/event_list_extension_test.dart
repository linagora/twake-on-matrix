import 'package:fluffychat/utils/matrix_sdk_extensions/event_list_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

void main() {
  late Client client;
  late Room room;

  setUpAll(() async {
    client = await getClient();
    room = Room(
      client: client,
      id: '!test:example.com',
      membership: Membership.join,
    );
  });

  Event createEvent({
    required String eventId,
    String? transactionId,
    String body = 'test',
    int timestamp = 1234567890,
  }) {
    return Event(
      senderId: '@user:example.com',
      type: 'm.room.message',
      room: room,
      eventId: eventId,
      content: {'body': body},
      originServerTs: DateTime.fromMillisecondsSinceEpoch(timestamp),
      unsigned: transactionId != null
          ? {'transaction_id': transactionId}
          : null,
    );
  }

  group('EventListExtension.buildEventMap', () {
    test('should create map with eventId as key', () {
      final event = createEvent(eventId: '\$event1');
      final map = EventListExtension.buildEventMap([event]);

      expect(map['\$event1'], event);
      expect(map.length, 1);
    });

    test('should create map with both eventId and transactionId as keys', () {
      final event = createEvent(eventId: '\$event1', transactionId: 'txn123');
      final map = EventListExtension.buildEventMap([event]);

      expect(map['\$event1'], event);
      expect(map['txn123'], event);
      expect(map.length, 2);
    });

    test('should handle multiple events', () {
      final event1 = createEvent(eventId: '\$event1', body: 'test1');
      final event2 = createEvent(
        eventId: '\$event2',
        transactionId: 'txn456',
        body: 'test2',
      );

      final map = EventListExtension.buildEventMap([event1, event2]);

      expect(map['\$event1'], event1);
      expect(map['\$event2'], event2);
      expect(map['txn456'], event2);
      expect(map.length, 3);
    });
  });

  group('EventListExtension.syncEventLists', () {
    test('should return empty lists when events are completely different', () {
      final oldEvent = createEvent(eventId: '\$old1', body: 'old');
      final newEvent = createEvent(eventId: '\$new1', body: 'new');

      final result = EventListExtension.syncEventLists(
        oldEvents: [oldEvent],
        newEvents: [newEvent],
        currentTop: [],
        currentBottom: [oldEvent],
        wasRequestingFuture: false,
      );

      expect(result.top, isEmpty);
      expect(result.bottom.length, 1);
      expect(result.bottom.first, newEvent);
    });

    test('should remove deleted events from bottom list', () {
      final event1 = createEvent(eventId: '\$event1', body: 'test1');
      final event2 = createEvent(eventId: '\$event2', body: 'test2');
      final event3 = createEvent(eventId: '\$event3', body: 'test3');

      final result = EventListExtension.syncEventLists(
        oldEvents: [event1, event2, event3],
        newEvents: [event1, event3], // event2 removed
        currentTop: [],
        currentBottom: [event1, event2, event3],
        wasRequestingFuture: false,
      );

      expect(result.bottom.length, 2);
      expect(result.bottom[0].eventId, '\$event1');
      expect(result.bottom[1].eventId, '\$event3');
    });

    test('should update changed events (sending -> sent)', () {
      final sendingEvent = createEvent(
        eventId: 'txn123',
        transactionId: 'txn123',
      );
      final sentEvent = createEvent(
        eventId: '\$event1',
        transactionId: 'txn123',
      );

      final result = EventListExtension.syncEventLists(
        oldEvents: [sendingEvent],
        newEvents: [sentEvent],
        currentTop: [],
        currentBottom: [sendingEvent],
        wasRequestingFuture: false,
      );

      expect(result.bottom.length, 1);
      expect(result.bottom.first.eventId, '\$event1');
    });

    test('should add new events at the end to bottom list', () {
      final event1 = createEvent(eventId: '\$event1', body: 'test1');
      final event2 = createEvent(eventId: '\$event2', body: 'test2');
      final event3 = createEvent(eventId: '\$event3', body: 'test3');

      final result = EventListExtension.syncEventLists(
        oldEvents: [event1, event2],
        newEvents: [event1, event2, event3],
        currentTop: [],
        currentBottom: [event1, event2],
        wasRequestingFuture: false,
      );

      expect(result.bottom.length, 3);
      expect(result.bottom[2].eventId, '\$event3');
    });

    test('should add new events at the start to top list', () {
      final event1 = createEvent(eventId: '\$event1', body: 'test1');
      final event2 = createEvent(eventId: '\$event2', body: 'test2');
      final event3 = createEvent(eventId: '\$event3', body: 'test3');

      final result = EventListExtension.syncEventLists(
        oldEvents: [event2, event3],
        newEvents: [event1, event2, event3],
        currentTop: [],
        currentBottom: [event2, event3],
        wasRequestingFuture: false,
      );

      expect(result.top.length, 1);
      expect(result.top[0].eventId, '\$event1');
    });

    test('should not add duplicates when events exist in both lists', () {
      final event1 = createEvent(eventId: '\$event1', body: 'test1');
      final event2 = createEvent(eventId: '\$event2', body: 'test2');

      final result = EventListExtension.syncEventLists(
        oldEvents: [event1],
        newEvents: [event1, event2],
        currentTop: [event1],
        currentBottom: [],
        wasRequestingFuture: false,
      );

      // event1 already in top, so only event2 should be added to bottom
      expect(result.top.length, 1);
      expect(result.bottom.length, 1);
      expect(result.bottom[0].eventId, '\$event2');
    });

    test('should handle complex scenario with multiple operations', () {
      final event1 = createEvent(eventId: '\$event1', body: 'test1');
      final sendingEvent = createEvent(
        eventId: 'txn123',
        transactionId: 'txn123',
        body: 'test2',
      );
      final sentEvent = createEvent(
        eventId: '\$event2',
        transactionId: 'txn123',
        body: 'test2',
      );
      final event3 = createEvent(eventId: '\$event3', body: 'test3');
      final event4 = createEvent(eventId: '\$event4', body: 'test4');

      // Start with event1 and sendingEvent
      // Update to: event1, sentEvent (updated), event3 (new at end), event4 (new at end)
      final result = EventListExtension.syncEventLists(
        oldEvents: [event1, sendingEvent],
        newEvents: [event1, sentEvent, event3, event4],
        currentTop: [],
        currentBottom: [event1, sendingEvent],
        wasRequestingFuture: false,
      );

      expect(result.bottom.length, 4);
      expect(result.bottom[0].eventId, '\$event1');
      expect(result.bottom[1].eventId, '\$event2'); // updated from sending
      expect(result.bottom[2].eventId, '\$event3'); // new
      expect(result.bottom[3].eventId, '\$event4'); // new
    });

    test('should handle removing sending event from middle of list', () {
      final event1 = createEvent(eventId: '\$event1', body: 'test1');
      final sendingEvent = createEvent(
        eventId: 'txn123',
        transactionId: 'txn123',
        body: 'sending',
      );
      final event3 = createEvent(eventId: '\$event3', body: 'test3');

      final result = EventListExtension.syncEventLists(
        oldEvents: [event1, sendingEvent, event3],
        newEvents: [event1, event3], // sending event removed
        currentTop: [],
        currentBottom: [event1, sendingEvent, event3],
        wasRequestingFuture: false,
      );

      expect(result.bottom.length, 2);
      expect(result.bottom[0].eventId, '\$event1');
      expect(result.bottom[1].eventId, '\$event3');
    });
  });
}
