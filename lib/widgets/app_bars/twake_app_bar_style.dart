import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/style/linagora_text_style.dart';

class TwakeAppBarStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();
  bool isMobile(BuildContext context) => responsiveUtils.isMobile(context);

  static Color appBarBackgroundColor(BuildContext context) =>
      responsiveUtils.isMobile(context)
          ? LinagoraSysColors.material().background
          : LinagoraSysColors.material().onPrimary;
  static TextStyle? titleTextStyle(BuildContext context) =>
      responsiveUtils.isMobile(context)
          ? LinagoraTextStyle.material().bodyLarge1.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 24 / 17,
              )
          : Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 32 / 24,
              );

  static const double dividerHeight = 1.0;
  static const double dividerthickness = 1.0;
  static const EdgeInsets leadingIconPadding = EdgeInsets.only(left: 12);
  static const double leadingIconSize = 24;
}
