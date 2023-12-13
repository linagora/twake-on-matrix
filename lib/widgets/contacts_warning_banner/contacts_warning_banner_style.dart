import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContactsWarningBannerStyle {
  static double warningBannerBorder = 16.0.r;
  static double hoverButtonWaningBannerBorder = 100.0.r;

  static EdgeInsets warningBannerMargin = EdgeInsets.symmetric(
    horizontal: 16.0.w,
    vertical: 8.0.h,
  );

  static EdgeInsets warningBannerPadding = EdgeInsets.all(16.0.w);

  static EdgeInsets paddingForContentBanner = EdgeInsets.only(bottom: 16.0.h);

  static EdgeInsetsDirectional buttonWarningBannerMargin =
      EdgeInsetsDirectional.symmetric(
    vertical: 10.0.h,
    horizontal: 24.0.w,
  );

  static EdgeInsets rightButtonPadding = EdgeInsets.only(
    right: 10.0.w,
  );
}
