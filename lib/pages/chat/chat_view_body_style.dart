import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatViewBodyStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double bottomSheetPadding(BuildContext context) =>
      TwakeThemes.isColumnMode(context) ? 16.0 : 8.0;

  static double chatScreenMaxWidth = 800.0;

  static double dividerSize = 1.0;

  static double blockedUserBannerHeight = 40.0;

  static const Color backgroundColor = Color(0xFFF4EFE8);

  static String get imageBackground => ImagePaths.chatBackground;

  static EdgeInsets inputBarPadding(BuildContext context) =>
      EdgeInsets.symmetric(
        horizontal: responsive.isMobile(context) ? 8.0 : 16.0,
      );
}
