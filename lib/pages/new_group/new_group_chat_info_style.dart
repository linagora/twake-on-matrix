import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class NewGroupChatInfoStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double toolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 104 : 56;

  static EdgeInsetsDirectional paddingTitle(BuildContext context) =>
      EdgeInsetsDirectional.only(
        top: responsive.isMobile(context) ? 40 : 0,
      );
}
