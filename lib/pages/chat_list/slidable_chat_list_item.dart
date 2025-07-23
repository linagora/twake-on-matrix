import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_view_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SlidableChatListItem extends StatelessWidget {
  const SlidableChatListItem({
    super.key,
    required this.controller,
    required this.slidables,
    required this.chatListItem,
    this.enabled = true,
  });

  final ChatListController controller;
  final List<Widget> slidables;
  final Widget chatListItem;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      // Slidables must have the same groupTag for SlidableAutoCloseBehavior to work properly
      groupTag: 'slidable_list',
      enabled: enabled,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: ChatListViewStyle.slidableExtentRatio(slidables.length),
        children: slidables,
      ),
      child: chatListItem,
    );
  }
}
