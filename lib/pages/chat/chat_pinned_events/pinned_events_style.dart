import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PinnedEventsStyle {
  static double maxHeight = 48.0.h;
  static double minHeightIndicator = 12;
  static double maxWidthIndicator = 2.0;
  static double maxLengthIndicator = 5.0;
  static double zeroHeight = 0;

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

  static EdgeInsetsDirectional marginPinnedEventsWidget =
      EdgeInsetsDirectional.symmetric(
    horizontal: 16.0.w,
    vertical: 8.0.h,
  );

  static EdgeInsetsDirectional paddingContentPinned =
      EdgeInsetsDirectional.symmetric(
    horizontal: 4.0.w,
  );
}
