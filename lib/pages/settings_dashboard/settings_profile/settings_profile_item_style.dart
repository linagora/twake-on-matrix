import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class SettingsProfileItemStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double iconSize = 24.0;
  static const double dividerSize = 2.0;

  static const EdgeInsetsDirectional itemBuilderPadding =
      EdgeInsetsDirectional.only(end: 8.0);

  static const EdgeInsetsDirectional snackBarPadding =
      EdgeInsetsDirectional.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  static double? widthSnackBar(BuildContext context) {
    if (responsiveUtils.isWebDesktop(context)) {
      return 334;
    } else {
      return null;
    }
  }
}
