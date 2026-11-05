import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/domain/spaces/room_list_filter.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/domain/spaces/usecases/get_addable_spaces_usecase.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/get_space_children_usecase.provider.dart';
import 'package:twake_chat/domain/spaces/usecases/join_space_child_usecase.provider.dart';
import 'package:twake_chat/providers/room_list/folded_spaces_controller.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_entries_provider.dart';
import 'package:twake_chat/providers/room_list/room_list_filter_controller.dart';

part 'room_list_providers.freezed.dart';
part 'room_list_providers.g.dart';

/// What the list shows: a folder gone (renamed or deleted, here or on another
/// client) falls back on All.
@riverpod
RoomListFilter shownRoomListFilter(Ref ref) {
  final selected = ref.watch(roomListFilterControllerProvider);
  if (selected is RoomListFilterAll) return selected;
  final folders = ref.watch(roomListFoldersProvider);
  return folders.map(RoomListFilter.of).contains(selected)
      ? selected
      : const RoomListFilter.all();
}

/// What a space holds, joined or not, in its order. Read again when the space
/// lists something else; a failure keeps what was read before.
@riverpod
Future<List<SpaceChannel>> spaceChildren(Ref ref, String spaceId) {
  ref.watch(
    roomListEntriesProvider.select(
      (entries) => entries
          .firstWhereOrNull((entry) => entry.id == spaceId)
          ?.childIds
          .join(','),
    ),
  );
  return ref.watch(getSpaceChildrenUseCaseProvider).execute(spaceId);
}

/// The spaces a new room may go in. Read again once the rooms are loaded: an
/// account other than the first may land on a form before that.
@riverpod
List<SpaceSummary> addableSpaces(Ref ref) {
  ref.watch(roomChangesProvider);
  return ref.watch(getAddableSpacesUseCaseProvider).execute();
}

/// Joins what a space holds.
@riverpod
class SpaceJoinController extends _$SpaceJoinController {
  final Set<String> _joining = {};

  @override
  void build() {}

  /// False when the same join is already running: a second tap does nothing.
  ///
  /// Throws a `SpaceJoinFailedException`.
  Future<bool> join(String parentSpaceId, SpaceChannel child) async {
    if (!_joining.add(child.roomId)) return false;
    // Nobody listens to this provider: it must outlive the join.
    final link = ref.keepAlive();
    try {
      await ref
          .read(joinSpaceChildUseCaseProvider)
          .execute(child.roomId, via: child.via);
      if (ref.mounted) ref.invalidate(spaceChildrenProvider(parentSpaceId));
      return true;
    } finally {
      _joining.remove(child.roomId);
      link.close();
    }
  }
}

/// All the list needs to lay itself out.
@freezed
abstract class RoomListContent with _$RoomListContent {
  const factory RoomListContent({
    required List<RoomListEntry> visible,
    required Set<String> foldedSpaceIds,
    required Map<String, List<SpaceChannel>> joinableBySpace,
  }) = _RoomListContent;
}

/// Joinable sub-spaces of each joined space, watched in every view: a chip
/// and back must not read every space again.
Map<String, List<SpaceChannel>> _joinableBySpace(
  Ref ref,
  List<RoomListEntry> entries,
) {
  // Membership as of now: the hierarchy is read again only when a space lists
  // something else, not when the user leaves or joins what it holds.
  final joinedIds = {
    for (final entry in entries)
      if (entry.isJoined) entry.id,
  };
  return {
    for (final entry in entries)
      if (entry.isSpace && entry.isJoined)
        entry.id: joinableSubspaces([
          for (final child
              in ref.watch(spaceChildrenProvider(entry.id)).value ?? const [])
            child.copyWith(isJoined: joinedIds.contains(child.roomId)),
        ]),
  };
}

@riverpod
RoomListContent roomListContent(Ref ref, String? activeRoomId) {
  final view = ref.watch(shownRoomListFilterProvider);
  final entries = ref.watch(roomListEntriesProvider);
  final visible = visibleEntries(
    entries,
    view: view,
    activeRoomId: activeRoomId,
    folders: ref.watch(roomListFoldersProvider),
  );
  final joinableBySpace = _joinableBySpace(ref, entries);
  return RoomListContent(
    visible: visible,
    foldedSpaceIds: ref.watch(foldedSpacesControllerProvider).value ?? const {},
    joinableBySpace: {
      for (final entry in visible)
        if (entry.isSpace)
          entry.id: view.showsJoinableSubspaces
              ? joinableBySpace[entry.id] ?? const []
              : const [],
    },
  );
}
