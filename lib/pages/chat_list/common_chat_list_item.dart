import 'package:collection/collection.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class CommonChatListItem extends StatelessWidget {
  final ChatListController controller;
  final Room room;
  final Event? lastEvent;

  const CommonChatListItem({
    super.key,
    required this.controller,
    required this.room,
    this.lastEvent,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.widget.activeRoomIdNotifier,
      builder: (context, activeRoomId, child) {
        return ChatListItem(
          room,
          key: Key('chat_list_item_${room.id}'),
          isEnableSelectMode: controller.isSelectMode,
          onTap: controller.isSelectMode
              ? () => controller.toggleSelection(room.id)
              : null,
          onSecondaryTapDown: (detail) =>
              controller.handleContextMenuAction(context, room, detail),
          onLongPress: () => controller.onLongPressChatListItem(room),
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
          lastEvent: lastEvent,
        );
      },
    );
  }
}
