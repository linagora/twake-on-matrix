import 'package:flutter/widgets.dart';

class ContactsSelectionViewStyle {
  static EdgeInsetsDirectional getSelectionListPadding({
    required bool haveSelectedContact,
  }) =>
      haveSelectedContact
          ? EdgeInsetsDirectional.zero
          : const EdgeInsetsDirectional.only(top: 8.0);

  static EdgeInsetsDirectional webActionsButtonMargin =
      const EdgeInsetsDirectional.symmetric(
    vertical: 10.0,
    horizontal: 24.0,
  );

  static EdgeInsets parentPadding = const EdgeInsets.all(12.0);

  static EdgeInsetsDirectional webActionsButtonPadding =
      const EdgeInsetsDirectional.symmetric(
    horizontal: 16.0,
  );

  static const double webActionsButtonHeight = 72.0;

  static const double webActionsButtonPaddingAll = 10.0;

  static const double webActionsButtonBorder = 100.0;
}
