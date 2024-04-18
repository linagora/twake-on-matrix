import 'package:fluffychat/pages/chat_details/chat_details_page_view/files/chat_details_files_item/chat_details_files_item_style.dart';
import 'package:flutter/material.dart';

class ChatDetailsFileRowBody extends StatelessWidget {
  const ChatDetailsFileRowBody({
    super.key,
    required this.child,
    required this.trailingIcon,
    required this.iconColor,
  });

  final IconData trailingIcon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ChatDetailsFileTileStyle.bodyPadding,
      height: ChatDetailsFileTileStyle.tileHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: ChatDetailsFileTileStyle.dividerHeight,
            color: ChatDetailsFileTileStyle.dividerColor(context),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: ChatDetailsFileTileStyle.bodyChildPadding,
              child: child,
            ),
          ),
          Padding(
            padding: ChatDetailsFileTileStyle.trailingPadding,
            child: Icon(
              trailingIcon,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
