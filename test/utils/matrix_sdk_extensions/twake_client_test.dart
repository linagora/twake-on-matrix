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

  test('enables limited timeline history backfill before initialization', () {
    final client = TwakeClient('testclient', database: MockDatabase());

    expect(client.requestHistoryOnLimitedTimeline, isTrue);
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
