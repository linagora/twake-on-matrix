import 'package:flutter/material.dart';

class TwakeContextMenuStyle {
  static Color? defaultMenuColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color? defaultItemColorIcon(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static const double defaultVerticalPadding = 8.0;
  static const double menuElevation = 2.0;
  static const double menuBorderRadius = 4.0;
  static const double menuMinWidth = 196.0;
  static const double menuMaxWidth = 306.0;
  static const double defaultItemIconSize = 24.0;
  static const EdgeInsets defaultItemPadding = EdgeInsets.all(12.0);
  static const double defaultItemElementsGap = 12.0;
  static TextStyle? defaultItemTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          overflow: TextOverflow.ellipsis,
        );
  }
}
