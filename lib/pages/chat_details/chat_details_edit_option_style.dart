import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatDetailsEditOptionStyle {
  static const double defaultLeadingIconSize = 24.0;
  static const double defaultTrailingIconSize = 24.0;
  static const int titleMaxLines = 2;
  static const int subtitleMaxLines = 3;

  static Color defaultLeadingIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static const EdgeInsetsDirectional itemBuilderPadding =
      EdgeInsetsDirectional.only(top: 16, bottom: 16, start: 16, end: 8);
  static const EdgeInsetsDirectional leadingIconPadding =
      EdgeInsetsDirectional.only(end: 8.0);
  static const EdgeInsetsDirectional subtitleItemBuilderPadding =
      EdgeInsetsDirectional.only(top: 4.0);
  static const EdgeInsetsDirectional itemOptionPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 8.0);

  static TextStyle? titleTextStyle(BuildContext context, Color? titleColor) {
    return LinagoraTextStyle.material().bodyMedium2.copyWith(
      color: titleColor ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle? subtitleTextStyle(
    BuildContext context,
    Color? subtitleColor,
  ) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: subtitleColor ?? LinagoraRefColors.material().neutral[40],
    );
  }
}
