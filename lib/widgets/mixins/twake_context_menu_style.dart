import 'package:flutter/material.dart';

class TwakeContextMenuStyle {
  static Color? defaultMenuColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static const double defaultVerticalPadding = 8.0;
  static const double menuElevation = 2.0;
  static const double menuBorderRadius = 4.0;
  static const double menuMinWidth = 196.0;
  static const double menuMaxWidth = 306.0;
}
