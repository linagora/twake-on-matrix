import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForwardViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double preferredAppBarSize(BuildContext context) =>
      (responsive.isMobile(context) ? 64 : 80).h;

  static double paddingBody = 8.0.w;

  static double bottomBarHeight = 60.0.h;

  static double iconSendSize = 56.0.w;
}
