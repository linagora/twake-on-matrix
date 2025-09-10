import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:flutter/material.dart';

class AudioPlayerStyle {
  static const minWaveCount = 32;

  static const maxWaveWidth = 4.0;

  static const maxBodyContentWidth = 88.0;

  static int maxWaveCount(BuildContext context) {
    return (MessageStyle.messageBubbleWidth(context) - maxBodyContentWidth) ~/
        maxWaveWidth;
  }

  static const minWaveHeight = 4.0;

  static const maxWaveHeight = 26.0;
}
