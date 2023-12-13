import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NewGroupChatInfoStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static int thumbnailSizeWidth = 56.0.w.toInt();
  static int thumbnailSizeHeight = 56.0.h.toInt();
  static double avatarRadiusForWeb = 48.0.w;
  static double avatarRadiusForMobile = 28.0.w;
  static double backIconPaddingAll = 8.0.w;

  static double profileSize(BuildContext context) =>
      (responsive.isMobile(context) ? 56.0 : 96.0).h;

  static EdgeInsetsDirectional groupNameTextFieldPadding =
      EdgeInsetsDirectional.only(
    start: 8.0.w,
    end: 8.0.w,
  );

  static EdgeInsets backIconMargin = EdgeInsets.symmetric(
    vertical: 12.0.h,
    horizontal: 8.0.w,
  );

  static EdgeInsetsDirectional padding =
      EdgeInsetsDirectional.symmetric(horizontal: 8.0.w);

  static EdgeInsetsDirectional contentPadding =
      EdgeInsetsDirectional.all(16.0.w);

  static EdgeInsetsDirectional profilePadding =
      EdgeInsetsDirectional.only(top: 16.0.h);

  static EdgeInsetsDirectional screenPadding =
      EdgeInsetsDirectional.only(start: 8.0.w, bottom: 8.0.h, end: 4.0.w);

  static EdgeInsetsDirectional topScreenPadding =
      EdgeInsetsDirectional.only(top: 8.0.h);
}
