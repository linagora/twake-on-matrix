import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class ForwardViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double preferredAppBarSize(BuildContext context) =>
      responsive.isMobile(context) ? 64 : 80;

  static const double paddingBody = 8.0;

  static const double bottomBarHeight = 60.0;

  static const double iconSendSize = 56.0;
}
