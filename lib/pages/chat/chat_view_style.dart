import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double get paddingVerticalActionButtons => 8.0;

  static const double pinnedMessageHintHeight = 48;

  static const double appBarIconSize = 24.0;

  static EdgeInsetsDirectional paddingLeading(BuildContext context) =>
      EdgeInsetsDirectional.only(
        start: responsive.isMobile(context) ? 0 : 16,
      );
  static EdgeInsetsDirectional paddingTrailing(BuildContext context) =>
      EdgeInsetsDirectional.only(
        end: responsive.isMobile(context) ? 0 : 16,
      );

  static BoxDecoration searchBottomViewDecoration(BuildContext context) =>
      BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      );

  static const EdgeInsetsDirectional noSearchResultPadding =
      EdgeInsetsDirectional.all(8);

  static const double searchLoadingSize = 16;

  static const double searchLoadingStrokeWidth = 2;

  static Color searchControlColor(
    BuildContext context, {
    required bool active,
  }) =>
      active
          ? Theme.of(context).colorScheme.primary
          // TODO: change to colorSurface when its approved
          // ignore: deprecated_member_use
          : Theme.of(context).colorScheme.onBackground;

  static const paddingBottomContextMenu = 16.0;

  static double appBarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 64 : 56;
}
