import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/threaded_read_receipt_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_summary.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../utils/thread_unread/thread_fakes.dart';

/// Scope (review of #3608, nqhhdev, 12/11; replaces the orchestrator scope
/// of 11/11 « UI only »): the flag gates every thread behaviour, counters,
/// badges, receipts and sync filter included. It is on from #3609.
///
/// `AppConfig.threadsEnabled` off: a thread reply is an ordinary message of
/// the room, a root has no card, the message menu has no « Start a thread »,
/// the room counters are the server room counters only. Receipts: see
/// test/utils/matrix_sdk_extensions/threaded_read_receipt_extension_test.dart;
/// sync filter: test/utils/client_manager_sync_filter_test.dart. With the
/// flag on, the thread specs hold.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool flagBefore;

  setUp(() {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = false;
    _room = MockRoom();
    when(_room.id).thenReturn(_roomId);
    when(_room.canSendDefaultMessages).thenReturn(true);
  });

  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  group('a thread reply in the room', _timelineTests);
  group('a thread root', _rootTests);
  group('the room counters', _roomCounterTests);
  group('the new messages of the room', _newMessagesTests);
}

const _roomId = '!room:example.com';
const _rootId = r'$root';
const _bob = '@bob:example.com';

late MockRoom _room;

Event _message({
  required String eventId,
  Map<String, Object?>? relatesTo,
  Map<String, Object?>? unsigned,
}) => Event(
  type: EventTypes.Message,
  content: {'msgtype': 'm.text', 'body': 'hello', 'm.relates_to': ?relatesTo},
  eventId: eventId,
  senderId: _bob,
  originServerTs: DateTime.utc(2026, 11, 11, 10),
  room: _room,
  unsigned: unsigned,
);

Event _threadReply() => _message(
  eventId: r'$reply',
  relatesTo: {
    'rel_type': RelationshipTypes.thread,
    'event_id': _rootId,
    'is_falling_back': true,
    'm.in_reply_to': {'event_id': _rootId},
  },
);

/// A root the server says has 2 replies.
Event _rootWithReplies() => _message(
  eventId: _rootId,
  unsigned: {
    'm.relations': {
      'm.thread': {
        'count': 2,
        'current_user_participated': false,
        'latest_event': {
          'event_id': r'$reply',
          'type': EventTypes.Message,
          'sender': _bob,
          'origin_server_ts': 1,
          'content': {'msgtype': 'm.text', 'body': 'in the thread'},
        },
      },
    },
  },
);

void _timelineTests() {
  test('shows in the room timeline', () {
    expect(EventVisibilityResolver.isVisibleInTimeline(_threadReply()), isTrue);
  });

  test('a reply seen in a thread and deleted since shows, deleted, in the '
      'room timeline', () {
    final deleted = deletedEvent(
      eventId: r'$reply',
      sender: _bob,
      room: _room,
      sentAt: DateTime.utc(2026, 11, 11, 10),
    );

    expect(
      EventVisibilityResolver.isVisibleInTimeline(
        deleted,
        knownThreadReplyIds: {r'$reply'},
      ),
      isTrue,
    );
  });

  test('is the last message of the room in the room list', () async {
    expect(
      EventVisibilityResolver.isEligibleForChatListPreviewSync(_threadReply()),
      isTrue,
    );
    expect(
      await EventVisibilityResolver.isEligibleForChatListPreview(
        _room,
        _threadReply(),
      ),
      isTrue,
    );
  });
}

void _rootTests() {
  test('has no thread card', () {
    expect(ThreadSummary.fromRoot(_rootWithReplies()), isNull);
  });

  test('a message has no « Start a thread » in its menu', () {
    expect(
      ThreadRules.canStartThread(
        _message(eventId: r'$message'),
        hasThread: false,
      ),
      isFalse,
    );
  });
}

const _me = '@me:example.com';

DateTime _at(int minute) => DateTime.utc(2026, 11, 11, 10, minute);

RecordingThreadClient _threadClient() {
  SharedPreferences.setMockInitialValues({});
  final client = RecordingThreadClient();
  when(client.clientName).thenReturn('account-a');
  when(client.userID).thenReturn(_me);
  when(client.database).thenReturn(StoredEvents(const []));
  when(
    client.roomPreviewLastEvents,
  ).thenReturn({EventTypes.Message, EventTypes.Encrypted});
  return client;
}

/// The thread counters the store may hold (a sync of a build with the flag
/// on, or a saved snapshot): a followed thread with 2 replies, 1 mention.
void _storeHoldsAFollowedThread(RecordingThreadClient client) {
  client.threadUnread.markFollowed(const ThreadRef(_roomId, _rootId));
  client.threadUnread.apply(
    const SyncThreadUpdate(
      counts: {
        _roomId: {_rootId: (notificationCount: 2, highlightCount: 1)},
      },
      leftRoomIds: [],
    ),
  );
}

void _roomCounterTests() {
  late RecordingThreadClient client;

  setUp(() {
    client = _threadClient();
    _storeHoldsAFollowedThread(client);
  });

  test('the room badge is the server notification count', () {
    final room = Room(id: _roomId, client: client, notificationCount: 1);

    expect(room.unreadBadgeCount, 1);
  });

  test('the room mentions are the server highlight count', () {
    final room = Room(id: _roomId, client: client);

    expect(room.highlightCountWithThreads, 0);
  });

  test('a room with nothing unread on the server is not unread', () {
    final room = Room(id: _roomId, client: client);

    expect(room.isUnreadWithThreads, isFalse);
    expect(room.isUnreadOrInvitedWithThreads, isFalse);
  });
}

/// Before threads a thread reply was a message of the room: newer than the
/// read receipt, the room has new messages, followed thread or not.
void _newMessagesTests() {
  test('a thread reply newer than the receipt is a new message', () {
    final client = _threadClient();
    final read = LatestReceiptStateData(
      r'$read',
      _at(1).millisecondsSinceEpoch,
    );
    late Room room;
    room = Room(
      id: _roomId,
      client: client,
      receiptState: LatestReceiptState(
        global: LatestReceiptStateForTimeline(
          ownPrivate: null,
          ownPublic: read,
          latestOwnReceipt: read,
          otherUsers: {},
        ),
      ),
    );
    room.lastEvent = Event(
      type: EventTypes.Message,
      content: {
        'msgtype': 'm.text',
        'body': 'in the thread',
        'm.relates_to': {
          'rel_type': RelationshipTypes.thread,
          'event_id': _rootId,
          'is_falling_back': true,
          'm.in_reply_to': {'event_id': _rootId},
        },
      },
      eventId: r'$reply',
      senderId: _bob,
      originServerTs: _at(5),
      room: room,
    );

    expect(room.hasNewMessagesWithThreads, isTrue);
  });
}
