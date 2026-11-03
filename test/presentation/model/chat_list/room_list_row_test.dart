import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';

RoomListEntry _space(
  String id, {
  bool isFavourite = false,
  int unread = 0,
  List<String> parents = const [],
}) => RoomListEntry(
  id: id,
  kind: RoomKind.space,
  isFavourite: isFavourite,
  unreadCount: unread,
  parentSpaceIds: parents,
);

RoomListEntry _room(
  String id, {
  bool isFavourite = false,
  int unread = 0,
  List<String> parents = const [],
}) => RoomListEntry(
  id: id,
  isFavourite: isFavourite,
  unreadCount: unread,
  parentSpaceIds: parents,
);

RoomListEntry _mentioned(
  String id, {
  required int mentions,
  int unread = 0,
  List<String> parents = const [],
}) => RoomListEntry(
  id: id,
  unreadCount: unread,
  mentionCount: mentions,
  parentSpaceIds: parents,
);

const _dm = RoomListEntry(id: '!dm', kind: RoomKind.direct);

String _shape(List<RoomListRow> rows) => rows
    .map(
      (row) => switch (row) {
        RoomListRoomRow(:final entry) ||
        RoomListSpaceRow(:final entry) => '${row.depth}:${entry.id}',
        RoomListJoinableRow(:final subspace) =>
          '${row.depth}:join ${subspace.roomId}',
      },
    )
    .join(' ');

void main() {
  _buildRoomListRowsTests();
  _buildRoomListRowsPinnedTests();
  _buildRoomListRowsJoinableTests();
}

void _buildRoomListRowsTests() {
  group('buildRoomListRows', () {
    test('whenAChannelIsRecent_placesItsSpaceThere', () {
      final rows = buildRoomListRows([
        _room('!recent', parents: ['!quiet']),
        _dm,
        _space('!quiet'),
      ]);

      expect(_shape(rows), '0:!quiet 1:!recent 0:!dm');
    });

    test('whenFolded_hidesWhatItHoldsAndCountsIt', () {
      final rows = buildRoomListRows(
        [
          _space('!s', unread: 1),
          _space('!sub', parents: ['!s']),
          _mentioned('!c', parents: ['!sub'], unread: 2, mentions: 1),
          _room('!d', parents: ['!s'], unread: 4),
        ],
        foldedSpaceIds: const {'!s'},
      );

      final row = rows.single as RoomListSpaceRow;
      expect(row.entry.id, '!s');
      expect(row.fold, SpaceFold.folded);
      expect(row.unreadCount, 7);
      expect(row.mentionCount, 1);
    });

    test('whenOpen_countsItselfAlone', () {
      final rows = buildRoomListRows([
        _space('!s', unread: 1),
        _room('!c', parents: ['!s'], unread: 2),
      ]);

      final row = rows.first as RoomListSpaceRow;
      expect(row.fold, SpaceFold.open);
      expect(row.unreadCount, 1);
    });

    test('whenSpaceHoldsNothing_hasNothingToFold', () {
      final rows = buildRoomListRows([_space('!s')]);

      expect((rows.single as RoomListSpaceRow).fold, SpaceFold.none);
    });

    test('whenSubSpaceIsFolded_keepsItsParentOpen', () {
      final rows = buildRoomListRows(
        [
          _space('!s'),
          _space('!sub', parents: ['!s']),
          _room('!c', parents: ['!sub']),
        ],
        foldedSpaceIds: const {'!sub'},
      );

      expect(_shape(rows), '0:!s 1:!sub');
    });
  });
}

void _buildRoomListRowsPinnedTests() {
  group('buildRoomListRows', () {
    test('whenChannelIsPinned_showsOnTopAndInItsSpace', () {
      final rows = buildRoomListRows([
        _space('!s'),
        _room('!c', parents: ['!s'], isFavourite: true),
      ]);

      expect(_shape(rows), '0:!c 0:!s 1:!c');
      expect(rows.map((row) => row.key).toSet(), hasLength(3));
    });

    test('whenPinnedChannelHasNoSpace_showsOnce', () {
      final rows = buildRoomListRows([_room('!c', isFavourite: true)]);

      expect(_shape(rows), '0:!c');
    });

    test('whenSpaceIsPinned_showsOnceOnTopWithItsChannels', () {
      final rows = buildRoomListRows([
        _dm,
        _space('!s', isFavourite: true),
        _room('!c', parents: ['!s']),
      ]);

      expect(_shape(rows), '0:!s 1:!c 0:!dm');
    });

    test('whenSpaceIsFolded_doesNotCountItsPinnedChannelAgain', () {
      final rows = buildRoomListRows(
        [
          _space('!s'),
          _room('!c', parents: ['!s'], isFavourite: true, unread: 3),
          _room('!d', parents: ['!s'], unread: 1),
        ],
        foldedSpaceIds: const {'!s'},
      );

      expect(_shape(rows), '0:!c 0:!s');
      expect((rows.last as RoomListSpaceRow).unreadCount, 1);
    });
  });
}

void _buildRoomListRowsJoinableTests() {
  group('buildRoomListRows', () {
    group('whenASubSpaceIsJoinable', () {
      const subspace = SpaceChannel(roomId: '!sub', name: 'Sub');
      const joinable = {
        '!s': [subspace],
      };

      test('showsItUnderItsOpenSpace', () {
        final rows = buildRoomListRows([
          _space('!s'),
        ], joinableBySpace: joinable);

        expect(_shape(rows), '0:!s 1:join !sub');
        expect((rows.first as RoomListSpaceRow).fold, SpaceFold.open);
        expect((rows.last as RoomListJoinableRow).parentSpaceId, '!s');
      });

      test('whenTwoSpacesListIt_keepsTheirRowsApart', () {
        final rows = buildRoomListRows(
          [_space('!s'), _space('!t')],
          joinableBySpace: const {
            '!s': [subspace],
            '!t': [subspace],
          },
        );

        expect(rows.map((row) => row.key).toSet(), hasLength(rows.length));
      });

      test('hidesItOnceFoldedButCanOpen', () {
        final rows = buildRoomListRows(
          [_space('!s')],
          foldedSpaceIds: const {'!s'},
          joinableBySpace: joinable,
        );

        expect(_shape(rows), '0:!s');
        expect((rows.single as RoomListSpaceRow).fold, SpaceFold.folded);
      });

      test('doesNotOfferItAgainOnceJoined', () {
        final rows = buildRoomListRows([
          _space('!s'),
          _space('!sub', parents: ['!s']),
        ], joinableBySpace: joinable);

        expect(_shape(rows), '0:!s 1:!sub');
      });
    });
  });
}
