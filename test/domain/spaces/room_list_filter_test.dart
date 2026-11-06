import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';

const _entries = [
  RoomListEntry(id: '!space', kind: RoomKind.space),
  RoomListEntry(id: '!unreadSpace', kind: RoomKind.space, unreadCount: 2),
  RoomListEntry(id: '!channel', parentSpaceIds: ['!space']),
  RoomListEntry(id: '!orphan', parentSpaceIds: ['!notJoined']),
  RoomListEntry(id: '!dm', kind: RoomKind.direct, isFavourite: true),
  RoomListEntry(id: '!bot', kind: RoomKind.bot),
  RoomListEntry(id: '!feed', kind: RoomKind.broadcast, mentionCount: 1),
  RoomListEntry(id: '!marked', isMarkedUnread: true),
];

List<String> _shown(
  RoomListFilter view, {
  String? activeRoomId,
  List<Folder> folders = const [],
}) => visibleEntries(
  _entries,
  view: view,
  activeRoomId: activeRoomId,
  folders: folders,
).map((entry) => entry.id).toList();

void main() {
  group('visibleEntries', () {
    test('whenAll_showsEverything', () {
      expect(_shown(const RoomListFilter.all()), hasLength(_entries.length));
    });

    test('whenSpaces_showsTheSpacesAndTheRoomsOfAJoinedSpace', () {
      expect(_shown(const RoomListFilter.builtin(BuiltinFolder.spaces)), [
        '!space',
        '!unreadSpace',
        '!channel',
      ]);
    });

    test('whenBroadcasts_showsOnlyBroadcasts', () {
      expect(_shown(const RoomListFilter.builtin(BuiltinFolder.broadcasts)), [
        '!feed',
      ]);
    });

    test('whenDirects_showsPeopleAndBots', () {
      expect(_shown(const RoomListFilter.builtin(BuiltinFolder.directs)), [
        '!dm',
        '!bot',
      ]);
    });

    test('whenFavourites_showsThePinned', () {
      expect(_shown(const RoomListFilter.builtin(BuiltinFolder.favourites)), [
        '!dm',
      ]);
    });

    group('whenUnread', () {
      const unread = RoomListFilter.builtin(BuiltinFolder.unread);

      test('showsWhatIsUnreadOrMarkedSo', () {
        expect(_shown(unread), ['!unreadSpace', '!feed', '!marked']);
      });

      test('keepsTheOpenRoomWhileItIsRead', () {
        expect(_shown(unread, activeRoomId: '!dm'), contains('!dm'));
      });

      test('doesNotKeepAnOpenSpace', () {
        expect(
          _shown(unread, activeRoomId: '!space'),
          isNot(contains('!space')),
        );
      });
    });

    test('whenFolder_showsWhatItsRuleHolds', () {
      expect(
        _shown(
          const RoomListFilter.folder('Work'),
          folders: const [
            Folder.user('Work', include: [FolderChatType.group]),
          ],
        ),
        ['!channel', '!orphan', '!marked'],
      );
    });

    test('whenFolderIsUnknown_showsNothing', () {
      expect(_shown(const RoomListFilter.folder('Gone')), isEmpty);
    });
  });

  group('RoomListFilter', () {
    test('of_always_namesTheFolder', () {
      expect(
        RoomListFilter.of(const Folder.builtin(BuiltinFolder.spaces)),
        const RoomListFilter.builtin(BuiltinFolder.spaces),
      );
      expect(
        RoomListFilter.of(const Folder.user('Work')),
        const RoomListFilter.folder('Work'),
      );
    });

    test('showsJoinableSubspaces_onlyInAllAndSpaces', () {
      expect(const RoomListFilter.all().showsJoinableSubspaces, isTrue);
      expect(
        const RoomListFilter.builtin(
          BuiltinFolder.spaces,
        ).showsJoinableSubspaces,
        isTrue,
      );
      expect(
        const RoomListFilter.builtin(
          BuiltinFolder.unread,
        ).showsJoinableSubspaces,
        isFalse,
      );
      expect(const RoomListFilter.folder('W').showsJoinableSubspaces, isFalse);
    });
  });
}
