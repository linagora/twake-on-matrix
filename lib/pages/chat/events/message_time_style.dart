import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class MessageTimeStyle {
  static double get paddingTimeAndIcon => 8.0.w;
  static double get seenByRowIconSize => 16.0.w;
  static Color seenByRowIconPrimaryColor(
    bool timelineOverlayMessage,
    BuildContext context,
  ) =>
      timelineOverlayMessage ? Colors.white : Theme.of(context).primaryColor;
  static Color? seenByRowIconSecondaryColor(
    bool timelineOverlayMessage,
    BuildContext context,
  ) =>
      timelineOverlayMessage
          ? Theme.of(context).colorScheme.onPrimary
          : LinagoraRefColors.material().neutral[50];
}
