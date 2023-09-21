import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatDetailsLinksStyle {
  static const double avatarSize = 56;
  static BoxDecoration avatarDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      );
  static const double margin = 16;
  static TextStyle? avatarTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSecondary,
          );
  static TextStyle? titleTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium;
  static TextStyle? descriptionTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: LinagoraRefColors.material().tertiary[20],
          );
  static TextStyle? linkTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          );
}
