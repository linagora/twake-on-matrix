import 'package:flutter/material.dart';
import 'package:twake_chat/pages/chat_details/chat_details_edit_view_style.dart';

class ChatDetailsEditCategory extends StatelessWidget {
  const ChatDetailsEditCategory({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: ChatDetailEditViewStyle.textChatDetailsEditCategoryStyle(
          context,
        ),
      ),
    );
  }
}
