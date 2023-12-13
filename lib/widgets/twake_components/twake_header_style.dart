import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TwakeHeaderStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();
  static const double toolbarHeight = 56.0;
  static double leadingWidth = 76.0.w;
  static double titleHeight = 36.0.h;
  static double closeIconSize = 24.0.r;
  static double widthSizedBox = 16.0.w;
  static double textBorderRadius = 24.0.r;
  static const int flexTitle = 6;
  static const int flexActions = 3;

  static bool isDesktop(BuildContext context) => responsive.isDesktop(context);

  static AlignmentGeometry alignment(BuildContext context) {
    return isDesktop(context)
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.center;
  }

  static EdgeInsetsDirectional actionsPadding = EdgeInsetsDirectional.only(
    end: 16.w,
  );

  static EdgeInsetsDirectional leadingPadding = EdgeInsetsDirectional.only(
    start: 26.h,
  );

  static EdgeInsetsDirectional textButtonPadding =
      EdgeInsetsDirectional.all(8.w);

  static EdgeInsetsDirectional counterSelectionPadding =
      EdgeInsetsDirectional.only(start: 4.w);
}
