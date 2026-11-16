import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/twake_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_client.dart';

/// A logged-in account: its own events are the ones of [userID].
class _OwnClient extends TwakeClient {
  _OwnClient() : super('testclient', database: MockDatabase());

  @override
  String? get userID => '@me:example.org';
}

void main() {
  // This level is gated by the flag (off by default until #3609).
  late bool threadsFlagBefore;
  setUp(() {
    threadsFlagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
  });
  tearDown(() => AppConfig.threadsEnabled = threadsFlagBefore);

  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const roomId = '!room:example.org';
  const thread = ThreadRef(roomId, r'$root');

  /// A client whose server answers /sync with [body].
  TwakeClient serverAnswering(Map<String, Object?> body) {
    final client = TwakeClient(
      'testclient',
      database: MockDatabase(),
      httpClient: http_testing.MockClient(
        (_) async => http.Response(jsonEncode(body), 200),
      ),
    );
    client.baseUri = Uri.parse('https://example.org');
    client.bearerToken = 'token';
    return client;
  }

  /// One sync, handled: the SDK emits onSync once it applied the update.
  Future<void> syncOnce(TwakeClient client) async {
    client.onSync.add(await client.sync());
    await pumpEventQueue(times: 50);
  }

  const threeUnreadRepliesSync = {
    'next_batch': 's1',
    'rooms': {
      'join': {
        roomId: {
          'unread_thread_notifications': {
            r'$root': {'notification_count': 3, 'highlight_count': 1},
          },
        },
      },
    },
  };

  test('with threads on, the thread counters of a sync reach the '
      'thread store', () async {
    final client = serverAnswering(threeUnreadRepliesSync);

    await syncOnce(client);

    expect(client.threadUnread.unreadCount(thread), 3);
  });

  test('enables limited timeline history backfill before initialization', () {
    final client = TwakeClient('testclient', database: MockDatabase());

    expect(client.requestHistoryOnLimitedTimeline, isTrue);
  });

  /// Review of #3621 (jbrnzl): with the flag off, off means off.
  group('with threads off', () {
    setUp(() => AppConfig.threadsEnabled = false);

    /// Review of #3621 (nqhhdev): the onSync listener applied the sync to
    /// the store whatever the flag.
    test(
      'the thread counters of a sync never reach the thread store',
      () async {
        final client = serverAnswering(threeUnreadRepliesSync);
        var storeChanges = 0;
        client.threadUnread.addListener(() => storeChanges++);

        await syncOnce(client);

        expect(client.threadUnread.unreadCount(thread), 0);
        expect(storeChanges, 0);
      },
    );

    test('a room left in a sync does not rewrite the saved thread '
        'state', () async {
      const saved =
          '{"counts":{"$roomId":{"\$root":[3,1]}},'
          '"followed":["$roomId|\$root"],"replies":{}}';
      SharedPreferences.setMockInitialValues({
        'thread_unread_testclient': saved,
      });
      final client = serverAnswering({
        'next_batch': 's2',
        'rooms': {
          'leave': {roomId: <String, Object?>{}},
        },
      });
      await client.threadUnread.restore();

      await syncOnce(client);
      await Future<void>.delayed(const Duration(seconds: 2));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('thread_unread_testclient'), saved);
    });

    test('a synced thread reply is not remembered', () async {
      final client = TwakeClient('testclient', database: MockDatabase());
      final room = Room(id: '!room:example.org', client: client);

      client.onTimelineEvent.add(
        Event(
          type: EventTypes.Message,
          content: {
            'msgtype': 'm.text',
            'body': 'in the thread',
            'm.relates_to': {
              'rel_type': RelationshipTypes.thread,
              'event_id': r'$root',
              'is_falling_back': true,
            },
          },
          eventId: r'$reply',
          senderId: '@bob:example.org',
          originServerTs: DateTime.utc(2026, 11, 8),
          room: room,
        ),
      );
      await pumpEventQueue();

      expect(
        client.threadUnread.knownThreadReplyIds(room),
        isNot(contains(r'$reply')),
      );
    });

    test('a synced thread reply writes nothing to the preferences', () async {
      final client = TwakeClient('testclient', database: MockDatabase());
      final room = Room(id: '!room:example.org', client: client);

      client.onHistoryEvent.add(
        Event(
          type: EventTypes.Message,
          content: {
            'msgtype': 'm.text',
            'body': 'older, in the thread',
            'm.relates_to': {
              'rel_type': RelationshipTypes.thread,
              'event_id': r'$root',
              'is_falling_back': true,
            },
          },
          eventId: r'$old_reply',
          senderId: '@bob:example.org',
          originServerTs: DateTime.utc(2026, 11, 1),
          room: room,
        ),
      );
      await pumpEventQueue(times: 50);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => k.startsWith('thread_unread_')),
        isEmpty,
      );
    });
  });

  /// THR-M-01: once deleted, a reply loses its thread relation; its id must
  /// be known before that, from the live timeline of any sender.
  test('a thread reply of the live timeline is remembered as one', () async {
    final client = TwakeClient('testclient', database: MockDatabase());
    final room = Room(id: '!room:example.org', client: client);

    client.onTimelineEvent.add(
      Event(
        type: EventTypes.Message,
        content: {
          'msgtype': 'm.text',
          'body': 'in the thread',
          'm.relates_to': {
            'rel_type': RelationshipTypes.thread,
            'event_id': r'$root',
            'is_falling_back': true,
          },
        },
        eventId: r'$reply',
        senderId: '@bob:example.org',
        originServerTs: DateTime.utc(2026, 11, 8),
        room: room,
      ),
    );
    await pumpEventQueue();

    expect(client.threadUnread.knownThreadReplyIds(room), contains(r'$reply'));
  });

  /// THR-M-01 and THR-M-07: the local echo of an own reply carries the transaction id
  /// as event id, and the SDK emits it on onTimelineEvent like a synced
  /// event. Only the synced echo, with its real id, is a thread reply.
  group('own thread reply sent from this device', () {
    const roomId = '!room:example.org';
    const rootId = r'$root';
    const txid = 'txn-1';

    Event ownReply(
      Room room, {
      required String eventId,
      required EventStatus status,
    }) => Event(
      type: EventTypes.Message,
      content: {
        'msgtype': 'm.text',
        'body': 'my reply',
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': rootId,
          'is_falling_back': true,
        },
      },
      eventId: eventId,
      senderId: '@me:example.org',
      originServerTs: DateTime.now(),
      status: status,
      unsigned: {
        messageSendingStatusKey: status.intValue,
        'transaction_id': txid,
      },
      room: room,
    );

    test('its local echo, still sending, is neither remembered nor makes '
        'the thread followed', () async {
      final client = _OwnClient();
      final room = Room(id: roomId, client: client);

      client.onTimelineEvent.add(
        ownReply(room, eventId: txid, status: EventStatus.sending),
      );
      await pumpEventQueue();

      expect(
        client.threadUnread.knownThreadReplyIds(room),
        isNot(contains(txid)),
      );
      expect(
        client.threadUnread.isFollowed(const ThreadRef(roomId, rootId)),
        isFalse,
      );
    });

    test('its local echo, failed to send, is neither remembered nor makes '
        'the thread followed', () async {
      final client = _OwnClient();
      final room = Room(id: roomId, client: client);

      client.onTimelineEvent.add(
        ownReply(room, eventId: txid, status: EventStatus.error),
      );
      await pumpEventQueue();

      expect(
        client.threadUnread.knownThreadReplyIds(room),
        isNot(contains(txid)),
      );
      expect(
        client.threadUnread.isFollowed(const ThreadRef(roomId, rootId)),
        isFalse,
      );
    });

    test('its synced echo is remembered by its real id and makes the thread '
        'followed', () async {
      final client = _OwnClient();
      final room = Room(id: roomId, client: client);

      client.onTimelineEvent.add(
        ownReply(room, eventId: txid, status: EventStatus.sending),
      );
      client.onTimelineEvent.add(
        ownReply(room, eventId: r'$my_reply', status: EventStatus.synced),
      );
      await pumpEventQueue();

      expect(client.threadUnread.knownThreadReplyIds(room), {r'$my_reply'});
      expect(
        client.threadUnread.isFollowed(const ThreadRef(roomId, rootId)),
        isTrue,
      );
    });
  });

  /// THR-M-01: a gap in the sync is filled by requestHistory;
  /// those replies come on onHistoryEvent and lose their relation once
  /// deleted, as live ones do.
  test('a thread reply loaded with the history is remembered as one', () async {
    final client = TwakeClient('testclient', database: MockDatabase());
    final room = Room(id: '!room:example.org', client: client);

    client.onHistoryEvent.add(
      Event(
        type: EventTypes.Message,
        content: {
          'msgtype': 'm.text',
          'body': 'older, in the thread',
          'm.relates_to': {
            'rel_type': RelationshipTypes.thread,
            'event_id': r'$root',
            'is_falling_back': true,
          },
        },
        eventId: r'$old_reply',
        senderId: '@bob:example.org',
        originServerTs: DateTime.utc(2026, 11, 1),
        room: room,
      ),
    );
    await pumpEventQueue();

    expect(
      client.threadUnread.knownThreadReplyIds(room),
      contains(r'$old_reply'),
    );
  });

  test('keeps call events out of the room preview', () {
    final client = TwakeClient('testclient', database: MockDatabase());

    expect(
      client.roomPreviewLastEvents,
      containsAll([EventTypes.Message, EventTypes.Encrypted]),
    );
    expect(
      client.roomPreviewLastEvents,
      isNot(contains(EventTypes.CallInvite)),
    );
    expect(
      client.roomPreviewLastEvents,
      isNot(contains(EventTypes.GroupCallMember)),
    );
  });
}
