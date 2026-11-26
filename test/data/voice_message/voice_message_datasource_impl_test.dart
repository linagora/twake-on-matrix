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

  Event text(String id) => event(id, msgtype: MessageTypes.Text, voice: false);

  /// [chronological] oldest first, stored newest first.
  void store(List<Event> chronological) =>
      client.db.newestFirst = chronological.reversed.toList();

  /// Two voice messages, v0 then v1, under [count] newer texts.
  void storeUnderTexts(int count) => store([
    event('v0'),
    event('v1'),
    for (var i = 0; i < count; i++) text('t$i'),
  ]);

  Future<String?> next(String eventId, {String? threadRootId}) =>
      datasource.nextVoiceMessageId(
        roomId: _roomId,
        eventId: eventId,
        threadRootId: threadRootId,
      );

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
    store([event('v1'), text('text'), event('v2')]);

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
      text('root'),
      event('r1', threadRootId: 'root'),
      event('main'),
      event('other', threadRootId: 'other-root'),
      event('r2', threadRootId: 'root'),
    ]);

    expect(await next('r1', threadRootId: 'root'), 'r2');
  });

  test('plays the replies after a voice root on its thread screen', () async {
    store([event('root'), event('main'), event('r1', threadRootId: 'root')]);

    expect(await next('root', threadRootId: 'root'), 'r1');
  });

  test('plays the chat after a voice root in the chat', () async {
    store([event('root'), event('r1', threadRootId: 'root'), event('main')]);

    expect(await next('root'), 'main');
  });

  test('stops looking past 3200 stored events', () async {
    storeUnderTexts(3300);

    expect(await next('v0'), isNull);
    expect(client.db.limits, [50, 100, 200, 400, 800, 1600, 3200]);
  });

  test('reads older pages until it finds the event', () async {
    storeUnderTexts(120);

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
