import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatInvitationBodyStyle {
  static final ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static final Color backgroundColor = LinagoraSysColors.material().onPrimary
      .withOpacity(0.5);

  static const double _mobileIconSize = 140;
  static const double _nonMobileIconSize = 180;

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

  // Dialog Parent
  static const double dialogBorderRadius = 16.0;
  static const double dialogPadding = 16.0;

  // Dialog Buttons
  static const double dialogButtonSpacing = 8.0;
  static const double dialogButtonBorderRadius = 100.0;
  static const double dialogButtonHeight = 48.0;

  // Chat Invitation Bottom Bar
  static const double chatInvitationBottomBarPadding = 16.0;
  static const double chatInvitationBottomBarHeight = 96.0;
  static const double chatInvitationBottomBarIconSize = 24.0;
  static const double chatInvitationBottomBarIconSpacing = 8.0;

  static const double _mobileMaxWidth = 330;
  static const double _nonMobileMaxWidth = 442;

  static double maxWidth(BuildContext context) {
    if (responsiveUtils.isMobile(context)) {
      return _mobileMaxWidth;
    } else {
      return _nonMobileMaxWidth;
    }
  }
}
