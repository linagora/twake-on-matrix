import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class TwakeTextButtonStyle {
  static final ResponsiveUtils _responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double maxWidthDialogButtonMobile = 112;

  static const double maxWidthDialogButtonWeb = 128;

  static double getBoxConstraintMaxWidth(BuildContext context) {
    return _responsiveUtils.isMobile(context)
        ? maxWidthDialogButtonMobile
        : maxWidthDialogButtonWeb;
  }
}
