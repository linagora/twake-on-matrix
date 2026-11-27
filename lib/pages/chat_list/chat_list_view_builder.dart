import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/domain/personalization/room_sections.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/chat_list_sort_rooms.dart';
import 'package:twake_chat/pages/chat_list/chat_list_view_style.dart';
import 'package:twake_chat/pages/chat_list/common_chat_list_item.dart';
import 'package:twake_chat/providers/room_list/folded_spaces_controller.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/joinable_subspace_row.dart';
import 'package:twake_chat/pages/chat_list/slidable_chat_list_item.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatListViewBuilder extends StatelessWidget {
  final ChatListController controller;

  /// Every room the list may show: the sort knows them all, so a chip shows
  /// its rooms at once.
  final List<Room> rooms;

  const ChatListViewBuilder({
    super.key,
    required this.controller,
    required this.rooms,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.widget.activeRoomIdNotifier,
      builder: (context, activeRoomId, _) => _RoomListSliver(
        controller: controller,
        rooms: rooms,
        activeRoomId: activeRoomId,
      ),
    );
  }
}

class _RoomListSliver extends ConsumerWidget {
  const _RoomListSliver({
    required this.controller,
    required this.rooms,
    required this.activeRoomId,
  });

  final ChatListController controller;
  final List<Room> rooms;
  final String? activeRoomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(roomListContentProvider(activeRoomId));
    final bySections = ref.watch(
      displayPreferencesProvider.select(
        (preferences) => preferences.roomOrder == RoomOrder.sections,
      ),
    );
    final entryById = {for (final entry in content.visible) entry.id: entry};
    return ChatListSortRooms(
      rooms: rooms,
      sortingRoomsNotifier: controller.sortingRoomsNotifier,
      builder: (sortedRooms, previewByRoomId) {
        // Every room belonged to an account that just logged out.
        if (sortedRooms.isEmpty && rooms.isNotEmpty) {
          return const SliverToBoxAdapter();
        }
        final roomById = {for (final room in sortedRooms) room.id: room};
        final visible = <RoomListEntry>[
          for (final room in sortedRooms) ?entryById[room.id],
        ];
        final rows =
            (bySections ? buildSectionedRoomListRows : buildRoomListRows)(
              visible,
              foldedSpaceIds: content.foldedSpaceIds,
              joinableBySpace: content.joinableBySpace,
            );
        final indexByKey = {
          for (final (index, row) in rows.indexed) row.key: index,
        };
        if (rows.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(L10n.of(context)!.roomListEmptyView)),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => switch (rows[index]) {
              final RoomListSectionTitleRow row => _SectionTitle(
                key: ValueKey(row.key),
                kind: row.kind,
              ),
              final RoomListJoinableRow row => JoinableSubspaceRow(
                key: ValueKey(row.key),
                row: row,
              ),
              final RoomListRoomRow row => _RoomRow(
                key: ValueKey(row.key),
                controller: controller,
                room: roomById[row.entry.id]!,
                depth: row.depth,
                previewResult: previewByRoomId[row.entry.id],
              ),
              final RoomListSpaceRow row => _RoomRow(
                key: ValueKey(row.key),
                controller: controller,
                room: roomById[row.entry.id]!,
                depth: row.depth,
                previewResult: previewByRoomId[row.entry.id],
                spaceRow: row,
              ),
            },
            childCount: rows.length,
            findChildIndexCallback: (key) =>
                indexByKey[(key as ValueKey).value],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({super.key, required this.kind});

  final RoomSectionKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    return Padding(
      padding: ChatListViewStyle.paddingSectionTitle,
      child: Text(
        switch (kind) {
          RoomSectionKind.unread => l10n.unread,
          RoomSectionKind.spaces => l10n.roomSectionSpaces,
          RoomSectionKind.directs => l10n.directChats,
          RoomSectionKind.groups => l10n.groups,
        },
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _RoomRow extends ConsumerWidget {
  const _RoomRow({
    super.key,
    required this.controller,
    required this.room,
    required this.depth,
    required this.previewResult,
    this.spaceRow,
  });

  final ChatListController controller;
  final Room room;
  final int depth;
  final RoomPreviewResult? previewResult;
  final RoomListSpaceRow? spaceRow;

  SpaceRowData? _spaceData(BuildContext context, WidgetRef ref) {
    final row = spaceRow;
    if (row == null) return null;
    return SpaceRowData(
      fold: row.fold,
      unreadCount: row.unreadCount,
      mentionCount: row.mentionCount,
      onToggleFold: () => ref
          .read(foldedSpacesControllerProvider.notifier)
          .toggle(row.entry.id),
      onAddSubspace: row.depth == 0 && row.entry.canAddChildren
          ? () => controller.goToNewSpace(context, parentSpaceId: row.entry.id)
          : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<SelectMode>(
      valueListenable: controller.selectModeNotifier,
      builder: (context, selectMode, _) {
        // A space is no conversation: read, mute and pin act on the space
        // room alone, not on the chats inside it.
        final slidables = spaceRow == null
            ? controller.getSlidables(context, room)
            : const <Widget>[];
        return SlidableChatListItem(
          controller: controller,
          slidables: slidables,
          enabled:
              ChatListViewStyle.responsiveUtils.isMobileOrTablet(context) &&
              !selectMode.isSelectMode &&
              slidables.isNotEmpty,
          chatListItem: CommonChatListItem(
            controller: controller,
            room: room,
            previewResult: previewResult,
            depth: depth,
            space: _spaceData(context, ref),
          ),
        );
      },
    );
  }
}
