import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class MessageContentStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const int maxLengthTextInline = 180;
  static const double appBarFontSize = 16.0;

  static double imageBubbleWidth(BuildContext context) {
    if (responsiveUtils.isDesktop(context)) {
      return imageBubbleWidthForWeb;
    }
    return imageBubbleWidthForMobileAndTablet;
  }

  static double imageBubbleHeight(BuildContext context) {
    if (responsiveUtils.isDesktop(context)) {
      return imageBubbleHeightForWeb;
    }
    return imageBubbleHeightForMobileAndTable;
  }

  static const double imageBubbleHeightForWeb = 420;
  static const double imageBubbleHeightForMobileAndTable = 320;
  static const double imageBubbleWidthForMobileAndTablet = 256;
  static const double imageBubbleWidthForWeb = 500;
  static const double imageBubbleMinWidth = 120;
  static const double imageBubbleMinHeight = 100;
  static const double imageBubbleDefaultWidth = 292;
  static const double imageBubbleDefaultHeight = 340;
  static Color backgroundColorButton = Colors.white.withAlpha(64);
  static const String defaultBlurHash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';

  static const double letterSpacingMessageContent = -0.15;
}
