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

  const roomId = '!room:example.com';
  const rootId = r'$root';
  const me = '@me:example.com';

  late bool flagBefore;
  late RecordingThreadClient client;
  late Completer<MatrixEvent> lookup;

  setUp(() {
    flagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    SharedPreferences.setMockInitialValues({});
    lookup = Completer<MatrixEvent>();
    client = RecordingThreadClient();
    when(client.clientName).thenReturn('account-a');
    when(client.userID).thenReturn(me);
    when(client.database).thenReturn(StoredEvents(const []));
    when(client.roomsLoading).thenAnswer((_) async {});
    when(client.onSync).thenReturn(CachedStreamController<SyncUpdate>());
    when(client.directChats).thenReturn({});
    when(
      client.getOneRoomEvent(roomId, rootId),
    ).thenAnswer((_) => lookup.future);
    final room = MockRoom();
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    when(room.membership).thenReturn(Membership.join);
    when(room.tags).thenReturn({});
    when(room.spaceParents).thenReturn([]);
    when(room.spaceChildren).thenReturn([]);
    when(room.notificationCount).thenReturn(0);
    when(room.highlightCount).thenReturn(0);
    when(client.rooms).thenReturn([room]);
  });

  tearDown(() => AppConfig.threadsEnabled = flagBefore);

  test('the room list shows a followed thread once its follow lookup answers, '
      'with no new sync', () async {
    final container = ProviderContainer.test(
      overrides: activeAccountOverrides(client),
    );
    final shown = <List<RoomListEntry>>[];
    container.listen(
      roomListEntriesProvider,
      (_, entries) => shown.add(entries),
      fireImmediately: true,
    );
    await pumpEventQueue();

    // A sync brings two replies in a thread whose follow state is unknown.
    client.threadUnread.apply(
      const SyncThreadUpdate(
        counts: {
          roomId: {rootId: (notificationCount: 2, highlightCount: 0)},
        },
        leftRoomIds: [],
      ),
    );
    await pumpEventQueue();
    // The server says the user replied in it; no sync comes after.
    lookup.complete(
      MatrixEvent(
        type: EventTypes.Message,
        content: {'msgtype': 'm.text', 'body': 'root'},
        eventId: rootId,
        senderId: '@alice:example.com',
        originServerTs: DateTime.utc(2026, 11, 12),
        roomId: roomId,
        unsigned: {
          'm.relations': {
            'm.thread': {'count': 2, 'current_user_participated': true},
          },
        },
      ),
    );
    // Past the rate limit of the room changes.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(
      client.threadUnread.isFollowed(const ThreadRef(roomId, rootId)),
      isTrue,
      reason: 'setup: the lookup made the thread followed',
    );

    expect(shown.last.single.unreadCount, 2);
  });
}
