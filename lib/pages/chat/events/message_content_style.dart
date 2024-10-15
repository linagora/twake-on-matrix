import 'dart:math';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class MessageContentStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const int maxLengthTextInline = 180;
  static const double appBarFontSize = 16.0;
  static Duration animationSwitcherDuration = const Duration(milliseconds: 300);

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

  static const double letterSpacingMessageContent = -0.15;

  static const double videoCenterButtonSize = 56;

  static const double iconInsideVideoButtonSize = 48;

  static const double cancelButtonSize = 28;

  static const double downloadButtonSize = 32;

  static const double strokeVideoWidth = 2;

  static const Color backgroundColorCenterButton = Colors.black38;

  static const BorderRadius borderRadiusBubble =
      BorderRadius.all(Radius.circular(12.0));

  static const backIconColor = Colors.white;

  static const EdgeInsets endOfBubbleWidgetPadding =
      EdgeInsets.symmetric(vertical: 4);

  static const EdgeInsets emojiPadding = EdgeInsets.symmetric(
    horizontal: 8.0,
  );

  static TextStyle? linkStyleMessageContent(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          );

  static const blurhashSize = 32;

  static const iconErrorSize = 36.0;
}
