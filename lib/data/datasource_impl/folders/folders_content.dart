import 'package:twake_chat/domain/spaces/folders.dart';

/// The account data every Twake client shares its folders in.
const String foldersAccountDataType = 'app.twake.chat.folders';

/// The folders of the account data, whatever a client wrote there.
List<Folder> readFolders(Map<String, Object?>? content) {
  final list = content?['folders'];
  if (list is! List) return const [];
  // A built-in is known by its kind, a folder by its name: « spaces » is
  // both a kind and a name a folder may have.
  final kinds = <BuiltinFolder>{};
  final names = <String>{};
  final folders = <Folder>[];
  for (final item in list.whereType<Map>()) {
    final name = item['name'];
    final emoji = item['emoji'];
    final safeEmoji = emoji is String && emoji.isNotEmpty ? emoji : null;
    final color = FolderColor.tryParse(item['color']);
    final kind = BuiltinFolder.values.asNameMap()[item['builtin']];
    if (kind != null) {
      if (!kinds.add(kind)) continue;
      folders.add(
        Folder.builtin(
          kind,
          name: name is String ? name.trim() : '',
          emoji: safeEmoji,
          color: color,
          hidden: item['hidden'] == true,
        ),
      );
    } else if (name is String && name.trim().isNotEmpty && names.add(name)) {
      final include = item['include'];
      final exclude = item['exclude'];
      folders.add(
        Folder.user(
          name,
          emoji: safeEmoji,
          color: color,
          include: include is List
              ? FolderChatType.values
                    .where((type) => include.contains(type.name))
                    .toList()
              : const [],
          exclude: exclude is List
              ? exclude.whereType<String>().toList()
              : const [],
        ),
      );
    }
  }
  return folders;
}

/// The content written back, without the empty parts.
Map<String, Object?> writeFolders(List<Folder> folders) => {
  'folders': folders.map(_writeFolder).toList(),
};

Map<String, Object?> _writeFolder(Folder folder) => switch (folder) {
  BuiltinFolderEntry(:final kind, hidden: true) => {
    'builtin': kind.name,
    'hidden': true,
  },
  BuiltinFolderEntry(:final kind, :final name, :final emoji, :final color) => {
    'builtin': kind.name,
    if (name.isNotEmpty) 'name': name,
    'emoji': ?emoji,
    'color': ?color?.hex,
  },
  UserFolder(
    :final name,
    :final emoji,
    :final color,
    :final include,
    :final exclude,
  ) =>
    {
      'name': name,
      'emoji': ?emoji,
      'color': ?color?.hex,
      if (include.isNotEmpty) 'include': include.map((t) => t.name).toList(),
      if (exclude.isNotEmpty) 'exclude': exclude,
    },
};
