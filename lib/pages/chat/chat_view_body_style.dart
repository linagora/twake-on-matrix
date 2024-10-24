import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatViewBodyStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double bottomSheetPadding(BuildContext context) =>
      TwakeThemes.isColumnMode(context) ? 16.0 : 8.0;

  static double chatScreenMaxWidth = 800.0;

  static double dividerSize = 1.0;

  static Color chatViewBackgroundColor(BuildContext context) =>
      responsive.isMobile(context)
          ? LinagoraSysColors.material().background
          : LinagoraSysColors.material().onPrimary;

  static EdgeInsets inputBarPadding(BuildContext context) => EdgeInsets.only(
        left: responsive.isMobile(context) ? 8.0 : 16.0,
        right: responsive.isMobile(context) ? 8.0 : 16.0,
      );
}
