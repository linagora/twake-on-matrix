import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class AudioPlayerStyle {
  static const minWaveCount = 32;

  static const maxWaveWidth = 4.0;

  // UI element widths that take up space in the audio player
  static const playButtonWidth = 40.0;
  static const spacingAfterButton = 4.0;
  static const paddingLeft = 32.0;
  static const paddingRight = 32.0;

  static int maxWaveCount(BuildContext context) {
    // Calculate available width for waveform:
    // messageBubbleWidth - padding - playButton - spacing - safetyMargin
    final availableWidth = MessageStyle.messageBubbleWidth(context) -
        paddingLeft -
        paddingRight -
        playButtonWidth -
        spacingAfterButton;

    return availableWidth ~/ maxWaveWidth;
  }

  static const minWaveHeight = 4.0;

  static const maxWaveHeight = 26.0;

  static TextStyle? textInformationStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!.copyWith(
            color: LinagoraRefColors.material().tertiary[20],
          );
}
