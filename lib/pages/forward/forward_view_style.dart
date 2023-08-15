import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';

class ForwardViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double preferredAppBarSize(BuildContext context) =>
      responsive.isMobile(context) ? 104 : 64;

  static double get paddingBody => 16.0;

  static double get bottomBarHeight => 120.0;

  static double get iconSendSize => 40.0;

  static EdgeInsetsDirectional paddingItemAppbar(BuildContext context) =>
      EdgeInsetsDirectional.only(
        top: responsive.isMobile(context) ? 40 : 0,
      );
}
