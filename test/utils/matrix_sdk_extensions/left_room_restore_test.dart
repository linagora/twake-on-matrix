import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:twake_chat/widgets/unread_rooms_badge.dart';

/// Left rooms are synced with `includeLeave`, so they are stored in the
/// database and come back as [Room]s after a restart. A room that was left
/// must come back as [Membership.leave] and must not reach the chat list or
/// the unread badge, whatever unread count it had when it was left.
void main() {
  const roomId = '!room:example.org';
  const unreadWhenLeft = 3;

  late MatrixSdkDatabase database;
  late Client client;

  Future<MatrixSdkDatabase> openDatabase() async {
    return MatrixSdkDatabase.init(
      'left_room_restore_test',
      database: await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      ),
      sqfliteFactory: databaseFactoryFfi,
    );
  }

  Future<void> storeJoinedWithUnread(int notificationCount) {
    return database.storeRoomUpdate(
      roomId,
      JoinedRoomUpdate(
        unreadNotifications: UnreadNotificationCounts(
          notificationCount: notificationCount,
          highlightCount: 0,
        ),
      ),
      null,
      client,
    );
  }

  Future<void> storeLeft() {
    return database.storeRoomUpdate(roomId, LeftRoomUpdate(), null, client);
  }

  /// Simulates a cold start: a new in-memory client loaded from the database.
  Future<Room> restoreRoom() async {
    final restored = await database.getRoomList(client);
    client.rooms
      ..clear()
      ..addAll(restored);
    return restored.single;
  }

  int chatsTabBadge() => UnreadRoomsBadge.countNotifications(
    client,
    (room) => !room.isSpace && !room.isStoryRoom,
  );

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await openDatabase();
    client = Client(
      'left_room_restore_test',
      database: database,
      syncFilter: Filter(room: RoomFilter(includeLeave: true)),
    );
  });

  tearDown(() => database.close());

  test(
    'a joined room with unread messages is restored as joined and counted',
    () async {
      await storeJoinedWithUnread(unreadWhenLeft);

      final room = await restoreRoom();

      expect(room.membership, Membership.join);
      expect(chatsTabBadge(), unreadWhenLeft);
    },
  );

  test(
    'a room left with unread messages is restored as left after a restart',
    () async {
      await storeJoinedWithUnread(unreadWhenLeft);
      await storeLeft();

      final room = await restoreRoom();

      expect(room.membership, Membership.leave);
    },
  );

  test('a restored left room stays out of the chat list filters', () async {
    await storeJoinedWithUnread(unreadWhenLeft);
    await storeLeft();

    final room = await restoreRoom();

    for (final filter in ActiveFilter.values) {
      expect(
        filter.getRoomFilterByActiveFilter()(room),
        isFalse,
        reason: '$filter',
      );
    }
    expect(client.joinedOrInvitedRooms, isEmpty);
  });

  test('a restored left room is not counted in the unread badge', () async {
    await storeJoinedWithUnread(unreadWhenLeft);
    await storeLeft();

    await restoreRoom();

    expect(chatsTabBadge(), 0);
  });

  test('a left room that is joined again is restored as joined', () async {
    await storeJoinedWithUnread(unreadWhenLeft);
    await storeLeft();
    await storeJoinedWithUnread(0);

    final room = await restoreRoom();

    expect(room.membership, Membership.join);
    expect(chatsTabBadge(), 0);
  });
}
