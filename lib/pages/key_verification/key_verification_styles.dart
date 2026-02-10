import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class KeyVerificationStyles {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double borderHoverButtonWaningBanner = 100.0;

  static EdgeInsetsDirectional marginButtonWarningBanner =
      const EdgeInsetsDirectional.symmetric(horizontal: 24.0);

  static const double maxWidthMatchButtonMobile = 158;

  static const double maxWidthMatchButtonWeb = 168;

  static double maxWidthMatchButton(BuildContext context) {
    return responsiveUtils.isMobile(context)
        ? maxWidthMatchButtonMobile
        : maxWidthMatchButtonWeb;
  }
}
