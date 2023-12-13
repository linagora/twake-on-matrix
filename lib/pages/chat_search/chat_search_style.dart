import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatSearchStyle {
  static EdgeInsetsGeometry inputPadding = EdgeInsetsDirectional.only(
    start: 8.0.w,
    top: 16.0.h,
    bottom: 16.0.h,
    end: 16.0.w,
  );

  static EdgeInsetsGeometry itemMargin =
      EdgeInsetsDirectional.symmetric(horizontal: 16.0.w);

  static EdgeInsetsGeometry itemPadding =
      EdgeInsetsDirectional.only(end: 8.0.w);

  static EdgeInsetsGeometry avatarPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 8.0.w, vertical: 16.0.h);

  static EdgeInsetsGeometry emptyPadding = EdgeInsetsDirectional.all(16.0.w);

  static double emptyGap = 128.0.h;

  static double itemHeight = 90.0.h;

  static double itemBorderRadius = 12.0.r;
}
