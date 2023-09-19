import 'package:flutter/material.dart';

class ChatDetailsMediaStyle {
  static const durationPadding = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 2,
  );

  static Decoration durationBoxDecoration(BuildContext context) =>
      ShapeDecoration(
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
        shape: const StadiumBorder(),
      );

  static TextStyle? durationTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          );

  static const double durationPosition = 10;
}
