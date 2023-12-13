import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InputBarStyle {
  static double suggestionAvatarSize = 30.0.w;

  static double suggestionAvatarFontSize = 15.0.sp;

  static double suggestionSize = 50.0.h;

  static double suggestionBorderRadius = 12.0.r;

  static double suggestionListPadding = 8.0.h;

  static TextStyle getTypeAheadTextStyle(BuildContext context) => TextStyle(
        fontSize: 15.0.sp,
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white,
      );

  static double suggestionTileAvatarTextGap = 8.0.w;
}
