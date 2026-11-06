import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';

void main() {
  group('FolderColor', () {
    test('tryParse_whenInvalid_returnsNull', () {
      expect(FolderColor.tryParse('red'), isNull);
      expect(FolderColor.tryParse(3), isNull);
    });

    test('argb_whenValid_isOpaque', () {
      expect(FolderColor.tryParse('#ff0000')!.argb, 0xFFFF0000);
    });
  });

  group('withHiddenBuiltins', () {
    test('whenBuiltinsAreLeftOut_savesThemHiddenAndLast', () {
      final saved = withHiddenBuiltins(const [
        Folder.builtin(BuiltinFolder.spaces),
        Folder.user('Work'),
        Folder.builtin(BuiltinFolder.unread, hidden: true, name: 'Old'),
      ]);

      expect(saved, const [
        Folder.builtin(BuiltinFolder.spaces),
        Folder.user('Work'),
        Folder.builtin(BuiltinFolder.unread, hidden: true),
        Folder.builtin(BuiltinFolder.broadcasts, hidden: true),
        Folder.builtin(BuiltinFolder.directs, hidden: true),
        Folder.builtin(BuiltinFolder.favourites, hidden: true),
      ]);
    });
  });

  group('listFolders', () {
    test('whenNothingIsSaved_showsTheBuiltinsInOrder', () {
      expect(
        listFolders(const [], const []),
        BuiltinFolder.values.map(Folder.builtin).toList(),
      );
    });

    test('whenSaved_keepsTheOrderWithoutTheHidden', () {
      const spaces = Folder.builtin(BuiltinFolder.spaces);
      const work = Folder.user('Work');
      const unread = Folder.builtin(BuiltinFolder.unread);

      expect(
        listFolders(const [
          spaces,
          work,
          unread,
          Folder.builtin(BuiltinFolder.directs, hidden: true),
          Folder.builtin(BuiltinFolder.broadcasts, hidden: true),
          Folder.builtin(BuiltinFolder.favourites, hidden: true),
        ], const []),
        [spaces, work, unread],
      );
    });

    test('whenOnlyTagsKnowAFolder_addsItByName', () {
      final folders = listFolders(
        const [Folder.user('Work')],
        const ['Zed', 'Work', 'Abc'],
      );

      expect(folders.whereType<UserFolder>().map((f) => f.name), [
        'Work',
        'Abc',
        'Zed',
      ]);
    });
  });

  group('folderChatTypeOf', () {
    test('always_followsTheKind', () {
      FolderChatType? typeOf(RoomKind kind) =>
          folderChatTypeOf(RoomListEntry(id: '!a', kind: kind));

      expect(typeOf(RoomKind.space), isNull);
      expect(typeOf(RoomKind.direct), FolderChatType.direct);
      expect(typeOf(RoomKind.bot), FolderChatType.bot);
      expect(typeOf(RoomKind.group), FolderChatType.group);
      expect(typeOf(RoomKind.broadcast), FolderChatType.broadcast);
    });
  });

  group('isInFolder', () {
    const work = UserFolder('Work', include: [FolderChatType.direct]);
    const direct = RoomListEntry(id: '!a', kind: RoomKind.direct);

    test('whenChatWasPicked_holdsIt', () {
      expect(
        isInFolder(const RoomListEntry(id: '!a', folders: ['Work']), work),
        isTrue,
      );
    });

    test('whenChatIsOfAKindItTakes_holdsIt', () {
      expect(isInFolder(direct, work), isTrue);
      expect(isInFolder(const RoomListEntry(id: '!a'), work), isFalse);
    });

    test('whenChatIsExcluded_keepsItOutWhateverElseSays', () {
      expect(
        isInFolder(
          direct.copyWith(folders: ['Work']),
          work.copyWith(exclude: ['!a']),
        ),
        isFalse,
      );
    });

    test('whenRoomIsASpace_keepsItOut', () {
      expect(
        isInFolder(
          const RoomListEntry(
            id: '!s',
            kind: RoomKind.space,
            folders: ['Work'],
          ),
          work,
        ),
        isFalse,
      );
    });
  });

  group('planFolderEdit', () {
    const chats = [
      RoomListEntry(id: '!dm', kind: RoomKind.direct),
      RoomListEntry(id: '!old', folders: ['Work']),
      RoomListEntry(id: '!group'),
    ];
    const directs = UserFolder('Work', include: [FolderChatType.direct]);

    test('whenChatOutsideTheKindsIsTicked_tagsIt', () {
      final plan = planFolderEdit(
        folder: directs,
        previous: directs,
        picked: {'!dm', '!old', '!group'},
        chats: chats,
      );

      expect(plan.changes, const [
        FolderTagChange(roomId: '!group', folderName: 'Work', isIn: true),
      ]);
      expect(plan.folder.exclude, isEmpty);
    });

    test('whenChatsAreUnticked_excludesOrUntagsThem', () {
      final plan = planFolderEdit(
        folder: directs,
        previous: directs.copyWith(exclude: ['!gone', '!dm']),
        picked: const {},
        chats: chats,
      );

      expect(plan.folder.exclude, ['!gone', '!dm']);
      expect(plan.changes, const [
        FolderTagChange(roomId: '!old', folderName: 'Work', isIn: false),
      ]);
    });

    test('whenRenamed_movesTheTags', () {
      final plan = planFolderEdit(
        folder: const UserFolder('Job'),
        previous: const UserFolder('Work'),
        picked: {'!old'},
        chats: chats,
      );

      expect(plan.changes, const [
        FolderTagChange(roomId: '!old', folderName: 'Job', isIn: true),
        FolderTagChange(roomId: '!old', folderName: 'Work', isIn: false),
      ]);
    });

    test('whenNew_tagsWhatIsTicked', () {
      final plan = planFolderEdit(
        folder: const UserFolder('New'),
        previous: null,
        picked: {'!group'},
        chats: chats,
      );

      expect(plan.changes, const [
        FolderTagChange(roomId: '!group', folderName: 'New', isIn: true),
      ]);
    });
  });
}
