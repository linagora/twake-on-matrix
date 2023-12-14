import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import '../../config/themes.dart';
import 'chat.dart';
import 'events/reply_content.dart';
import 'events/reply_content_style.dart';

class ReplyDisplay extends StatelessWidget {
  final ChatController controller;

  const ReplyDisplay(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: controller.editEvent != null || controller.replyEvent != null
          ? const EdgeInsets.symmetric(
              vertical: 8,
            )
          : EdgeInsets.zero,
      child: AnimatedContainer(
        duration: TwakeThemes.animationDuration,
        curve: TwakeThemes.animationCurve,
        height: controller.editEvent != null || controller.replyEvent != null
            ? ReplyContentStyle.replyContainerHeight
            : 0,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: controller.replyEvent != null
                  ? ReplyContent(
                      controller.replyEvent!,
                      timeline: controller.timeline!,
                    )
                  : _EditContent(
                      controller.editEvent
                          ?.getDisplayEvent(controller.timeline!),
                    ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              tooltip: L10n.of(context)!.close,
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: controller.cancelReplyEventAction,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditContent extends StatelessWidget {
  final Event? event;

  const _EditContent(this.event);

  @override
  Widget build(BuildContext context) {
    final event = this.event;
    if (event == null) {
      return Container();
    }
    return Row(
      children: <Widget>[
        Icon(
          Icons.edit,
          color: Theme.of(context).primaryColor,
        ),
        Container(width: 15.0),
        FutureBuilder<String>(
          future: event.calcLocalizedBody(
            MatrixLocals(L10n.of(context)!),
            withSenderNamePrefix: false,
            hideReply: true,
          ),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ??
                  event.calcLocalizedBodyFallback(
                    MatrixLocals(L10n.of(context)!),
                    withSenderNamePrefix: false,
                    hideReply: true,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
            );
          },
        ),
      ],
    );
  }
}
