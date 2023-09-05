import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class SearchableAppBarStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static Size preferredSize(
    BuildContext context, {
    bool? isFullScreen = true,
  }) =>
      Size.fromHeight(
        appBarHeight(
          context,
          isFullScreen: isFullScreen,
        ),
      );

  static double appBarHeight(
    BuildContext context, {
    bool? isFullScreen = true,
  }) =>
      isFullScreen == true ? 56 : 112;

  static EdgeInsetsDirectional textFieldWebPadding =
      const EdgeInsetsDirectional.only(
    start: 16,
    end: 16,
    bottom: 8,
  );

  static EdgeInsetsDirectional textFieldContentPadding =
      const EdgeInsetsDirectional.only(top: 10);

  static const int textFieldMaxLength = 200;

  static const int textFieldMaxLines = 1;

  static const double appBarBorderRadius = 16.0;
}
