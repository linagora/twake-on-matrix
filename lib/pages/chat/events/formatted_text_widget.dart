import 'package:fluffychat/pages/chat/events/html_message.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/markdown_fix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' hide Visibility;

class FormattedTextWidget extends StatelessWidget {
  final Event event;
  final double fontSize;
  final TextStyle? linkStyle;

  const FormattedTextWidget({
    super.key,
    required this.event,
    required this.fontSize,
    this.linkStyle,
  });

  @override
  Widget build(BuildContext context) {
    var html = fixDoubleEncodedCodeBlocks(event.formattedText);

    if (event.messageType == MessageTypes.Emote) {
      html = '* $html';
    }
    final bigEmotes =
        event.onlyEmotes && event.numberEmotes > 0 && event.numberEmotes <= 10;

    return HtmlMessage(
      html: html,
      defaultTextStyle: event.getMessageTextStyle(context),
      linkStyle: linkStyle,
      room: event.room,
      emoteSize: bigEmotes ? fontSize * 3 : fontSize * 1.5,
    );
  }
}
