import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatDetailsEditOptionStyle {
  static const double defaultLeadingIconSize = 24.0;
  static const double defaultTrailingIconSize = 24.0;
  static const int titleMaxLines = 2;
  static const int subtitleMaxLines = 3;

  static Color defaultLeadingIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static const EdgeInsetsDirectional itemBuilderPadding =
      EdgeInsetsDirectional.all(16.0);
  static const EdgeInsetsDirectional leadingIconPadding =
      EdgeInsetsDirectional.only(end: 8.0);
  static const EdgeInsetsDirectional subtitleItemBuilderPadding =
      EdgeInsetsDirectional.only(top: 4.0);

  static TextStyle? titleTextStyle(BuildContext context, Color? titleColor) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          color: titleColor ?? Theme.of(context).colorScheme.onSurface,
          fontSize: 16.0,
        );
  }

  static TextStyle? subtitleTextStyle(
    BuildContext context,
    Color? subtitleColor,
  ) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: subtitleColor ?? LinagoraRefColors.material().neutral[40],
          fontSize: 12.0,
        );
  }
}
