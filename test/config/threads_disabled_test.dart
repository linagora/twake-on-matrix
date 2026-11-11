import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_summary.dart';

import '../domain/usecase/room/send_text_message_interactor_test.mocks.dart';
import '../utils/thread_unread/thread_fakes.dart';

/// Scope (orchestrator, 11/11): the flag gates the thread UI only; counters, badges, receipts and the sync filter are not gated.
///
/// `AppConfig.threadsEnabled` off (until the counters/receipts PR sets it
/// on): a thread reply is an ordinary message of the room, a root has no
/// card, the message menu has no « Start a thread ». With the flag on, the
/// thread specs hold.
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
