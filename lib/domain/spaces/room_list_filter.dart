import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/spaces/folders.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/space_tree.dart';

part 'room_list_filter.freezed.dart';

/// What the chips of the room list select.
@freezed
sealed class RoomListFilter with _$RoomListFilter {
  const factory RoomListFilter.all() = RoomListFilterAll;
  const factory RoomListFilter.builtin(BuiltinFolder kind) =
      RoomListFilterBuiltin;
  const factory RoomListFilter.folder(String name) = RoomListFilterFolder;

  const RoomListFilter._();

  factory RoomListFilter.of(Folder folder) => switch (folder) {
    BuiltinFolderEntry(:final kind) => RoomListFilter.builtin(kind),
    UserFolder(:final name) => RoomListFilter.folder(name),
  };

  /// Only All and Spaces offer what a space holds and the user is not in.
  bool get showsJoinableSubspaces =>
      this is RoomListFilterAll ||
      this == const RoomListFilter.builtin(BuiltinFolder.spaces);
}

/// The entries the view shows, in their order.
List<RoomListEntry> visibleEntries(
  List<RoomListEntry> entries, {
  required RoomListFilter view,
  String? activeRoomId,
  List<Folder> folders = const [],
}) {
  final byId = {for (final entry in entries) entry.id: entry};
  bool isInBuiltin(RoomListEntry entry, BuiltinFolder kind) => switch (kind) {
    // The open room stays while it is read; a space is no conversation.
    BuiltinFolder.unread =>
      entry.isUnread || (!entry.isSpace && entry.id == activeRoomId),
    BuiltinFolder.favourites => entry.isFavourite,
    BuiltinFolder.spaces => entry.isSpace || parentSpaceOf(entry, byId) != null,
    BuiltinFolder.directs => entry.isDirect,
    BuiltinFolder.broadcasts => entry.kind == RoomKind.broadcast,
  };
  return switch (view) {
    RoomListFilterAll() => entries,
    RoomListFilterBuiltin(:final kind) =>
      entries.where((entry) => isInBuiltin(entry, kind)).toList(),
    RoomListFilterFolder(:final name) => switch (folders
        .whereType<UserFolder>()
        .firstWhereOrNull((folder) => folder.name == name)) {
      final folder? =>
        entries.where((entry) => isInFolder(entry, folder)).toList(),
      null => const [],
    },
  };
}
