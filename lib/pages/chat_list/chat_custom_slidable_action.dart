import 'package:fluffychat/pages/chat_list/chat_list_view_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ChatCustomSlidableAction extends StatelessWidget {
  const ChatCustomSlidableAction({
    super.key,
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
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foregroundColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
