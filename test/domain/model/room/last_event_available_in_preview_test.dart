// ignore_for_file: depend_on_referenced_packages

import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/domain/model/room/room_preview_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../../../fake_client.dart';

Future<Client> _clientWithDatabase(DatabaseApi database) async {
  if (!vod.isInitialized()) {
    await vod.init(libraryPath: './vodozemac/debug/');
  }
  final client = Client(
    'testclient',
    httpClient: FakeMatrixApi(),
    database: database,
  );
  await client.checkHomeserver(
    Uri.parse('https://fakeServer.notExisting'),
    checkWellKnown: false,
  );
  await client.init(
    newToken: 'abcd',
    newUserID: '@admin:fakeServer',
    newHomeserver: client.homeserver,
    newDeviceName: 'Text Matrix Client',
    newDeviceID: 'GHTYAJCE',
  );
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return client;
}

/// [MockDatabase] with a configurable [getEventList] for preview tests.
class FixedEventListDatabase extends MockDatabase {
  final List<Event> events = [];

  @override
  Future<List<Event>> getEventList(
    Room room, {
    int start = 0,
    bool onlySending = false,
    int? limit,
  }) async => List<Event>.from(events);
}

class ThrowingGetEventListDatabase extends MockDatabase {
  @override
  Future<List<Event>> getEventList(
    Room room, {
    int start = 0,
    bool onlySending = false,
    int? limit,
  }) async => Future.error(Exception('database error'));
}

Room _room(Client client) => Room(
  client: client,
  id: '!preview_room:test.local',
  membership: Membership.join,
  notificationCount: 0,
  highlightCount: 0,
  prev_batch: '',
);

Event _message(Room room, String eventId, DateTime ts) => Event(
  content: {'msgtype': 'm.text', 'body': 'hello'},
  type: EventTypes.Message,
  eventId: eventId,
  senderId: '@alice:test.local',
  originServerTs: ts,
  room: room,
);

Event _reaction(Room room, String eventId, DateTime ts) => Event(
  content: {
    'm.relates_to': {
      'rel_type': RelationshipTypes.reaction,
      'event_id': '\$target',
    },
    'm.new': '👍',
  },
  type: EventTypes.Reaction,
  eventId: eventId,
  senderId: '@alice:test.local',
  originServerTs: ts,
  room: room,
);

Event _roomCreate(Room room, String eventId, DateTime ts) => Event(
  content: {'creator': '@alice:test.local'},
  type: EventTypes.RoomCreate,
  eventId: eventId,
  senderId: '@alice:test.local',
  originServerTs: ts,
  room: room,
  stateKey: '',
);

void main() {
  group('lastEventAvailableInPreview', () {
    test(
      'returns RoomPreviewFound when DB contains an eligible message',
      () async {
        final db = FixedEventListDatabase();
        final client = await _clientWithDatabase(db);
        final room = _room(client);
        db.events.add(_message(room, '\$1', DateTime.utc(2024, 1, 2)));

        final result = await room.lastEventAvailableInPreview();

        expect(result, isA<RoomPreviewFound>());
        expect((result as RoomPreviewFound).event.type, EventTypes.Message);
        expect(result.event.eventId, '\$1');
      },
    );

    test('returns RoomPreviewEmpty when m.room.create is in the window '
        'and no eligible preview exists', () async {
      final db = FixedEventListDatabase();
      final client = await _clientWithDatabase(db);
      final room = _room(client);
      final ts = DateTime.utc(2024, 1, 1);
      db.events.addAll([
        _reaction(room, '\$r1', ts.add(const Duration(seconds: 2))),
        _roomCreate(room, '\$create', ts),
      ]);

      final result = await room.lastEventAvailableInPreview();

      expect(result, isA<RoomPreviewEmpty>());
    });

    test('returns RoomPreviewUnavailable when there are events '
        'but no m.room.create and no eligible preview', () async {
      final db = FixedEventListDatabase();
      final client = await _clientWithDatabase(db);
      final room = _room(client);
      final base = DateTime.utc(2024, 1, 1);
      for (var i = 0; i < 5; i++) {
        db.events.add(_reaction(room, '\$r$i', base.add(Duration(seconds: i))));
      }

      final result = await room.lastEventAvailableInPreview();

      expect(result, isA<RoomPreviewUnavailable>());
    });

    test(
      'returns RoomPreviewFound when both reactions and a message appear',
      () async {
        final db = FixedEventListDatabase();
        final client = await _clientWithDatabase(db);
        final room = _room(client);
        final base = DateTime.utc(2024, 1, 1);
        db.events.addAll([
          _reaction(room, '\$r1', base),
          _message(room, '\$m1', base.add(const Duration(seconds: 1))),
          _roomCreate(room, '\$c', base.subtract(const Duration(days: 1))),
        ]);

        final result = await room.lastEventAvailableInPreview();

        expect(result, isA<RoomPreviewFound>());
        expect((result as RoomPreviewFound).event.eventId, '\$m1');
      },
    );

    test('returns RoomPreviewUnavailable when getEventList fails', () async {
      final client = await _clientWithDatabase(ThrowingGetEventListDatabase());
      final room = _room(client);

      final result = await room.lastEventAvailableInPreview();

      expect(result, isA<RoomPreviewUnavailable>());
    });

    test(
      'returns RoomPreviewUnavailable when DB returns an empty event list',
      () async {
        final db = FixedEventListDatabase();
        final client = await _clientWithDatabase(db);
        final room = _room(client);

        final result = await room.lastEventAvailableInPreview();

        expect(result, isA<RoomPreviewUnavailable>());
      },
    );
  });
}
