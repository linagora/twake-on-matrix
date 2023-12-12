import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class PinnedMessagesStyle {
  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  static EdgeInsets paddingListMessages(BuildContext context) =>
      EdgeInsets.symmetric(
        vertical: responsiveUtils.isMobile(context) ? 4.0 : 16.0,
      );

  static const SizedBox paddingIconAndUnpin = SizedBox(width: 4.0);

  static const double unpinButtonHeight = 72;

  static const double paddingAllContextMenuItem = 12;

  static const double heightContextMenuItem = 48;
}
