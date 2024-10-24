import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatLoadingViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static EdgeInsets padding(BuildContext context) => EdgeInsets.symmetric(
        vertical: 8,
        horizontal: responsive.isMobile(context) ? 8 : 16,
      );
}
