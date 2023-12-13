import 'package:fluffychat/config/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatViewBodyStyle {
  static double bottomSheetPadding(BuildContext context) =>
      (TwakeThemes.isColumnMode(context) ? 16.0 : 8.0).w;

  static double inputMessageWidgetMaxWidth = 800.0.w;

  static double dividerSize = 1.h;

  static EdgeInsets inputBarPadding = EdgeInsets.only(
    left: 8.0.w,
    right: 16.0.w,
  );
}
