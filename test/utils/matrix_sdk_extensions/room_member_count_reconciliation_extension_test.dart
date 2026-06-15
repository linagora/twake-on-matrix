import 'package:fluffychat/utils/matrix_sdk_extensions/room_member_count_reconciliation_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

/// Records the summaries persisted through [storeRoomUpdate].
class RecordingDatabase extends MockDatabase {
  final List<JoinedRoomUpdate> storedJoinedRoomUpdates = [];

  @override
  Future<void> storeRoomUpdate(
    String roomId,
    SyncRoomUpdate roomUpdate,
    Event? lastEvent,
    Client client,
  ) async {
    if (roomUpdate is JoinedRoomUpdate) {
      storedJoinedRoomUpdates.add(roomUpdate);
    }
  }

  @override
  Future<List<User>> getUsers(Room room) async => [];
}

void main() {
  late RecordingDatabase database;
  late Client client;

  setUp(() async {
    database = RecordingDatabase();
    client = await getClient(database: database);
  });

  tearDown(() async {
    await client.dispose(closeDatabase: false);
  });

  Room makeRoom(
    String id, {
    Membership membership = Membership.join,
    int? joined,
    int? invited,
    List<String>? heroes,
  }) {
    final room = Room(
      id: id,
      membership: membership,
      client: client,
      summary: RoomSummary.fromJson({
        if (joined != null) 'm.joined_member_count': joined,
        if (invited != null) 'm.invited_member_count': invited,
        if (heroes != null) 'm.heroes': heroes,
      }),
    );
    client.rooms.add(room);
    return room;
  }

  group('healSummaryMemberCounts', () {
    test('fixes a stale summary in memory and persists it', () async {
      final room = makeRoom(
        '!stale:example.com',
        joined: 1,
        invited: 0,
        heroes: ['@bob:example.com'],
      );

      await room.healSummaryMemberCounts([
        User('@alice:example.com', membership: 'join', room: room),
        User('@bob:example.com', membership: 'join', room: room),
        User('@carol:example.com', membership: 'invite', room: room),
      ]);

      expect(room.summary.mJoinedMemberCount, 2);
      expect(room.summary.mInvitedMemberCount, 1);
      // The merge must not drop the heroes used for DM display names.
      expect(room.summary.mHeroes, ['@bob:example.com']);

      expect(database.storedJoinedRoomUpdates, hasLength(1));
      final stored = database.storedJoinedRoomUpdates.single.summary;
      expect(stored?.mJoinedMemberCount, 2);
      expect(stored?.mInvitedMemberCount, 1);
    });

    test('does nothing when the summary already matches', () async {
      final room = makeRoom('!uptodate:example.com', joined: 2, invited: 1);

      await room.healSummaryMemberCounts([
        User('@alice:example.com', membership: 'join', room: room),
        User('@bob:example.com', membership: 'join', room: room),
        User('@carol:example.com', membership: 'invite', room: room),
      ]);

      expect(room.summary.mJoinedMemberCount, 2);
      expect(room.summary.mInvitedMemberCount, 1);
      expect(database.storedJoinedRoomUpdates, isEmpty);
    });

    test('ignores memberships other than join and invite', () async {
      final room = makeRoom('!banned:example.com', joined: 1, invited: 0);

      await room.healSummaryMemberCounts([
        User('@alice:example.com', membership: 'join', room: room),
        User('@bad:example.com', membership: 'ban', room: room),
        User('@gone:example.com', membership: 'leave', room: room),
        User('@maybe:example.com', membership: 'knock', room: room),
      ]);

      expect(room.summary.mJoinedMemberCount, 1);
      expect(room.summary.mInvitedMemberCount, 0);
      expect(database.storedJoinedRoomUpdates, isEmpty);
    });

    test('does not touch rooms the user has not joined', () async {
      final room = makeRoom(
        '!invitedroom:example.com',
        membership: Membership.invite,
        joined: 1,
        invited: 1,
      );

      await room.healSummaryMemberCounts([
        User('@alice:example.com', membership: 'join', room: room),
        User('@bob:example.com', membership: 'join', room: room),
      ]);

      // A JoinedRoomUpdate would have flipped the membership to join.
      expect(room.membership, Membership.invite);
      expect(room.summary.mJoinedMemberCount, 1);
      expect(database.storedJoinedRoomUpdates, isEmpty);
    });

    test(
      'does not heal from a ground truth without any joined member',
      () async {
        final room = makeRoom('!emptychunk:example.com', joined: 1, invited: 0);

        // Pathological /members response (200 with a missing `chunk`):
        // healing from it would zero out the counts.
        await room.healSummaryMemberCounts([]);
        await room.healSummaryMemberCounts([
          User('@carol:example.com', membership: 'invite', room: room),
        ]);

        expect(room.summary.mJoinedMemberCount, 1);
        expect(room.summary.mInvitedMemberCount, 0);
        expect(database.storedJoinedRoomUpdates, isEmpty);
      },
    );

    test('does not touch rooms unknown to the client', () async {
      final room = Room(
        id: '!archived:example.com',
        membership: Membership.join,
        client: client,
        summary: RoomSummary.fromJson({'m.joined_member_count': 1}),
      );

      await room.healSummaryMemberCounts([
        User('@alice:example.com', membership: 'join', room: room),
        User('@bob:example.com', membership: 'join', room: room),
      ]);

      expect(client.getRoomById('!archived:example.com'), isNull);
      expect(database.storedJoinedRoomUpdates, isEmpty);
    });
  });

  group('requestParticipantsWithSummaryReconciliation', () {
    test('heals the summary from the fetched member list', () async {
      // FakeMatrixApi serves a single joined member for this room's /members.
      final room = makeRoom('!726s6s6q:example.com', joined: 5, invited: 2);

      final participants = await room
          .requestParticipantsWithSummaryReconciliation();

      expect(participants.map((user) => user.id), ['@alice:example.com']);
      expect(room.summary.mJoinedMemberCount, 1);
      expect(room.summary.mInvitedMemberCount, 0);
      expect(database.storedJoinedRoomUpdates, hasLength(1));
    });

    test(
      'skips reconciliation when the filter is not a ground truth',
      () async {
        final room = makeRoom('!726s6s6q:example.com', joined: 5, invited: 2);

        await room.requestParticipantsWithSummaryReconciliation([
          Membership.join,
        ]);

        expect(room.summary.mJoinedMemberCount, 5);
        expect(room.summary.mInvitedMemberCount, 2);
        expect(database.storedJoinedRoomUpdates, isEmpty);
      },
    );
  });
}
