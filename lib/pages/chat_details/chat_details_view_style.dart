import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatDetailViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double toolbarHeightSliverAppBar = 300.0.h;

  static double actionsHeaderWidth(BuildContext context) =>
      (responsive.isMobile(context) || responsive.isTablet(context)
              ? 98.0
              : 148.0)
          .w;

  static double chatDetailsPageViewWebBorderRadius = 16.0.r;

  static double chatDetailsPageViewWebWidth = 640.0.w;

  static EdgeInsetsDirectional groupAvatarPadding =
      EdgeInsetsDirectional.symmetric(vertical: 16.0.h);

  static EdgeInsetsDirectional groupNameAndInfoPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 16.0.w);

  static EdgeInsetsDirectional paddingTabBarView = EdgeInsetsDirectional.only(
    top: 50.0.h,
  );

  static double groupAvatarSize = 96.0.w;

  static double groupAvatarBorderRadius = 48.0.r;
}
