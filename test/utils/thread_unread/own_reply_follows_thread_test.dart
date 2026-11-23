import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart';

/// Review 4515561985 (triage nit): an old reply of the user, known only from
/// a page of the thread screen (`/relations`, never on the live timeline),
/// did not make the thread followed. The next reply of someone else could
/// then lose its local notification while the follow lookup ran. Every
/// thread reply the store is given, live or from a page, makes the thread
/// followed when the user sent it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient();
    when(client.clientName).thenReturn('account-a');
    when(client.userID).thenReturn(_me);
    _room = Room(id: _roomId, client: client);
    _store = ThreadUnreadStore(client: client);
  });

  test('a reply of the user makes the thread followed', () {
    _store.rememberThreadReply(_reply(sender: _me));

    expect(_store.isFollowed(_thread), isTrue);
  });

  test('a reply of someone else does not', () {
    _store.rememberThreadReply(_reply(sender: '@bob:example.com'));

    expect(_store.isFollowed(_thread), isFalse);
  });

  test('a reply of the user still being sent does not', () {
    _store.rememberThreadReply(
      _reply(sender: _me, status: EventStatus.sending),
    );

    expect(_store.isFollowed(_thread), isFalse);
  });

  test('a reply of the user tells the listeners', () {
    var told = 0;
    _store.addListener(() => told++);

    _store.rememberThreadReply(_reply(sender: _me));

    expect(told, isPositive);
  });
}

const _roomId = '!room:example.com';
const _rootId = r'$root';
const _me = '@me:example.com';
const _thread = ThreadRef(_roomId, _rootId);

late Room _room;
late ThreadUnreadStore _store;

Event _reply({
  required String sender,
  EventStatus status = EventStatus.synced,
}) => Event(
  type: EventTypes.Message,
  content: {
    'msgtype': 'm.text',
    'body': 'an old reply',
    'm.relates_to': {
      'rel_type': RelationshipTypes.thread,
      'event_id': _rootId,
      'is_falling_back': true,
    },
  },
  eventId: r'$old_reply',
  senderId: sender,
  originServerTs: DateTime.utc(2026, 11, 1),
  status: status,
  room: _room,
);
