import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class MessageTimeStyle {

  static Color? timelineColor(bool timelineOverlayMessage)  
    => timelineOverlayMessage
      ? Colors.white
      : LinagoraRefColors.material().neutral[50];

  static double get timelineLetterSpacing => 0.4;

  static double get paddingTimeAndIcon => 8;
  static double get seenByRowIconSize => 16;

  static TextStyle? textStyle(BuildContext context, bool timelineOverlayMessage) 
    => Theme.of(context).textTheme.bodySmall?.merge(
        TextStyle(
          color: timelineColor(timelineOverlayMessage),
          letterSpacing: 0.4
        ),
      );
}