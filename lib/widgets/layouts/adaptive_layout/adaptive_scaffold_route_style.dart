import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class AdaptiveScaffoldRouteStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static EdgeInsetsDirectional secondaryBodyWidgetPadding(
    bool isWebAndDesktop,
  ) {
    return isWebAndDesktop
        ? const EdgeInsetsDirectional.all(16)
        : EdgeInsetsDirectional.zero;
  }

  static EdgeInsetsDirectional bodyWidgetPadding(
    BuildContext context,
    bool isWebAndDesktop,
  ) {
    return isWebAndDesktop
        ? EdgeInsetsDirectional.only(
            bottom: 16,
            top: 16,
            start: responsiveUtils.isTablet(context) ? 16 : 0,
          )
        : EdgeInsetsDirectional.zero;
  }

  static BorderRadiusGeometry secondaryBodyBorder(
    bool isWebAndDesktop,
  ) {
    if (isWebAndDesktop) {
      return const BorderRadius.all(Radius.circular(16.0));
    } else {
      return BorderRadius.zero;
    }
  }
}
