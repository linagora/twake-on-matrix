import 'package:flutter/material.dart';

class GetStartedGuideStyle {
  static const EdgeInsets margin = EdgeInsets.fromLTRB(12, 4, 12, 8);
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(16, 12, 8, 12);
  static const EdgeInsets stepPadding = EdgeInsets.fromLTRB(16, 8, 16, 16);
  static const double radius = 16.0;
  static const double cardElevation = 0.0;

  static const double progressBarHeight = 6.0;
  static const double progressBarRadius = 8.0;

  static const double stepIconSize = 28.0;
  static const double stepIconBoxSize = 48.0;

  // Fixed height keeps the collapsing/paging animation from jumping.
  static const double pageViewHeight = 150.0;

  static const double dotSize = 7.0;
  static const double dotSpacing = 6.0;

  static const Duration animationDuration = Duration(milliseconds: 280);
  static const Curve animationCurve = Curves.easeInOut;
}
