import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatListViewStyle {
  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double editIconSize = 18.0;

  static Size preferredSizeAppBar(BuildContext context) =>
      const Size.fromHeight(120);

  // Slidable Ratio of one slidable item
  static const double slidableSizeRatio = 0.23;
  static double slidableExtentRatio(int slidablesLength) {
    return slidableSizeRatio * slidablesLength;
  }

  static const EdgeInsets slidablePadding = EdgeInsets.all(4.0);
  static const double slidableIconTextGap = 4.0;

  static const double slidableIconSize = 24.0;
  static Color? pinSlidableColor(bool isFavourite) {
    return isFavourite
        ? LinagoraRefColors.material().neutral[70]
        : Colors.greenAccent[700];
  }

  static Color? readSlidableColor(bool isUnread) {
    return isUnread
        ? LinagoraRefColors.material().neutral[70]
        : LinagoraRefColors.material().primary[40];
  }

  static Color? muteSlidableColor(bool isMuted) {
    return isMuted
        ? LinagoraRefColors.material().primary[20]
        : Colors.amber[700];
  }
}
