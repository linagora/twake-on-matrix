import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class SearchableAppBarStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static Size preferredSize(BuildContext context) => Size.fromHeight(
        AppConfig.toolbarHeight(context),
      );

  static Size maxPreferredSize(BuildContext context) => Size.fromHeight(
        maxToolbarHeight(context),
      );

  static double maxToolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 48 : 112;

  static EdgeInsetsDirectional textFieldWebPadding =
      const EdgeInsetsDirectional.only(
    start: 16,
    end: 16,
    bottom: 8,
    top: 8,
  );

  static const paddingTitleFullScreen = SizedBox(height: 16.0);

  static EdgeInsetsDirectional textFieldContentPadding =
      const EdgeInsetsDirectional.only(top: 10);

  static const int textFieldMaxLength = 200;

  static const int textFieldMaxLines = 1;

  static const double appBarBorderRadius = 16.0;

  static const double closeButtonPaddingAll = 10.0;

  static const EdgeInsets closeButtonMargin = EdgeInsets.symmetric(
    vertical: 10.0,
    horizontal: 6.0,
  );

  static const double closeButtonPlaceholderWidth = 44.0;
}
