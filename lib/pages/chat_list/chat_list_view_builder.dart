import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view_style.dart';
import 'package:fluffychat/pages/chat_list/common_chat_list_item.dart';
import 'package:fluffychat/pages/chat_list/slidable_chat_list_item.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatListViewBuilder extends StatelessWidget {
  final ChatListController controller;
  final List<Room> rooms;
  final SyncUpdate? syncUpdate;

  const ChatListViewBuilder({
    super.key,
    required this.controller,
    required this.rooms,
    this.syncUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        return ValueListenableBuilder<SelectMode>(
          valueListenable: controller.selectModeNotifier,
          builder: (context, selectMode, _) {
            final slidables = controller.getSlidables(context, rooms[index]);
            if (ChatListViewStyle.responsiveUtils.isMobileOrTablet(context) &&
                !selectMode.isSelectMode &&
                slidables.isNotEmpty) {
              return SlidableChatListItem(
                controller: controller,
                slidables: slidables,
                chatListItem: CommonChatListItem(
                  controller: controller,
                  room: rooms[index],
                  joinedRoomUpdate: syncUpdate?.rooms?.join?[rooms[index].id],
                ),
              );
            }
            return CommonChatListItem(
              controller: controller,
              room: rooms[index],
              joinedRoomUpdate: syncUpdate?.rooms?.join?[rooms[index].id],
            );
          },
        );
      },
    );
  }
}
