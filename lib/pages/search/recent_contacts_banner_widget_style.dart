import 'package:flutter/cupertino.dart';

class RecentContactsBannerWidgetStyle {
  static double get chatRecentContactItemWidth => 72.0;
  static double get avatarWidthSize => 48.0;

  static EdgeInsetsGeometry get chatRecentContactItemPadding =>
      const EdgeInsets.only(top: 8, right: 4, left: 4);
  static EdgeInsetsDirectional get chatRecentContactListPadding =>
      const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 12);
}
