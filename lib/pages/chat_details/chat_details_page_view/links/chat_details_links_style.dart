import 'package:flutter/material.dart';

class ChatDetailsLinksStyle {
  static const double avatarSize = 56;
  static BoxDecoration avatarDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      );
  static TextStyle? avatarTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSecondary,
          );
  static TextStyle? subtitleTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          );
}
