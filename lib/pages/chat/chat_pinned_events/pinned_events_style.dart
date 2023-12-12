import 'package:flutter/material.dart';

class PinnedEventsStyle {
  static const double maxHeight = 48;
  static const double maxWidthContextItem = 100;
  static const double minWidthContextItem = 80;
  static const double minHeightIndicator = 12;
  static const double maxWidthIndicator = 2.0;
  static const double maxLengthIndicator = 5.0;
  static const double iconListSize = 24;
  static const double zeroHeight = 0;

  static double calcHeightIndicator(int length) {
    if (length < 1) {
      return zeroHeight;
    }

    if (length < maxLengthIndicator) {
      return maxHeight / length;
    } else {
      return minHeightIndicator;
    }
  }

  static const EdgeInsetsDirectional marginPinnedEventsWidget =
      EdgeInsetsDirectional.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  static const EdgeInsetsDirectional paddingContentPinned =
      EdgeInsetsDirectional.symmetric(
    horizontal: 4.0,
  );

  static EdgeInsets get marginPinIcon => const EdgeInsets.only(top: 4.0);
  static const double paddingPinIcon = 8.0;
}
