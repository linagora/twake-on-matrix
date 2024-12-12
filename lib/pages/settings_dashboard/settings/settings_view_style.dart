import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class SettingsViewStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();
  static const double iconSize = 24.0;

  static const double fontSizeAvatar = 9 * 2.5;

  static const AlignmentGeometry alignment = AlignmentDirectional.centerStart;

  static EdgeInsetsDirectional itemBuilderPadding =
      const EdgeInsetsDirectional.only(top: 16.0, bottom: 16.0, start: 8.0);

  static EdgeInsetsDirectional leadingItemBuilderPadding =
      const EdgeInsetsDirectional.only(end: 8);

  static EdgeInsetsDirectional subtitleItemBuilderPadding =
      const EdgeInsetsDirectional.only(top: 4);

  static EdgeInsetsDirectional bodySettingsScreenPadding =
      const EdgeInsetsDirectional.symmetric(
    horizontal: 8,
  );

  static EdgeInsetsDirectional backupSwitchPadding =
      const EdgeInsetsDirectional.symmetric(
    horizontal: 24,
  );

  static EdgeInsetsDirectional avatarPadding =
      const EdgeInsetsDirectional.only(end: 8);

  static const double borderRadius = 4.0;
  static const double settingsItemDividerHeight = 1.0;
  static const double settingsItemDividerThikness = 1;
  static EdgeInsets settingsItemDividerPadding(BuildContext context) =>
      EdgeInsets.only(
        left: 48.0,
        right: responsiveUtils.isMobile(context) ? 0 : 8.0,
      );
  static EdgeInsets profileItemDividerPadding(BuildContext context) =>
      EdgeInsets.only(
        right: responsiveUtils.isMobile(context) ? 0 : 16.0,
      );
  static const double settingsItemHeight = 80;

  static const double maxWidthCancelButton = 127;
}
