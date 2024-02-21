import 'package:flutter/material.dart';

class ContextMenuItemImageViewerStyle {
  static const double width = 200;

  static const double height = 48;

  static const double dividerHeight = 1;

  static Color dividerColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceTint.withOpacity(0.16);

  static SizedBox get paddingBetweenItems => const SizedBox(width: 12);
}
