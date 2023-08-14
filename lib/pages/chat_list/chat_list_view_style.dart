import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class ChatListViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static Size preferredSizeAppBar(BuildContext context) => Size.fromHeight(
        responsive.isMobile(context) ? 160 : 120,
      );
}
