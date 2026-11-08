import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';

part 'folders.freezed.dart';

/// The filters the chat list always had, folders like the others: ordered,
/// renamed, hidden. « All » is none of them, always first.
enum BuiltinFolder { unread, broadcasts, directs, spaces, favourites }

/// The kinds of chats a folder takes in by itself.
enum FolderChatType { direct, group, broadcast, bot }

/// A colour of the palette, `#rrggbb`.
@freezed
abstract class FolderColor with _$FolderColor {
  const factory FolderColor(String hex) = _FolderColor;

  const FolderColor._();

  static final RegExp _pattern = RegExp(
    r'^#[0-9a-f]{6}$',
    caseSensitive: false,
  );

  static FolderColor? tryParse(Object? value) =>
      value is String && _pattern.hasMatch(value) ? FolderColor(value) : null;

  int get argb => int.parse(hex.substring(1), radix: 16) + 0xFF000000;
}

@freezed
sealed class Folder with _$Folder {
  /// A filter whose rule is its own. [name] is the name the user gave it;
  /// empty for the label of the app. A hidden one can be added back.
  const factory Folder.builtin(
    BuiltinFolder kind, {
    @Default('') String name,
    String? emoji,
    FolderColor? color,
    @Default(false) bool hidden,
  }) = BuiltinFolderEntry;

  /// A folder of the user. Its chats picked one by one are the tags of the
  /// rooms; [exclude] holds room ids kept out, whatever tags and kinds say.
  const factory Folder.user(
    String name, {
    String? emoji,
    FolderColor? color,
    @Default(<FolderChatType>[]) List<FolderChatType> include,
    @Default(<String>[]) List<String> exclude,
  }) = UserFolder;
}

@freezed
abstract class FolderTagChange with _$FolderTagChange {
  /// A chat to put in a folder or to take out of it.
  const factory FolderTagChange({
    required String roomId,
    required String folderName,
    required bool isIn,
  }) = _FolderTagChange;
}

/// What is saved: the folders shown, in their order, then the built-ins not
/// among them, hidden.
List<Folder> withHiddenBuiltins(List<Folder> folders) {
  final shown = folders.where((folder) => !_isHidden(folder)).toList();
  bool isShown(BuiltinFolder kind) => shown.any(
    (folder) => folder is BuiltinFolderEntry && folder.kind == kind,
  );
  return [
    ...shown,
    for (final kind in BuiltinFolder.values)
      if (!isShown(kind)) Folder.builtin(kind, hidden: true),
  ];
}

bool _isHidden(Folder folder) => folder is BuiltinFolderEntry && folder.hidden;

/// The folders shown, in their order: the built-ins the account data does not
/// know first, then those of the account data but the hidden ones, then those
/// only the tags know, by name.
List<Folder> listFolders(List<Folder> saved, Iterable<String> taggedNames) {
  final known = saved.whereType<UserFolder>().map((f) => f.name).toSet();
  final tagged = taggedNames.toSet().difference(known).toList()..sort();
  final savedKinds = saved.whereType<BuiltinFolderEntry>().map((f) => f.kind);
  return [
    for (final kind in BuiltinFolder.values)
      if (!savedKinds.contains(kind)) Folder.builtin(kind),
    ...saved.where((folder) => !_isHidden(folder)),
    ...tagged.map(Folder.user),
  ];
}

/// The kind of a chat for the folders; a space is in none.
FolderChatType? folderChatTypeOf(RoomListEntry entry) => switch (entry.kind) {
  RoomKind.space => null,
  RoomKind.direct => FolderChatType.direct,
  RoomKind.bot => FolderChatType.bot,
  RoomKind.group => FolderChatType.group,
  RoomKind.broadcast => FolderChatType.broadcast,
};

/// Whether the folder holds the chat, evaluated at each read: a new direct
/// chat lands in a folder of direct chats by itself. Kept out wins, then
/// picked one by one (its tag), then its kind.
bool isInFolder(RoomListEntry entry, UserFolder folder) {
  if (entry.isSpace || folder.exclude.contains(entry.id)) return false;
  return entry.folders.contains(folder.name) ||
      folder.include.contains(folderChatTypeOf(entry));
}

/// What saving a folder changes: a ticked chat of a kind the folder does not
/// take in gets its tag, an unticked one of a kind it takes in is excluded.
/// Exclusions of chats not listed here stay.
({UserFolder folder, List<FolderTagChange> changes}) planFolderEdit({
  required UserFolder folder,
  required UserFolder? previous,
  required Set<String> picked,
  required List<RoomListEntry> chats,
}) {
  final previousName = previous?.name;
  final isRenamed = previousName != null && previousName != folder.name;
  bool isOfKind(RoomListEntry chat) =>
      folder.include.contains(folderChatTypeOf(chat));
  final listed = {for (final chat in chats) chat.id};
  final changes = <FolderTagChange>[];
  for (final chat in chats) {
    final wasIn = previousName != null && chat.folders.contains(previousName);
    final isIn = picked.contains(chat.id) && !isOfKind(chat);
    if (isIn && (!wasIn || isRenamed)) {
      changes.add(
        FolderTagChange(roomId: chat.id, folderName: folder.name, isIn: true),
      );
    }
    if (previousName != null && wasIn && (!isIn || isRenamed)) {
      changes.add(
        FolderTagChange(roomId: chat.id, folderName: previousName, isIn: false),
      );
    }
  }
  return (
    folder: folder.copyWith(
      exclude: [
        ...?previous?.exclude.where((id) => !listed.contains(id)),
        for (final chat in chats)
          if (!picked.contains(chat.id) && isOfKind(chat)) chat.id,
      ],
    ),
    changes: changes,
  );
}
