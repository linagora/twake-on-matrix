import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double get paddingVerticalActionButtons => 8.0;

  static double toolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 56 : 80;

  static EdgeInsetsDirectional paddingLeading(BuildContext context) =>
      EdgeInsetsDirectional.only(
        start: responsive.isMobile(context) ? 0 : 16,
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
          : Theme.of(context).colorScheme.onBackground;
}
