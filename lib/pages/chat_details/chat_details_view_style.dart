import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class ChatDetailViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double toolbarHeight = 56;

  static double actionsHeaderWidth(BuildContext context) =>
      responsive.isMobile(context) || responsive.isTablet(context) ? 98 : 148;

  static double chatDetailsPageViewWebBorderRadius = 16.0;

  static double chatDetailsPageViewWebWidth = 640.0;

  static EdgeInsetsDirectional groupAvatarPadding =
      const EdgeInsetsDirectional.symmetric(vertical: 16.0);

  static EdgeInsetsDirectional groupNameAndInfoPadding =
      const EdgeInsetsDirectional.symmetric(horizontal: 16.0);

  static double groupAvatarSize = 96.0;

  static double groupAvatarBorderRadius = 48;
}
