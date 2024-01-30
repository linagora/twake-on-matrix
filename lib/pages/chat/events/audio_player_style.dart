import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class AudioPlayerStyle {
  static const int waveMaxHeight = 26;
  static const int waveMinHeight = 1;
  static Color? waveColor(BuildContext context, bool ownMessage) {
    return ownMessage
        ? Theme.of(context).colorScheme.primary
        : LinagoraRefColors.material().neutral;
  }

  static double? waveHeight(int waveform, int maxValue) {
    if (waveform == 0) {
      return AudioPlayerStyle.waveMinHeight.toDouble();
    }
    return AudioPlayerStyle.waveMaxHeight * waveform / maxValue;
  }

  static Color? timerColor(BuildContext context, bool ownMessage) {
    return ownMessage
        ? LinagoraRefColors.material().primary[40]
        : Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static const double playAndWaveGap = 8;
}
