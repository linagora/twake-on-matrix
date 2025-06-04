import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/events/reply_content.dart';
import 'package:fluffychat/pages/chat/reply_display_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ReplyDisplay extends StatelessWidget {
  final ChatController controller;

  const ReplyDisplay(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: controller.replyEventNotifier.value != null
          ? ReplyDisplayStyle.replyDisplayPadding
          : EdgeInsets.zero,
      child: AnimatedContainer(
        duration: TwakeThemes.animationDuration,
        curve: TwakeThemes.animationCurve,
        height: controller.replyEventNotifier.value != null
            ? ReplyDisplayStyle.replyContainerHeight
            : 0,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: controller.replyEventNotifier.value != null
                  ? ReplyContent(
                      controller.replyEventNotifier.value!,
                      timeline: controller.timeline!,
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: ReplyDisplayStyle.iconClosePadding,
              child: IconButton(
                tooltip: L10n.of(context)!.close,
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: onPressedAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onPressedAction() {
    if (controller.replyEventNotifier.value != null) {
      controller.cancelReplyEventAction();
      return;
    }
  }
}
