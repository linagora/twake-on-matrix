import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class InvitationSelectionViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double toolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 96 : 56;

  static EdgeInsetsDirectional paddingTitle(BuildContext context) =>
      responsive.isMobile(context)
          ? const EdgeInsetsDirectional.only(top: 40)
          : EdgeInsetsDirectional.zero;
}
