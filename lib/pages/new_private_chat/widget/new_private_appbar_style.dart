import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class NewPrivateAppBarStyle {
  static double appbarHeight(BuildContext context) =>
      ResponsiveUtils().isMobile(context) ? 104 : 64;

  static EdgeInsetsDirectional paddingItemAppbar(BuildContext context) =>
      EdgeInsetsDirectional.only(
        top: ResponsiveUtils().isMobile(context) ? 30 : 0,
      );
}
