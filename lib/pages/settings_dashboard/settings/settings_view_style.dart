import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsViewStyle {
  static double iconSize = 24.0.w;

  static double fontSizeAvatar = 9.0.sp * 2.5;

  static EdgeInsetsDirectional itemBuilderPadding =
      EdgeInsetsDirectional.all(16.0.w);

  static EdgeInsetsDirectional leadingItemBuilderPadding =
      EdgeInsetsDirectional.only(end: 8.0.w);

  static EdgeInsetsDirectional subtitleItemBuilderPadding =
      EdgeInsetsDirectional.only(top: 4.0.h);

  static EdgeInsetsDirectional bodySettingsScreenPadding =
      EdgeInsetsDirectional.symmetric(
    horizontal: 8.0.w,
  );

  static EdgeInsetsDirectional avatarPadding =
      EdgeInsetsDirectional.only(end: 8.0.w);
}
