import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:flutter/material.dart';

class AudioPlayerStyle {
  static const minWaveCount = 32;

  static int maxWaveCount(BuildContext context) {
    return (MessageStyle.messageBubbleWidth(context) - 88) ~/ 4;
  }
}
