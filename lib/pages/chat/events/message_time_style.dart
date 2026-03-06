import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

final class MessageTimeStyle {
  static Color? timelineColor(bool timelineOverlayMessage) =>
      timelineOverlayMessage
      ? Colors.white
      : LinagoraRefColors.material().neutral[50];

  static double get timelineLetterSpacing => 0.4;
  static double get paddingTimeAndIcon => 8;
  static double get seenByRowIconSize => 16;

  static Color readReceiptColor(bool seenByOthers) => seenByOthers
      ? LinagoraSysColors.material().secondary
      : LinagoraRefColors.material().neutral[50]!;

  static Color seenByRowIconPrimaryColor(bool timelineOverlayMessage) =>
      timelineOverlayMessage
      ? Colors.white
      : LinagoraSysColors.material().secondary;

  static Color? seenByRowIconSecondaryColor(
    bool timelineOverlayMessage,
    ColorScheme colorScheme,
  ) => timelineOverlayMessage
      ? colorScheme.onPrimary
      : LinagoraRefColors.material().neutral[50];

  static TextStyle? textStyle(
    bool timelineOverlayMessage,
    TextTheme textTheme,
  ) => textTheme.bodySmall?.merge(
    TextStyle(color: timelineColor(timelineOverlayMessage), letterSpacing: 0.4),
  );
}
