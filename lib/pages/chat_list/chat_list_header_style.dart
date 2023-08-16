import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class ChatListHeaderStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static const double searchRadiusBorder = 24.0;
  static const double searchBarHeight = 56.0;
  static const double searchBarContainerHeight = 64.0;

  static EdgeInsetsDirectional paddingChatListHeader(BuildContext context) =>
      responsive.isMobile(context)
          ? const EdgeInsetsDirectional.only(top: 40)
          : EdgeInsetsDirectional.zero;
}
