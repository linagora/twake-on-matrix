import 'package:flutter/material.dart';

class AppGridDashboardItemStyle {
  static const double iconAppSize = 42.0;
  static const double itemWidth = 80.0;

  static const EdgeInsets padding = EdgeInsets.only(
    bottom: 4,
    top: 8,
  );
  static const EdgeInsets textPadding = EdgeInsets.only(top: 8);

  static const BorderRadius borderRadius =
      BorderRadius.all(Radius.circular(10));

  static TextStyle? textStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall;
}
