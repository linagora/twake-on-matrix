import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:collection/collection.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view_style.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        return ValueListenableBuilder<SelectMode>(
          valueListenable: controller.selectModeNotifier,
          builder: (context, selectMode, _) {
            final slidables = _getSlidables(context, rooms[index]);
            if (ChatListViewStyle.responsiveUtils.isMobileOrTablet(context) &&
                !selectMode.isSelectMode &&
                slidables.isNotEmpty) {
              return _SlidableChatListItem(
                controller: controller,
                slidables: slidables,
                chatListItem: _CommonChatListItem(
                  controller: controller,
                  room: rooms[index],
                ),
              );
            }
            return _CommonChatListItem(
              controller: controller,
              room: rooms[index],
            );
          },
        );
      },
    );
  }

  List<Widget> _getSlidables(BuildContext context, Room room) {
    return [
      if (!room.isInvitation)
        _ChatCustomSlidableAction(
          label:
              room.isUnread ? L10n.of(context)!.read : L10n.of(context)!.unread,
          icon: Icon(
            room.isUnread
                ? Icons.mark_chat_read_outlined
                : Icons.mark_chat_unread_outlined,
            size: ChatListViewStyle.slidableIconSize,
          ),
          onPressed: (_) => controller.toggleRead(room),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor: ChatListViewStyle.readSlidableColor(room.isUnread)!,
        ),
      _ChatCustomSlidableAction(
        label: room.isMuted ? L10n.of(context)!.unmute : L10n.of(context)!.mute,
        icon: Icon(
          room.isMuted
              ? Icons.notifications_off_outlined
              : Icons.notifications_on_outlined,
          size: ChatListViewStyle.slidableIconSize,
        ),
        onPressed: (_) => controller.toggleMuteRoom(room),
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: ChatListViewStyle.muteSlidableColor(room.isMuted)!,
      ),
      if (!room.isInvitation)
        _ChatCustomSlidableAction(
          label: room.isFavourite
              ? L10n.of(context)!.unpin
              : L10n.of(context)!.pin,
          icon: room.isFavourite
              ? SvgPicture.asset(
                  ImagePaths.icUnpin,
                  width: ChatListViewStyle.slidableIconSize,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                )
              : const Icon(
                  Icons.push_pin_outlined,
                  size: ChatListViewStyle.slidableIconSize,
                ),
          onPressed: (_) => controller.togglePin(room),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor:
              ChatListViewStyle.pinSlidableColor(room.isFavourite)!,
        ),
    ];
  }
}

class _ChatCustomSlidableAction extends StatelessWidget {
  const _ChatCustomSlidableAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Widget icon;
  final String label;
  final SlidableActionCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      autoClose: true,
      padding: ChatListViewStyle.slidablePadding,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: ChatListViewStyle.slidableIconTextGap),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foregroundColor,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
          onSecondaryTapDown: (detail) => controller.handleContextMenuAction(
            context,
            room,
            detail,
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
        extentRatio: ChatListViewStyle.slidableExtentRatio(slidables.length),
        children: slidables,
      ),
      child: chatListItem,
    );
  }
}
