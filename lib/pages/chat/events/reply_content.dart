import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/events/reply_content_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import '../../../config/app_config.dart';
import 'html_message.dart';

class ReplyContent extends StatelessWidget {
  final Event replyEvent;
  final bool ownMessage;
  final Timeline? timeline;
  final ChatController chatController;

  const ReplyContent(
    this.replyEvent, {
    this.ownMessage = false,
    required this.chatController,
    Key? key,
    this.timeline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget replyBody;
    final timeline = this.timeline;
    final displayEvent =
        timeline != null ? replyEvent.getDisplayEvent(timeline) : replyEvent;
    if (AppConfig.renderHtml &&
        [EventTypes.Message, EventTypes.Encrypted]
            .contains(displayEvent.type) &&
        [MessageTypes.Text, MessageTypes.Notice, MessageTypes.Emote]
            .contains(displayEvent.messageType) &&
        !displayEvent.redacted &&
        displayEvent.content['format'] == 'org.matrix.custom.html' &&
        displayEvent.content['formatted_body'] is String) {
      String? html = (displayEvent.content['formatted_body'] as String?);
      if (displayEvent.messageType == MessageTypes.Emote) {
        html = '* $html';
      }
      replyBody = HtmlMessage(
        html: html!,
        defaultTextStyle: ReplyContentStyle.replyBodyTextStyle(context),
        maxLines: 1,
        room: displayEvent.room,
        emoteSize: ReplyContentStyle.fontSizeDisplayContent * 1.5,
        event: timeline!.events.first,
        chatController: chatController,
      );
    } else {
      replyBody = Text(
        displayEvent.calcLocalizedBodyFallback(
          MatrixLocals(L10n.of(context)!),
          withSenderNamePrefix: false,
          hideReply: true,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: ReplyContentStyle.replyBodyTextStyle(context),
      );
    }
    final user = displayEvent.getUser();
    return Container(
      padding: ReplyContentStyle.replyParentContainerPadding,
      decoration:
          ReplyContentStyle.replyParentContainerDecoration(context, ownMessage),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: ReplyContentStyle.prefixBarVerticalPadding,
              ),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: ReplyContentStyle.fontSizeDisplayContent * 2,
                ),
                width: ReplyContentStyle.prefixBarWidth,
                decoration: ReplyContentStyle.prefixBarDecoration(context),
              ),
            ),
            const SizedBox(
              width: ReplyContentStyle.prefixAndDisplayNameSpacing,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (user != null)
                    Text(
                      user.calcDisplayname(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ReplyContentStyle.displayNameTextStyle(context),
                    ),
                  if (displayEvent.getUser() == null)
                    FutureBuilder<User?>(
                      future: displayEvent.fetchSenderUser(),
                      builder: (context, snapshot) {
                        return Text(
                          '${snapshot.data?.calcDisplayname() ?? displayEvent.senderFromMemoryOrFallback.calcDisplayname()}:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              ReplyContentStyle.displayNameTextStyle(context),
                        );
                      },
                    ),
                  replyBody,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
