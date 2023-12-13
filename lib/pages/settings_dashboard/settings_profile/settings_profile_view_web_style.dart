import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsProfileViewWebStyle {
  static double bodyWidth = 640.0.w;
  static double widthSize = 116.0.w;
  static double avatarSize = 96.0.w;
  static double avatarFontSize = (18.0 * 2.5).sp;
  static double positionedBottomSize = 0;
  static double positionedRightSize = 0;
  static double iconEditBorderWidth = 4.0.w;
  static double iconEditSize = 24.0.w;
  static double radiusCircular = 16.0.r;
  static double radiusImageMemory = 48.0.r;

  static EdgeInsetsDirectional paddingBody = EdgeInsetsDirectional.all(32.0.w);

  static EdgeInsetsDirectional paddingWidgetBasicInfo =
      EdgeInsetsDirectional.all(16.0.w);

  static EdgeInsetsDirectional paddingBasicInfoTitle =
      EdgeInsetsDirectional.only(bottom: 3.0.h);

  static EdgeInsetsDirectional paddingEditIcon =
      EdgeInsetsDirectional.all(8.0.w);

  static EdgeInsetsDirectional paddingWidgetEditProfileInfo =
      EdgeInsetsDirectional.symmetric(vertical: 16.0.h);

  static EdgeInsetsDirectional paddingWorkIdentitiesInfoWidget =
      EdgeInsetsDirectional.only(bottom: 16.0.h);
}
