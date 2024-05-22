import 'dart:math' as math;

import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:flutter/material.dart';

class ReplyIconWidget extends StatelessWidget {
  final bool isOwnMessage;

  const ReplyIconWidget({
    super.key,
    required this.isOwnMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: MessageStyle.replyIconFlexMobile,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isOwnMessage)
            const SizedBox(
              width: 8.0,
            ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MessageStyle.forwardColorBackground(context),
              ),
              width: MessageStyle.forwardContainerSize,
              height: MessageStyle.forwardContainerSize,
              child: const Icon(Icons.reply),
            ),
          ),
          if (!isOwnMessage)
            const SizedBox(
              width: 12.0,
            ),
        ],
      ),
    );
  }
}
