import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_list_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

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

  group('EventListExtension.copyableEvents', () {
    Event message({
      required String eventId,
      required int timestamp,
      String type = EventTypes.Message,
      String msgtype = MessageTypes.Text,
    }) {
      return Event(
        senderId: '@user:example.com',
        type: type,
        room: room,
        eventId: eventId,
        content: {'msgtype': msgtype, 'body': eventId},
        originServerTs: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    }

    List<String> idsOf(List<Event> events) =>
        events.map((event) => event.eventId).toList();

    test('sorts text events chronologically, whatever the selection order', () {
      final events = [
        message(eventId: 'third', timestamp: 3),
        message(eventId: 'first', timestamp: 1),
        message(eventId: 'second', timestamp: 2),
      ];

      expect(idsOf(events.copyableEvents), ['first', 'second', 'third']);
    });

    test('keeps notices and emotes', () {
      final events = [
        message(eventId: 'notice', timestamp: 1, msgtype: MessageTypes.Notice),
        message(eventId: 'emote', timestamp: 2, msgtype: MessageTypes.Emote),
      ];

      expect(idsOf(events.copyableEvents), ['notice', 'emote']);
    });

    test(
      'keeps text and file messages, skips stickers and encrypted events',
      () {
        final events = [
          message(eventId: 'text', timestamp: 1),
          message(eventId: 'image', timestamp: 2, msgtype: MessageTypes.Image),
          message(eventId: 'file', timestamp: 3, msgtype: MessageTypes.File),
          message(eventId: 'video', timestamp: 4, msgtype: MessageTypes.Video),
          message(eventId: 'audio', timestamp: 5, msgtype: MessageTypes.Audio),
          message(
            eventId: 'location',
            timestamp: 6,
            msgtype: MessageTypes.Location,
          ),
          message(eventId: 'sticker', timestamp: 7, type: EventTypes.Sticker),
          message(
            eventId: 'encrypted',
            timestamp: 8,
            type: EventTypes.Encrypted,
          ),
        ];

        expect(idsOf(events.copyableEvents), [
          'text',
          'image',
          'file',
          'video',
          'audio',
        ]);
      },
    );

    test('skips redacted messages', () {
      final redacted = message(eventId: 'redacted', timestamp: 2)
        ..setRedactionEvent(
          Event(
            senderId: '@user:example.com',
            type: EventTypes.Redaction,
            room: room,
            eventId: 'redaction',
            redacts: 'redacted',
            content: {},
            originServerTs: DateTime.fromMillisecondsSinceEpoch(3),
          ),
        );
      final events = [message(eventId: 'text', timestamp: 1), redacted];

      expect(idsOf(events.copyableEvents), ['text']);
    });

    test('returns an empty list when nothing is copyable', () {
      final events = [
        message(eventId: 'sticker', timestamp: 1, type: EventTypes.Sticker),
      ];

      expect(events.copyableEvents, isEmpty);
    });
  });

  group('EventListExtension.copyTexts', () {
    late List<String> copiedTexts;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime at(DateTime day, int hour, int minute) =>
        DateTime(day.year, day.month, day.day, hour, minute);

    setUpAll(() {
      if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
        GetIt.instance.registerSingleton(ResponsiveUtils());
      }
      room.setState(
        Event(
          senderId: '@alice:example.com',
          type: EventTypes.RoomMember,
          room: room,
          eventId: '\$alice-member',
          stateKey: '@alice:example.com',
          content: {'membership': 'join', 'displayname': 'Alice'},
          originServerTs: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    });

    setUp(() {
      copiedTexts = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedTexts.add((call.arguments as Map)['text'] as String);
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Event messageFromAlice(
      Map<String, Object?> content, {
      required DateTime sentAt,
    }) {
      return Event(
        senderId: '@alice:example.com',
        type: EventTypes.Message,
        room: room,
        eventId: '\$${sentAt.millisecondsSinceEpoch}',
        content: content,
        originServerTs: sentAt,
      );
    }

    Event textMessage(String body, {required DateTime sentAt}) =>
        messageFromAlice({
          'msgtype': MessageTypes.Text,
          'body': body,
        }, sentAt: sentAt);

    Event replyWithoutText({required DateTime sentAt}) => messageFromAlice({
      'msgtype': MessageTypes.Text,
      'body': '> <@other:example.com> quoted',
      'm.relates_to': {
        'm.in_reply_to': {'event_id': '\$quoted'},
      },
    }, sentAt: sentAt);

    Future<void> copy(WidgetTester tester, List<Event> events) async {
      final timeline = Timeline(
        room: room,
        chunk: TimelineChunk(events: []),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => events.copyTexts(context, timeline),
                child: const Text('copy'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('copy'));
      await tester.pump();
    }

    final copiedSnackBar = find.text(
      lookupL10n(const Locale('en')).textCopiedToClipboard,
    );

    testWidgets(
      'copies each message under its author and time, in timeline order',
      (tester) async {
        await copy(tester, [
          textMessage('second', sentAt: at(today, 9, 5)),
          textMessage('first\non two lines', sentAt: at(yesterday, 18, 30)),
        ]);

        expect(copiedTexts, [
          'Alice, Yesterday 18:30\nfirst\non two lines\n\n'
              'Alice, Today 09:05\nsecond',
        ]);
        expect(copiedSnackBar, findsOneWidget);
      },
    );

    testWidgets('copies a captioned file with its caption', (tester) async {
      await copy(tester, [
        textMessage('look', sentAt: at(today, 9, 0)),
        messageFromAlice({
          'msgtype': MessageTypes.Image,
          'body': 'the caption',
          'filename': 'photo.png',
        }, sentAt: at(today, 9, 1)),
      ]);

      expect(copiedTexts, [
        'Alice, Today 09:00\nlook\n\nAlice, Today 09:01\nthe caption',
      ]);
    });

    testWidgets('copies a file without caption with its name', (tester) async {
      await copy(tester, [
        messageFromAlice({
          'msgtype': MessageTypes.File,
          'body': 'report.pdf',
        }, sentAt: at(today, 9, 0)),
        messageFromAlice({
          'msgtype': MessageTypes.Image,
          'body': '',
          'filename': 'photo.png',
        }, sentAt: at(today, 9, 1)),
      ]);

      expect(copiedTexts, [
        'Alice, Today 09:00\nreport.pdf\n\nAlice, Today 09:01\nphoto.png',
      ]);
    });

    testWidgets('leaves empty texts out', (tester) async {
      await copy(tester, [
        textMessage('first', sentAt: at(today, 9, 0)),
        replyWithoutText(sentAt: at(today, 9, 1)),
        textMessage('third', sentAt: at(today, 9, 2)),
      ]);

      expect(copiedTexts, [
        'Alice, Today 09:00\nfirst\n\nAlice, Today 09:02\nthird',
      ]);
    });

    testWidgets('does nothing when no text can be copied', (tester) async {
      await copy(tester, [replyWithoutText(sentAt: at(today, 9, 0))]);

      expect(copiedTexts, isEmpty);
      expect(copiedSnackBar, findsNothing);
    });
  });
}
