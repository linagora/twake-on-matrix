import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';

RoomListEntry _space(
  String id, {
  bool isFavourite = false,
  int unread = 0,
  List<String> parents = const [],
}) => _room(
  id,
  isFavourite: isFavourite,
  unread: unread,
  parents: parents,
).copyWith(kind: RoomKind.space);

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
}) => _room(
  id,
  unread: unread,
  parents: parents,
).copyWith(mentionCount: mentions);

const _dm = RoomListEntry(id: '!dm', kind: RoomKind.direct);

String _shape(List<RoomListRow> rows) => rows
    .map(
      (row) => switch (row) {
        RoomListRoomRow(:final entry) ||
        RoomListSpaceRow(:final entry) => '${row.depth}:${entry.id}',
        RoomListJoinableRow(:final subspace) =>
          '${row.depth}:join ${subspace.roomId}',
        RoomListSectionTitleRow(:final kind) => '# ${kind.name}',
      },
    )
    .join(' ');

void main() {
  _buildRoomListRowsTests();
  _buildRoomListRowsPinnedTests();
  _buildRoomListRowsJoinableTests();
  _buildSectionedRoomListRowsTests();
  _buildSectionedRoomListRowsSpacesTests();
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

// The order « sections »: the pinned rooms first under no title, then
// unread, spaces, groups and direct chats, each under its title. A space keeps
// its rooms under it, read or not, pinned or not.
void _buildSectionedRoomListRowsTests() {
  group('buildSectionedRoomListRows', () {
    test('whenNothingIsListed_showsNoRowNorTitle', () {
      expect(buildSectionedRoomListRows([]), isEmpty);
    });

    test('showsUnreadSpacesGroupsThenDirects_eachUnderItsTitle', () {
      final rows = buildSectionedRoomListRows([
        _dm,
        _room('!team'),
        _space('!s'),
        const RoomListEntry(
          id: '!alice',
          kind: RoomKind.direct,
          unreadCount: 1,
        ),
        _room('!ops'),
      ]);

      expect(
        _shape(rows),
        '# unread 0:!alice # spaces 0:!s # groups 0:!team 0:!ops # directs 0:!dm',
      );
    });

    test('leavesOutTheTitleOfAnEmptySection', () {
      final rows = buildSectionedRoomListRows([_room('!team'), _dm]);

      expect(_shape(rows), '# groups 0:!team # directs 0:!dm');
    });

    test('whenARoomIsPinned_showsItOnTopUnderNoTitle_andNotInItsSection', () {
      final rows = buildSectionedRoomListRows([
        _room('!g'),
        _room('!p', isFavourite: true),
        _dm,
      ]);

      expect(_shape(rows), '0:!p # groups 0:!g # directs 0:!dm');
    });

    test('givesEachRowItsOwnKey', () {
      final rows = buildSectionedRoomListRows([
        _space('!s'),
        _room('!c', parents: ['!s'], isFavourite: true),
        _room('!u', unread: 1),
        _room('!g'),
        _dm,
      ]);

      final keys = rows.map((row) => row.key).toList();
      expect(keys.toSet().length, keys.length, reason: '$keys');
    });
  });
}

void _buildSectionedRoomListRowsSpacesTests() {
  group('buildSectionedRoomListRows', () {
    test('whenARoomInASpaceIsPinned_showsItOnTopAndInItsSpace', () {
      final rows = buildSectionedRoomListRows([
        _space('!s'),
        _room('!c', parents: ['!s'], isFavourite: true),
        _room('!g'),
      ]);

      expect(_shape(rows), '0:!c # spaces 0:!s 1:!c # groups 0:!g');
    });

    test(
      'whenEverySpaceIsPinned_showsThemOnTopWithTheirRooms_andNoSpacesTitle',
      () {
        final rows = buildSectionedRoomListRows([
          _space('!s1', isFavourite: true),
          _room('!c', parents: ['!s1']),
          _space('!s2', isFavourite: true),
          _room('!g'),
        ]);

        expect(_shape(rows), '0:!s1 1:!c 0:!s2 # groups 0:!g');
      },
    );

    test('whenARoomInASpaceIsUnread_keepsItUnderItsSpace_notInUnread', () {
      final rows = buildSectionedRoomListRows([
        _room('!c', parents: ['!s'], unread: 3),
        _space('!s'),
        _room('!u', unread: 1),
      ]);

      expect(_shape(rows), '# unread 0:!u # spaces 0:!s 1:!c');
    });

    test('whenTheOnlyUnreadRoomIsInASpace_showsNoUnreadTitle', () {
      final rows = buildSectionedRoomListRows([
        _room('!c', parents: ['!s'], unread: 3),
        _space('!s'),
        _room('!g'),
      ]);

      expect(_shape(rows), '# spaces 0:!s 1:!c # groups 0:!g');
    });

    test('whenASpaceIsUnread_keepsItUnderSpaces', () {
      final rows = buildSectionedRoomListRows([
        _space('!s', unread: 2),
        _room('!g'),
      ]);

      expect(_shape(rows), '# spaces 0:!s # groups 0:!g');
    });
  });
}
