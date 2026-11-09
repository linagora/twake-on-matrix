import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/spaces/folders.dart';

/// The account data every Twake client shares its folders in.
const String foldersAccountDataType = 'app.twake.chat.folders';

/// The folders of the account data, whatever a client wrote there.
List<Folder> readFolders(Map<String, Object?>? content) {
  final list = content?['folders'];
  if (list is! List) {
    if (list != null) Logs().w('readFolders: malformed folders');
    return const [];
  }
  // A built-in is known by its kind, a folder by its name: « spaces » is
  // both a kind and a name a folder may have.
  final kinds = <BuiltinFolder>{};
  final names = <String>{};
  final folders = <Folder>[];
  final items = list.whereType<Map>().toList();
  if (items.length != list.length) Logs().w('readFolders: malformed folder');
  for (final item in items) {
    if (_isUnknownBuiltin(item)) continue;
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

/// A built-in of a newer client: this one has no rule for it.
bool _isUnknownBuiltin(Map item) {
  final kind = item['builtin'];
  return kind != null && !BuiltinFolder.values.asNameMap().containsKey(kind);
}

const Set<String> _folderKeys = {
  'builtin',
  'name',
  'emoji',
  'color',
  'hidden',
  'include',
  'exclude',
};

/// The content written back, without the empty parts. What another client
/// keeps in [current] and this one does not know stays; the built-ins this one
/// has no rule for move to the end.
Map<String, Object?> writeFolders(
  List<Folder> folders, {
  Map<String, Object?>? current,
}) {
  final stored = current?['folders'];
  final items = stored is List
      ? stored.whereType<Map>().toList()
      : const <Map>[];
  return {
    ...?current,
    'folders': [
      for (final folder in folders.map(_writeFolder))
        {..._unknownFieldsOf(items, folder), ...folder},
      ...items.where(_isUnknownBuiltin),
    ],
  };
}

Map<Object?, Object?> _unknownFieldsOf(
  List<Map> items,
  Map<String, Object?> folder,
) {
  final builtin = folder['builtin'];
  final item = items.firstWhereOrNull(
    (item) => builtin != null
        ? item['builtin'] == builtin
        : item['builtin'] == null && item['name'] == folder['name'],
  );
  return {...?item}..removeWhere((key, _) => _folderKeys.contains(key));
}

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
