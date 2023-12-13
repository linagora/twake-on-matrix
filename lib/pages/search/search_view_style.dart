import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class SearchViewStyle {
  static double get toolbarHeightSearch => 56.0.h;
  static double get toolbarHeightOfSliverAppBar => 44.0.h;

  static EdgeInsetsGeometry get paddingRecentChatsHeaders =>
      EdgeInsets.symmetric(horizontal: 16.0.w);
  static EdgeInsetsGeometry get paddingLeadingAppBar =>
      EdgeInsetsDirectional.only(end: 8.0.w, start: 8.0.w);
  static EdgeInsetsGeometry get contentPaddingAppBar => EdgeInsets.all(12.0.w);
  static EdgeInsetsGeometry get paddingRecentChats =>
      EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 8.0.h);

  static double paddingBackButton = 8.0.w;

  static final BorderRadius borderRadiusTextField =
      BorderRadius.circular(24.0.r);

  static EdgeInsetsGeometry get appbarPadding => EdgeInsetsDirectional.only(
        bottom: 0.0.h,
        top: 0.0.h,
      );

  static TextStyle? headerTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(
            color: LinagoraRefColors.material().neutral[40],
          );
}
