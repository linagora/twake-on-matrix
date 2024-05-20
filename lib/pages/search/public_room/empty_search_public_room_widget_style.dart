import 'package:flutter/material.dart';

class EmptySearchPublicRoomWidgetStyle {
  static const double avatarSize = 56.0;

  static const BorderRadiusGeometry avatarBorderRadius =
      BorderRadius.all(Radius.circular(28.0));
  static BoxBorder avatarBorder(BuildContext context) {
    return Border.all(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0x222c2d2f)
          : const Color(0x222c2d2f),
      width: 1,
    );
  }

  static Color avatarBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0x222c2d2f)
        : Colors.transparent;
  }

  static TextStyle avatarLetterTextStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black,
      fontSize: 24,
    );
  }
}
