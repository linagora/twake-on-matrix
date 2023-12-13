import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatListBodyViewStyle {
  static double sizeIconExpand = 24.r;

  static double heightIsTorBrowser(bool isTorBrowser) =>
      isTorBrowser ? 64.h : 0;

  static EdgeInsetsDirectional paddingIconSkeletons =
      EdgeInsetsDirectional.only(
    top: 64.h,
  );

  static EdgeInsetsDirectional paddingOwnProfile = EdgeInsetsDirectional.only(
    top: 16.h,
  );

  static EdgeInsetsDirectional paddingTextStartNewChatMessage =
      EdgeInsetsDirectional.only(
    start: 32.w,
    end: 32.w,
    top: 8.h,
  );

  static EdgeInsetsDirectional paddingTopExpandableTitleBuilder =
      EdgeInsetsDirectional.only(
    top: 8.h,
  );

  static EdgeInsetsDirectional paddingHorizontalExpandableTitleBuilder =
      EdgeInsetsDirectional.symmetric(
    horizontal: 16.w,
  );

  static EdgeInsetsDirectional paddingIconExpand =
      EdgeInsetsDirectional.all(8.w);
}
