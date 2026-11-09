import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_list_extension.dart';

import '../../fake_client.dart';

void main() {
  late Room room;

  setUpAll(() async {
    room = Room(
      client: await getClient(),
      id: '!test:example.com',
      membership: Membership.join,
    );
  });

  Event event(String id, int second, EventStatus status, {int minute = 24}) =>
      Event(
        senderId: '@user:example.com',
        type: 'm.room.message',
        room: room,
        eventId: id,
        content: {'body': id},
        originServerTs: DateTime.utc(2026, 11, 9, 14, minute, second),
        status: status,
      );

  List<String> order(List<Event> events) => [
    for (final e in (events..sort(compareEventsNewestFirst)).reversed)
      e.eventId,
  ];

  test('a sent image stays above the images of its send still uploading', () {
    // A was sent first and got the server time 14:24:02, B and C are
    // placeholders created at 14:23:58 and 14:23:59.
    final a = event('A', 2, EventStatus.sent);
    final b = event('B', 58, EventStatus.sending, minute: 23);
    final c = event('C', 59, EventStatus.sending, minute: 23);
    expect(order([b, c, a]), ['A', 'B', 'C']);
  });

  test('placeholders keep their creation order among themselves', () {
    expect(
      order([
        event('C', 59, EventStatus.sending),
        event('B', 58, EventStatus.sending),
        event('A', 57, EventStatus.sending),
      ]),
      ['A', 'B', 'C'],
    );
  });

  test(
    'an echo stamped "now" when its file starts to send keeps its place',
    () {
      // Transaction ids end with the creation time: A, then B, then C.
      Event echo(String name, int createdMs, int stampedSecond) => Event(
        senderId: '@user:example.com',
        type: 'm.room.message',
        room: room,
        eventId: 'Twake Chat android Debug-$name-$createdMs',
        content: {'body': name},
        originServerTs: DateTime.utc(2026, 11, 9, 14, 24, stampedSecond),
        status: EventStatus.sending,
      );
      // A and B already started to send, so the SDK stamped them later than
      // C, which still carries the time of its placeholder.
      final a = echo('120', 1794209038793, 10);
      final b = echo('121', 1794209038840, 13);
      final c = echo('122', 1794209038922, 1);
      expect(
        [
          for (final e in ([c, a, b]..sort(compareEventsNewestFirst)).reversed)
            e.eventId.split('-')[1],
        ],
        ['120', '121', '122'],
      );
    },
  );

  test('sent events keep the order of their time', () {
    expect(
      order([
        event('B', 10, EventStatus.synced),
        event('A', 5, EventStatus.sent),
        event('C', 20, EventStatus.sent),
      ]),
      ['A', 'B', 'C'],
    );
  });

  test('a failed echo stays among the echoes, in creation order', () {
    Event echo(String name, int createdMs, EventStatus status, int second) =>
        Event(
          senderId: '@user:example.com',
          type: 'm.room.message',
          room: room,
          eventId: 'Twake-$name-$createdMs',
          content: {'body': name},
          originServerTs: DateTime.utc(2026, 11, 9, 14, 24, second),
          status: status,
        );
    final sent = event('S', 30, EventStatus.synced);
    final failed = echo('1', 1794209038793, EventStatus.error, 50);
    final pending = echo('2', 1794209038840, EventStatus.sending, 5);

    expect(
      [
        for (final e in ([
          pending,
          sent,
          failed,
        ]..sort(compareEventsNewestFirst)).reversed)
          e.eventId,
      ],
      ['S', failed.eventId, pending.eventId],
    );
  });

  test('an echo whose id has no creation time is ordered by its time', () {
    Event echo(String id, int second) => Event(
      senderId: '@user:example.com',
      type: 'm.room.message',
      room: room,
      eventId: id,
      content: {'body': id},
      originServerTs: DateTime.utc(2026, 11, 9, 14, 24, second),
      status: EventStatus.sending,
    );

    expect(
      [
        for (final e in ([
          echo('x', 9),
          echo('y', 3),
        ]..sort(compareEventsNewestFirst)).reversed)
          e.eventId,
      ],
      ['y', 'x'],
    );
  });

  test(
    'a mix of echoes with and without a creation time sorts consistently',
    () {
      Event echo(String id, int second) => Event(
        senderId: '@user:example.com',
        type: 'm.room.message',
        room: room,
        eventId: id,
        content: {'body': id},
        originServerTs: DateTime.utc(2026, 11, 9, 14, 24, second),
        status: EventStatus.sending,
      );
      final events = [
        echo('Twake-1-1794209038793', 40),
        echo('Twake-2-1794209038840', 10),
        echo('plain', 25),
        echo('Twake-3-1794209038922', 5),
      ];

      // Whatever the starting order, the result is the same.
      final orders = <String>{};
      for (var i = 0; i < 24; i++) {
        final shuffled = [...events]..shuffle(Random(i));
        orders.add(shuffled.map((e) => e.eventId).toList().join());
        shuffled.sort(compareEventsNewestFirst);
        expect(shuffled.map((e) => e.eventId), [
          'Twake-3-1794209038922',
          'Twake-2-1794209038840',
          'Twake-1-1794209038793',
          'plain',
        ]);
      }
      expect(orders.length, greaterThan(1));
    },
  );

  test(
    'any input order gives the same result, and the order is antisymmetric',
    () {
      final random = Random(7);
      final statuses = [
        EventStatus.sending,
        EventStatus.error,
        EventStatus.sent,
        EventStatus.synced,
      ];
      for (var run = 0; run < 200; run++) {
        final events = [
          for (var i = 0; i < 12; i++)
            Event(
              senderId: '@user:example.com',
              type: 'm.room.message',
              room: room,
              eventId: random.nextBool()
                  ? 'Twake-$i-${1794209038000 + random.nextInt(900)}'
                  : (random.nextBool() ? 'plain$i' : '\$server$i'),
              content: {'body': '$i'},
              originServerTs: DateTime.utc(
                2026,
                11,
                9,
                14,
                24,
                random.nextInt(50),
              ),
              status: statuses[random.nextInt(4)],
            ),
        ];
        final first = ([...events]..shuffle(random))
          ..sort(compareEventsNewestFirst);
        final second = ([...events]..shuffle(random))
          ..sort(compareEventsNewestFirst);
        for (var i = 0; i < events.length; i++) {
          final a = first[i];
          final b = second[i];
          // equal ids, or two events that the order cannot tell apart
          if (a.eventId != b.eventId) {
            expect(compareEventsNewestFirst(a, b), 0);
          }
        }
        for (final a in events) {
          for (final b in events) {
            expect(
              compareEventsNewestFirst(a, b).sign,
              -compareEventsNewestFirst(b, a).sign,
            );
          }
        }
      }
    },
  );
}
