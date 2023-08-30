import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class MessageContentStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static int get maxLengthTextInline => 180;
  static double get appBarFontSize => 16.0;
  static double imageBubbleWidth(BuildContext context) {
    if (responsiveUtils.isDesktop(context)) {
      return 500;
    }
    return 256;
  }

  static double get imageBubbleHeight => 500;
  static Color get backgroundColorButton => Colors.white.withAlpha(64);

  static double get letterSpacingMessageContent => -0.15;
}
