// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/providers/room_list/room_list_entries_provider.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart'
    show MockRoom;
import '../../utils/thread_unread/thread_fakes.dart';
import '../fake_active_account.dart';

/// Review of #3608 (nqhhdev): the room list reads the thread counters, so
/// it must show them when they change. The follow state of a thread is known
/// only after a lookup that ends between two syncs: the list follows the
/// thread counters (`client.threadUnread`), not only the sync.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool flagBefore;

  setUp(() {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    SharedPreferences.setMockInitialValues({});
    _lookup = Completer<MatrixEvent>();
    _client = _clientWithOneRoom();
  });

  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  test('the room list shows a followed thread once its follow lookup answers, '
      'with no new sync', () async {
    final shown = await _listenToRoomList();

    // A sync brings two replies in a thread whose follow state is unknown.
    _client.threadUnread.apply(
      const SyncThreadUpdate(
        counts: {
          _roomId: {_rootId: (notificationCount: 2, highlightCount: 0)},
        },
        leftRoomIds: [],
      ),
    );
    await pumpEventQueue();
    // The server says the user replied in it; no sync comes after.
    _lookup.complete(_rootTheUserRepliedTo());
    // Past the rate limit of the room changes.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(
      _client.threadUnread.isFollowed(const ThreadRef(_roomId, _rootId)),
      isTrue,
      reason: 'setup: the lookup made the thread followed',
    );

    expect(shown.last.single.unreadCount, 2);
  });
}

const _roomId = '!room:example.com';
const _rootId = r'$root';
const _me = '@me:example.com';

late RecordingThreadClient _client;

/// What `GET /rooms/{roomId}/event/{rootId}` will answer.
late Completer<MatrixEvent> _lookup;

/// An account that keeps the thread counters, with one joined room.
RecordingThreadClient _clientWithOneRoom() {
  final client = RecordingThreadClient();
  when(client.clientName).thenReturn('account-a');
  when(client.userID).thenReturn(_me);
  when(client.database).thenReturn(StoredEvents(const []));
  when(client.roomsLoading).thenAnswer((_) async {});
  when(client.onSync).thenReturn(CachedStreamController<SyncUpdate>());
  when(client.directChats).thenReturn({});
  when(
    client.getOneRoomEvent(_roomId, _rootId),
  ).thenAnswer((_) => _lookup.future);
  final room = MockRoom();
  when(room.id).thenReturn(_roomId);
  when(room.client).thenReturn(client);
  when(room.membership).thenReturn(Membership.join);
  when(room.tags).thenReturn({});
  when(room.spaceParents).thenReturn([]);
  when(room.spaceChildren).thenReturn([]);
  when(room.notificationCount).thenReturn(0);
  when(room.highlightCount).thenReturn(0);
  when(client.rooms).thenReturn([room]);
  return client;
}

/// Every list of entries the room list shows, from now on.
Future<List<List<RoomListEntry>>> _listenToRoomList() async {
  final container = ProviderContainer.test(
    overrides: activeAccountOverrides(_client),
  );
  final shown = <List<RoomListEntry>>[];
  container.listen(
    roomListEntriesProvider,
    (_, entries) => shown.add(entries),
    fireImmediately: true,
  );
  await pumpEventQueue();
  return shown;
}

/// The root as the server returns it: the user replied in its thread.
MatrixEvent _rootTheUserRepliedTo() => MatrixEvent(
  type: EventTypes.Message,
  content: {'msgtype': 'm.text', 'body': 'root'},
  eventId: _rootId,
  senderId: '@alice:example.com',
  originServerTs: DateTime.utc(2026, 11, 12),
  roomId: _roomId,
  unsigned: {
    'm.relations': {
      'm.thread': {'count': 2, 'current_user_participated': true},
    },
  },
);
