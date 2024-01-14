import 'package:fluffychat/config/app_config.dart';
import 'package:flutter/widgets.dart';

class ContactsSelectionViewStyle {
  static EdgeInsetsDirectional webActionsButtonMargin =
      const EdgeInsetsDirectional.symmetric(
    vertical: 10.0,
    horizontal: 24.0,
  );

  static EdgeInsets parentPadding =
      const EdgeInsets.symmetric(horizontal: 12.0);

  static Size preferredSize(BuildContext context) => Size.fromHeight(
        AppConfig.toolbarHeight(context),
      );

  static EdgeInsetsDirectional webActionsButtonPadding =
      const EdgeInsetsDirectional.symmetric(
    horizontal: 16.0,
  );

  static const double webActionsButtonHeight = 72.0;

  static const double webActionsButtonPaddingAll = 10.0;

  static const double webActionsButtonBorder = 100.0;
}
