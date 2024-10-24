import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/widgets.dart';

class ContactsSelectionViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static EdgeInsetsDirectional webActionsButtonMargin =
      const EdgeInsetsDirectional.symmetric(
    horizontal: 24.0,
  );

  static EdgeInsets parentPadding =
      const EdgeInsets.symmetric(horizontal: 16.0);

  static Size preferredSize(BuildContext context) => Size.fromHeight(
        AppConfig.toolbarHeight(context),
      );

  static Size maxPreferredSize(BuildContext context) => Size.fromHeight(
        maxToolbarHeight(context),
      );

  static EdgeInsetsDirectional webActionsButtonPadding =
      const EdgeInsetsDirectional.only(
    top: 24,
    bottom: 16,
    start: 16,
    end: 16,
  );

  static const double webActionsButtonPaddingAll = 10.0;

  static const double webActionsButtonBorder = 100.0;

  static double maxToolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 48 : 136;
}
