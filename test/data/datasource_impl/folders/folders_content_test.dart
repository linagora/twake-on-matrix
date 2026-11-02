import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource_impl/folders/folders_content.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

void main() {
  group('readFolders', () {
    test('whenMalformed_keepsOnlyWellFormedOncePerName', () {
      final folders = readFolders({
        'folders': [
          {
            'name': 'Work',
            'include': ['direct', 'nope'],
            'exclude': ['!x', 3],
          },
          {'name': 'Work'},
          {'name': '  '},
          {'emoji': '😀'},
          'garbage',
          {'name': 'Colours', 'emoji': '', 'color': 'red'},
        ],
      });

      expect(folders, const [
        Folder.user('Work', include: [FolderChatType.direct], exclude: ['!x']),
        Folder.user('Colours'),
      ]);
    });

    test('whenBuiltinIsRepeated_readsItOnce', () {
      final folders = readFolders({
        'folders': [
          {
            'builtin': 'spaces',
            'name': ' Mine ',
            'include': ['direct'],
          },
          {'builtin': 'spaces'},
          {'builtin': 'nope'},
        ],
      });

      expect(folders, const [
        Folder.builtin(BuiltinFolder.spaces, name: 'Mine'),
      ]);
    });

    test('whenFolderIsNamedLikeABuiltin_keepsBoth', () {
      final folders = readFolders({
        'folders': [
          {'name': 'spaces'},
          {'builtin': 'spaces', 'hidden': true},
        ],
      });

      expect(folders, const [
        Folder.user('spaces'),
        Folder.builtin(BuiltinFolder.spaces, hidden: true),
      ]);
    });

    test('whenNotAList_readsNothing', () {
      expect(readFolders(null), isEmpty);
      expect(readFolders({'folders': 'nope'}), isEmpty);
    });
  });

  group('writeFolders', () {
    test('always_writesBackWhatItReadsWithoutEmptyParts', () {
      final content = {
        'folders': [
          {
            'name': 'Work',
            'emoji': '💼',
            'color': '#ff0000',
            'include': ['direct', 'group'],
            'exclude': ['!x'],
          },
          {'name': 'Plain'},
          {'builtin': 'unread', 'name': 'New'},
          {'builtin': 'spaces', 'hidden': true},
        ],
      };

      expect(writeFolders(readFolders(content)), content);
    });
  });
}
