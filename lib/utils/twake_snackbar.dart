import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class TwakeSnackBarStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

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

class TwakeSnackBar {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: TwakeSnackBarStyle.widthSnackBar(context),
        padding: TwakeSnackBarStyle.snackBarPadding,
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.background,
              ),
        ),
      ),
    );
  }
}
