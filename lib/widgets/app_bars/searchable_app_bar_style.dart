import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchableAppBarStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static Size preferredSize(BuildContext context) => Size.fromHeight(
        AppConfig.toolbarHeight(context),
      );

  static EdgeInsetsDirectional textFieldWebPadding = EdgeInsetsDirectional.only(
    start: 16.0.w,
    end: 16.0.w,
    bottom: 8.0.h,
  );

  static EdgeInsetsDirectional textFieldContentPadding =
      EdgeInsetsDirectional.only(top: 10.0.h);

  static const int textFieldMaxLength = 200;

  static const int textFieldMaxLines = 1;

  static double appBarBorderRadius = 16.0.r;
}
