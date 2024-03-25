import 'package:fluffychat/pages/chat/events/html_message.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' hide Visibility;

class MessageTextContent extends StatelessWidget {
  final Event event;
  final Color textColor;
  final double fontSize;
  final Widget endOfBubbleWidget;

  const MessageTextContent({
    super.key,
    required this.event,
    required this.textColor,
    required this.fontSize,
    required this.endOfBubbleWidget,
  });

  @override
  Widget build(BuildContext context) {
    var html = event.formattedText;

    if (event.messageType == MessageTypes.Emote) {
      html = '* $html';
    }
    final bigEmotes =
        event.onlyEmotes && event.numberEmotes > 0 && event.numberEmotes <= 10;

    return Padding(
      padding: MessageContentStyle.emojiPadding,
      child: HtmlMessage(
        html: html,
        defaultTextStyle: Theme.of(context).textTheme.bodyLarge,
        linkStyle: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          decorationColor: textColor.withAlpha(150),
        ),
        room: event.room,
        emoteSize: bigEmotes ? fontSize * 3 : fontSize * 1.5,
        bottomWidgetSpan: Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: endOfBubbleWidget,
        ),
      ),
    );
  }
}
