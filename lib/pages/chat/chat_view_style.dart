import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class ChatViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double get paddingVerticalActionButtons => 8.0;

  static double toolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 56 : 80;

  static EdgeInsetsDirectional paddingLeading(BuildContext context) =>
      EdgeInsetsDirectional.only(
        start: responsive.isMobile(context) ? 0 : 16,
      );
}
