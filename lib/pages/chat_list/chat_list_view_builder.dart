import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatListViewBuilder extends StatelessWidget {
  final ChatListController controller;
  final List<Room> rooms;

  const ChatListViewBuilder({
    super.key,
    required this.controller,
    required this.rooms,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        return ValueListenableBuilder(
          valueListenable: controller.selectModeNotifier,
          builder: (context, _, __) {
            return ChatListItem(
              rooms[index],
              key: Key('chat_list_item_${rooms[index].id}'),
              isEnableSelectMode: controller.isSelectMode,
              onTap: controller.isSelectMode
                  ? () => controller.toggleSelection(rooms[index].id)
                  : null,
              onSecondaryTap: () => controller.handleContextMenuAction(
                context,
                rooms[index],
              ),
              onLongPress: () => controller.onLongPressChatListItem(
                rooms[index],
              ),
              checkBoxWidget: ValueListenableBuilder(
                valueListenable: controller.conversationSelectionNotifier,
                builder: (context, conversationSelection, __) {
                  final conversation = conversationSelection.firstWhereOrNull(
                    (conversation) =>
                        conversation.roomId.contains(rooms[index].id),
                  );
                  return Checkbox(
                    value: conversation?.isSelected == true,
                    onChanged: (_) {
                      controller.toggleSelection(rooms[index].id);
                    },
                  );
                },
              ),
              activeChat: controller.activeRoomId == rooms[index].id,
            );
          },
        );
      },
    );
  }
}
