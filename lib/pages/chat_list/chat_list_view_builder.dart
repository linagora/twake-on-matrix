import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:collection/collection.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view_style.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
    return SlidableAutoCloseBehavior(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rooms.length,
        itemBuilder: (BuildContext context, int index) {
          return ValueListenableBuilder<SelectMode>(
            valueListenable: controller.selectModeNotifier,
            builder: (context, selectMode, child) {
              final slidables = _getSlidables(context, rooms[index]);
              if (ChatListViewStyle.responsiveUtils.isMobileOrTablet(context) &&
                  !selectMode.isSelectMode &&
                  slidables.isNotEmpty) {
                return _SlidableChatListItem(
                  controller: controller,
                  slidables: slidables,
                  chatListItem: child!,
                );
              }

              return child!;
            },
            child: _CommonChatListItem(
              controller: controller,
              room: rooms[index],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _getSlidables(BuildContext context, Room room) {
    return [
      if (!room.isInvitation) ...[
        SlidableAction(
          autoClose: true,
          label: room.isFavourite
              ? L10n.of(context)!.unpin
              : L10n.of(context)!.pin,
          icon: room.isFavourite ? Icons.push_pin_outlined : Icons.push_pin,
          onPressed: (_) => controller.togglePin(room),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor:
              Colors.greenAccent[700] ?? ChatListViewStyle.pinSlidableColorRaw,
        ),
      ],
    ];
  }
}

class _CommonChatListItem extends StatelessWidget {
  const _CommonChatListItem({
    required this.controller,
    required this.room,
  });

  final ChatListController controller;
  final Room room;

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
          onSecondaryTap: () => controller.handleContextMenuAction(
            context,
            room,
          ),
          onLongPress: () => controller.onLongPressChatListItem(
            room,
          ),
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
        );
      },
    );
  }
}

class _SlidableChatListItem extends StatelessWidget {
  const _SlidableChatListItem({
    required this.controller,
    required this.slidables,
    required this.chatListItem,
  });

  final ChatListController controller;
  final List<Widget> slidables;
  final Widget chatListItem;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      // Slidables must have the same groupTag for SlidableAutoCloseBehavior to work properly
      groupTag: 'slidable_list',
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: ChatListViewStyle.slidableExtentRatio,
        children: slidables,
      ),
      child: chatListItem,
    );
  }
}
