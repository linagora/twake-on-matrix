import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class GroupChatEmptyViewStyle {
  static final ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double _mobileIconSize = 140;
  static const double _nonMobileIconSize = 180;
  static const double _nonMobileMaxWidth = 442;

  static double iconSize(BuildContext context) {
    if (responsiveUtils.isMobile(context)) {
      return _mobileIconSize;
    } else {
      return _nonMobileIconSize;
    }
  }

  static TextStyle? titleStyle(BuildContext context) {
    if (responsiveUtils.isMobile(context)) {
      return Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: LinagoraSysColors.material().onSurface,
      );
    } else {
      return Theme.of(context).textTheme.headlineLarge?.copyWith(
        color: LinagoraSysColors.material().onSurface,
      );
    }
  }

  static TextStyle? ruleStyle(BuildContext context) {
    if (responsiveUtils.isMobile(context)) {
      return Theme.of(context).textTheme.labelLarge?.copyWith(
        color: LinagoraRefColors.material().tertiary[20],
      );
    } else {
      return Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: LinagoraRefColors.material().tertiary[20],
      );
    }
  }

  static EdgeInsetsGeometry rulePadding(BuildContext context) {
    if (responsiveUtils.isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 12);
    } else {
      return const EdgeInsets.symmetric(horizontal: 80);
    }
  }

  static double maxWidth(BuildContext context) {
    if (responsiveUtils.isMobile(context)) {
      return minWidth;
    } else {
      return _nonMobileMaxWidth;
    }
  }

  static const double minWidth = 330;
}
