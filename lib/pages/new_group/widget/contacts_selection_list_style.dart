import 'package:flutter/widgets.dart';

class ContactsSelectionListStyle {
  static const notFoundPadding = EdgeInsetsDirectional.only(
    top: 12.0,
    start: 16.0,
    end: 16.0,
  );
  static const listPaddingTop = 8.0;
  static BorderRadius contactItemBorderRadius = BorderRadius.circular(16.0);

  static const contactItemPadding = EdgeInsets.symmetric(horizontal: 16.0);

  static EdgeInsets checkBoxPadding(double paddingTop) {
    return EdgeInsets.only(
      left: 8.0,
      right: 16,
      top: paddingTop,
    );
  }
}
