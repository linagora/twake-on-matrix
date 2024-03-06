import 'package:flutter/material.dart';

class PopupMenuWidgetStyle {
  // Context Menu
  static Color? defaultMenuColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static const double menuElevation = 2.0;
  static const double menuBorderRadius = 4.0;
  static const double menuMaxWidth = 305.0;

  // Context Menu Items
  static TextStyle? defaultItemTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          overflow: TextOverflow.ellipsis,
        );
  }

  static Color? defaultItemColorIcon(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static const double defaultItemIconSize = 24.0;
  static const EdgeInsets defaultItemPadding = EdgeInsets.all(12.0);
  static const double defaultItemHeight = 48.0;
  static const double defaultItemElementsGap = 12.0;
}
