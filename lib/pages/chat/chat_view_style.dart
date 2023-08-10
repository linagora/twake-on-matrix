import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class ChatViewStyle {
  static double get paddingVerticalActionButtons => 8.0;

  static double toolbarHeight(BuildContext context) =>
      ResponsiveUtils().isMobile(context) ? 104 : 86;

  static EdgeInsetsDirectional paddingLeading(BuildContext context) =>
      EdgeInsetsDirectional.only(
        top: ResponsiveUtils().isMobile(context) ? 30 : 0,
      );
}
