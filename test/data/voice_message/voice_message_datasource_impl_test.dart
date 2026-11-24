import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/voice_message/datasources_impl/voice_message_datasource_impl.dart';

import '../../fake_client.dart';

const _roomId = '!room:example.org';

/// Serves [newestFirst] as the stored timeline, like the SDK database.
class _Database extends MockDatabase {
  List<Event> newestFirst = [];
  final limits = <int?>[];

  @override
  Future<List<Event>> getEventList(
    Room room, {
    int start = 0,
    bool onlySending = false,
    int? limit,
  }) async {
    limits.add(limit);
    return newestFirst.skip(start).take(limit ?? newestFirst.length).toList();
  }
}

class _Client extends Client {
  _Client(this.db) : super('voice-autoplay-test', database: db);

  final _Database db;
  late final Room room = Room(id: _roomId, client: this);

  @override
  Room? getRoomById(String id) => id == _roomId ? room : null;
}

void main() {
  late _Client client;
  late VoiceMessageDatasourceImpl datasource;
  var ts = 0;

  Event event(
    String id, {
    String msgtype = MessageTypes.Audio,
    bool voice = true,
    String? threadRootId,
    String type = EventTypes.Message,
  }) => Event(
    eventId: id,
    type: type,
    senderId: '@bob:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(++ts),
    room: client.room,
    content: {
      'msgtype': msgtype,
      'body': id,
      if (msgtype == MessageTypes.Audio) 'url': 'mxc://example.org/$id',
      if (voice) 'org.matrix.msc3245.voice': <String, Object?>{},
      if (threadRootId != null)
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': threadRootId,
        },
    },
  );

  /// [chronological] oldest first, stored newest first.
  void store(List<Event> chronological) =>
      client.db.newestFirst = chronological.reversed.toList();

  Future<String?> next(String eventId) =>
      datasource.nextVoiceMessageId(roomId: _roomId, eventId: eventId);

  setUp(() {
    client = _Client(_Database());
    datasource = VoiceMessageDatasourceImpl(client);
  });

  test('returns the voice message right after the one that ended', () async {
    store([event('v1'), event('v2'), event('v3')]);

    expect(await next('v1'), 'v2');
    expect(await next('v2'), 'v3');
  });

  test('stops at the end of the stored timeline', () async {
    store([event('v1'), event('v2')]);

    expect(await next('v2'), isNull);
  });

  test('stops at a message that is not a voice message', () async {
    store([
      event('v1'),
      event('text', msgtype: MessageTypes.Text, voice: false),
      event('v2'),
    ]);

    expect(await next('v1'), isNull);
  });

  test('stops at an audio file that is not a voice message', () async {
    store([event('v1'), event('song', voice: false), event('v2')]);

    expect(await next('v1'), isNull);
  });

  test('skips events the timeline does not show', () async {
    store([
      event('v1'),
      event(
        'reaction',
        type: EventTypes.Reaction,
        msgtype: MessageTypes.Text,
        voice: false,
      ),
      event('reply', threadRootId: 'root'),
      event('v2'),
    ]);

    expect(await next('v1'), 'v2');
  });

  test('does not chain from an audio file', () async {
    store([event('song', voice: false), event('v1')]);

    expect(await next('song'), isNull);
  });

  test('chains the replies of the same thread only', () async {
    store([
      event('root', msgtype: MessageTypes.Text, voice: false),
      event('r1', threadRootId: 'root'),
      event('main'),
      event('other', threadRootId: 'other-root'),
      event('r2', threadRootId: 'root'),
    ]);

    expect(await next('r1'), 'r2');
  });

  test('reads older pages until it finds the event', () async {
    store([
      event('v0'),
      event('v1'),
      for (var i = 0; i < 120; i++)
        event('t$i', msgtype: MessageTypes.Text, voice: false),
    ]);

    expect(await next('v0'), 'v1');
    expect(client.db.limits, [50, 100, 200]);
  });

  test('returns null for an unknown room', () async {
    expect(
      await datasource.nextVoiceMessageId(roomId: '!other:x', eventId: 'v1'),
      isNull,
    );
  });
}
