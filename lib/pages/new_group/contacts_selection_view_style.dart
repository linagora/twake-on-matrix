import 'package:flutter/widgets.dart';

class ContactsSelectionViewStyle {
  static EdgeInsetsDirectional getSelectionListPadding({
    required bool haveSelectedContact,
  }) =>
      haveSelectedContact
          ? EdgeInsetsDirectional.zero
          : const EdgeInsetsDirectional.only(top: 8.0);
}
