import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class NewPrivateAppBarStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double appbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 104 : 64;

  static EdgeInsetsDirectional paddingItemAppbar(BuildContext context) =>
      EdgeInsetsDirectional.only(
        top: responsive.isMobile(context) ? 30 : 0,
      );
}
