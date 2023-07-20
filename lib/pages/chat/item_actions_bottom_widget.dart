import 'package:fluffychat/pages/chat/chat_actions.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

typedef OnItemAction = void Function(ChatActions);

class ItemActionOnBottom extends StatelessWidget {
  final ChatActions chatActions;
  final OnItemAction onItemAction;
  const ItemActionOnBottom(
      {super.key, required this.chatActions, required this.onItemAction});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onItemAction.call(chatActions),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: ShapeDecoration(
              color: chatActions.getBackgroundColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36),
              ),
            ),
            child: Icon(
              chatActions.getIcon(),
              color: chatActions.getIconColor(),
            ),
          ),
          Text(
            chatActions.getTitle(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LinagoraSysColors.material().onBackground,
                ),
          ),
        ],
      ),
    );
  }
}
