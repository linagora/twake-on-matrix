import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class AdaptiveScaffoldPrimaryNavigationStyle {
  static const EdgeInsetsDirectional primaryNavigationMargin =
      EdgeInsetsDirectional.only(top: 32, bottom: 32);
  static const EdgeInsetsDirectional dividerPadding =
      EdgeInsetsDirectional.only(bottom: 16);
  static const EdgeInsetsDirectional avatarPadding = EdgeInsetsDirectional.only(
    bottom: 8,
  );

  static TextStyle? labelTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      overflow: TextOverflow.ellipsis,
    );
  }

  static TextStyle? selectedLabelTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
      color: LinagoraSysColors.material().primary,
      overflow: TextOverflow.ellipsis,
    );
  }

  static const double primaryNavigationWidth = 80;
  static const double avatarSize = 56;
  static const double dividerSize = 2;

  static const Color separatorLightColor = Color(0xFFD7D8D9);
}
