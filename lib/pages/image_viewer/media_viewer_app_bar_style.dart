import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class MediaViewewAppbarStyle {
  static const opacityAnimationDuration = Duration(milliseconds: 200);

  static final appBarBackgroundColor =
      LinagoraSysColors.material().onTertiaryContainer.withOpacity(0.5);

  static EdgeInsets paddingRightMenu = const EdgeInsets.only(right: 8.0);

  static BorderRadius showMoreIconSplashRadius = BorderRadius.circular(100);

  static EdgeInsets marginAllShowMoreIcon = const EdgeInsets.all(8.0);

  static double paddingAllShowMoreIcon = 0.0;
}
