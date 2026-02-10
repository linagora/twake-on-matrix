import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_sort_rooms.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view_style.dart';
import 'package:fluffychat/pages/chat_list/common_chat_list_item.dart';
import 'package:fluffychat/pages/chat_list/slidable_chat_list_item.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
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
    return ChatListSortRooms(
      rooms: rooms,
      sortingRoomsNotifier: controller.sortingRoomsNotifier,
      builder: (sortedRooms, lastEventByRoomId) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return ValueListenableBuilder<SelectMode>(
                key: ValueKey(sortedRooms[index].id),
                valueListenable: controller.selectModeNotifier,
                builder: (context, selectMode, _) {
                  final slidables = controller.getSlidables(
                    context,
                    sortedRooms[index],
                  );
                  return SlidableChatListItem(
                    controller: controller,
                    slidables: slidables,
                    enabled:
                        ChatListViewStyle.responsiveUtils.isMobileOrTablet(
                          context,
                        ) &&
                        !selectMode.isSelectMode &&
                        slidables.isNotEmpty,
                    chatListItem: CommonChatListItem(
                      controller: controller,
                      room: sortedRooms[index],
                      lastEvent: lastEventByRoomId[sortedRooms[index].id],
                    ),
                  );
                },
              );
            },
            childCount: sortedRooms.length,
            findChildIndexCallback: (key) {
              return sortedRooms.indexWhere(
                (room) => room.id == (key as ValueKey).value,
              );
            },
          ),
        );
      },
    );
  }
}
