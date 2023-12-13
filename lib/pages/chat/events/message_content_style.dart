import 'dart:math';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MessageContentStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();
  static double appBarFontSize = 16.0.sp;

  static double imageWidth(BuildContext context) {
    if (responsiveUtils.isDesktop(context)) {
      return imageBubbleWidthForWeb;
    }
    return imageBubbleWidthForMobileAndTablet;
  }

  static double imageHeight(BuildContext context) {
    if (responsiveUtils.isDesktop(context)) {
      return imageBubbleHeightForWeb;
    }
    return imageBubbleHeightForMobileAndTable;
  }

  static double imageBubbleHeightForWeb = 420.0.h;
  static double imageBubbleHeightForMobileAndTable = 320.0.h;
  static double imageBubbleWidthForMobileAndTablet = 256.0.w;
  static double imageBubbleWidthForWeb = 500.0.w;
  static double imageBubbleMinWidth = 120.0.w;
  static double imageBubbleMinHeight = 100.0.h;
  static double imageBubbleDefaultWidth = 292.0.w;
  static double imageBubbleDefaultHeight = 340.0.h;
  static Color backgroundColorButton = Colors.white.withAlpha(64);
  static String defaultBlurHash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';

  static double imageBubbleWidth(double displayWidth) => max(
        MessageContentStyle.imageBubbleMinWidth,
        displayWidth,
      );

  static double imageBubbleHeight(double displayHeight) => PlatformInfos.isWeb
      ? displayHeight
      : max(
          MessageContentStyle.imageBubbleMinHeight,
          displayHeight,
        );

  static double videoBubbleHeight(double displayHeight) => max(
        MessageContentStyle.imageBubbleMinHeight,
        displayHeight,
      );

  static double videoCenterButtonSize = 56.0.w;

  static double iconInsideVideoButtonSize = 48.0.w;

  static double strokeVideoWidth = 2.0.w;

  static Color backgroundColorCenterButton = Colors.black38;

  static BorderRadiusGeometry borderRadiusBubble =
      BorderRadius.all(Radius.circular(12.0.r));
}
