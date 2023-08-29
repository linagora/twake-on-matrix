import 'package:fluffychat/pages/forward/selectable_chat_list_item.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class RecentChatList extends StatelessWidget {
  const RecentChatList({
    super.key,
    required this.rooms,
    required this.recentChatScrollController,
    required this.selectedEventsNotifier,
    required this.onSelectedChat,
  });

  final List<Room> rooms;

  final ScrollController recentChatScrollController;

  final ValueNotifier<List<String>> selectedEventsNotifier;

  final void Function(String roomId) onSelectedChat;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: selectedEventsNotifier,
      builder: (context, selectedEvents, child) {
        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          controller: recentChatScrollController,
          itemCount: rooms.length,
          itemBuilder: (BuildContext context, int index) {
            return SelectableChatListItem(
              rooms[index],
              key: Key('selectable_chat_list_item_${rooms[index].id}'),
              selected: selectedEvents.contains(rooms[index].id),
              onTap: () {
                onSelectedChat(rooms[index].id);
              },
            );
          },
        );
      },
    );
  }
}
