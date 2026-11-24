import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class AdaptiveScaffoldRouteStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static EdgeInsetsDirectional secondaryBodyWidgetPadding(
    BuildContext context,
    bool isDesktopLayout,
  ) {
    return isDesktopLayout && responsiveUtils.isDesktopPlatformWide(context)
        ? const EdgeInsetsDirectional.only(top: 8)
        : EdgeInsetsDirectional.zero;
  }

  static EdgeInsetsDirectional bodyWidgetPadding(
    BuildContext context,
    bool isDesktopLayout,
  ) {
    return isDesktopLayout && responsiveUtils.isDesktopPlatformWide(context)
        ? const EdgeInsetsDirectional.only(top: 8)
        : EdgeInsetsDirectional.zero;
  }

  static BorderRadiusGeometry secondaryBodyBorder(bool isDesktopLayout) {
    if (isDesktopLayout) {
      return const BorderRadius.all(Radius.circular(16.0));
    } else {
      return BorderRadius.zero;
    }
  }
}
