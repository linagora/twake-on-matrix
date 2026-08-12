import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class DraftChatEmptyWidgetStyle {
  static final ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static final Color greetingButtonBackground = LinagoraSysColors.material()
      .onPrimary
      .withOpacity(0.5);

  static const double _mobileIconSize = 140;
  static const double _nonMobileIconSize = 180;
  static const double _mobileMaxWidth = 330;
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

  static TextStyle? subTitleStyle(BuildContext context) {
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

  static double maxWidth(BuildContext context) {
    if (responsiveUtils.isMobile(context)) {
      return _mobileMaxWidth;
    } else {
      return _nonMobileMaxWidth;
    }
  }
}
