import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_rules.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../usecase/room/send_text_message_interactor_test.mocks.dart';

/// THR-M-09, maintainer decision (09/11) « push rules + filter »: a message
/// of the main timeline raises a local notification only as before threads
/// came: from the room's own counters, which the push rules fill
/// (`notificationCount`, `highlightCount`). The unread replies of the
/// threads (the room badge, the mentions of a thread) must not make a main
/// message notify that the push rules did not count.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const roomId = '!room:example.com';
  const rootId = r'$root';

  late _ThreadClient client;
  late MockRoom room;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = _ThreadClient();
    when(client.clientName).thenReturn('account-a');
    when(client.userID).thenReturn('@me:example.com');
    room = MockRoom();
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    when(room.pushRuleState).thenReturn(PushRuleState.notify);
    when(room.notificationCount).thenReturn(0);
    when(room.highlightCount).thenReturn(0);
  });

  /// A followed thread of the room with unread replies, [mentions] of them
  /// mentioning the user.
  void unreadThread({int replies = 2, int mentions = 0}) {
    client.threadUnread
      ..markFollowed(roomId, rootId)
      ..apply({
        roomId: {
          rootId: (notificationCount: replies, highlightCount: mentions),
        },
      });
  }

  test('a room set to mentions only, a mention unread in a thread: a plain '
      'main message does not notify', () {
    when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);
    unreadThread(replies: 1, mentions: 1);
    // The push rules did not count the plain message.
    when(room.notificationCount).thenReturn(0);
    when(room.highlightCount).thenReturn(0);

    expect(ThreadRules.shouldNotifyMainTimelineEvent(room), isFalse);
  });

  test('a main message the push rules did not count does not notify, while a '
      'followed thread has unread replies', () {
    // A notice of a bot (`.m.rule.suppress_notices`).
    unreadThread(replies: 2);

    expect(ThreadRules.shouldNotifyMainTimelineEvent(room), isFalse);
  });

  test('a main message the push rules counted notifies', () {
    when(room.notificationCount).thenReturn(1);

    expect(ThreadRules.shouldNotifyMainTimelineEvent(room), isTrue);
  });

  test('a room set to mentions only: a main message that mentions the user '
      'notifies', () {
    when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);
    when(room.notificationCount).thenReturn(1);
    when(room.highlightCount).thenReturn(1);

    expect(ThreadRules.shouldNotifyMainTimelineEvent(room), isTrue);
  });

  test('a room set to mentions only: a main message without mention does not '
      'notify, whatever a thread holds', () {
    when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);
    unreadThread(replies: 1, mentions: 1);
    when(room.notificationCount).thenReturn(1);
    when(room.highlightCount).thenReturn(0);

    expect(ThreadRules.shouldNotifyMainTimelineEvent(room), isFalse);
  });
}

/// A client that keeps the thread counters, like [TwakeClient].
class _ThreadClient extends MockClient implements ThreadUnreadStoreOwner {
  @override
  late final ThreadUnreadStore threadUnread = ThreadUnreadStore(client: this);
}
