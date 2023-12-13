import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecentContactsBannerWidgetStyle {
  static double get chatRecentContactItemWidth => 72.0.w;
  static double get avatarWidthSize => 48.0.w;

  static EdgeInsetsGeometry get chatRecentContactItemPadding =>
      EdgeInsets.only(top: 8.0.h, right: 4.0.w, left: 4.0.w);
  static EdgeInsetsDirectional get chatRecentContactHorizontalPadding =>
      EdgeInsetsDirectional.symmetric(horizontal: 8.0.w);
}
