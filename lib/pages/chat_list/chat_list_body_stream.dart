import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/config/themes.dart';

import 'chat_list_body.dart';

class ChatListBodyStream extends StatelessWidget {
  final ChatListController controller;

  const ChatListBodyStream({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object?>(
      stream: Matrix.of(context).onShareContentChanged.stream,
      builder: (_, __) {
        return Row(
          children: [
            if (FluffyThemes.isColumnMode(context) &&
                FluffyThemes.getDisplayNavigationRail(context)) ...[
              Container(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ],
            Expanded(
              child: GestureDetector(
                onTap: FocusManager.instance.primaryFocus?.unfocus,
                excludeFromSemantics: true,
                behavior: HitTestBehavior.translucent,
                child: ChatListViewBody(controller),
              ),
            ),
          ],
        );
      },
    );
  }
}
