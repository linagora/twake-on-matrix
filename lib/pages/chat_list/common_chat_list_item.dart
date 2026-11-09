import 'package:collection/collection.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class CommonChatListItem extends StatelessWidget {
  final ChatListController controller;
  final Room room;
  final RoomPreviewResult? previewResult;
  final int depth;
  final SpaceRowData? space;

  const CommonChatListItem({
    super.key,
    required this.controller,
    required this.room,
    this.previewResult,
    this.depth = 0,
    this.space,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.widget.activeRoomIdNotifier,
      builder: (context, activeRoomId, child) {
        return ChatListItem(
          room,
          key: Key('chat_list_item_${room.id}'),
          isEnableSelectMode: controller.isSelectMode && space == null,
          onTap: !controller.isSelectMode
              ? null
              : space != null
              // Not null: a row without onTap opens its room.
              ? () {}
              : () => controller.toggleSelection(room.id),
          // Same as the swipe: nothing the menu offers fits a space.
          onSecondaryTapDown: space != null
              ? null
              : (detail) =>
                    controller.handleContextMenuAction(context, room, detail),
          onLongPress: space != null
              ? null
              : () => controller.onLongPressChatListItem(room),
          checkBoxWidget: ValueListenableBuilder(
            valueListenable: controller.conversationSelectionNotifier,
            builder: (context, conversationSelection, __) {
              final conversation = conversationSelection.firstWhereOrNull(
                (conversation) => conversation.roomId.contains(room.id),
              );
              return Checkbox(
                value: conversation?.isSelected == true,
                onChanged: (_) {
                  controller.toggleSelection(room.id);
                },
              );
            },
          ),
          activeChat: activeRoomId == room.id,
          previewResult: previewResult,
          depth: depth,
          space: space,
        );
      },
    );
  }
}
