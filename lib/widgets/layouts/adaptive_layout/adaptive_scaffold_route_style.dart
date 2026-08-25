import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class AdaptiveScaffoldRouteStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static EdgeInsetsDirectional secondaryBodyWidgetPadding(
    BuildContext context,
    bool isWebAndDesktop,
  ) {
    return isWebAndDesktop && responsiveUtils.isWebDesktop(context)
        ? const EdgeInsetsDirectional.only(top: 8)
        : EdgeInsetsDirectional.zero;
  }

  static EdgeInsetsDirectional bodyWidgetPadding(
    BuildContext context,
    bool isWebAndDesktop,
  ) {
    return isWebAndDesktop && responsiveUtils.isWebDesktop(context)
        ? const EdgeInsetsDirectional.only(top: 8)
        : EdgeInsetsDirectional.zero;
  }

  static BorderRadiusGeometry secondaryBodyBorder(bool isWebAndDesktop) {
    if (isWebAndDesktop) {
      return const BorderRadius.all(Radius.circular(16.0));
    } else {
      return BorderRadius.zero;
    }
  }
}
