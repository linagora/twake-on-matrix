import 'package:flutter/material.dart';

class TwakeFabStyle {
  static const double defaultSize = 28;
  static const Color defaultPrimaryColor = Color(0xFF99A2AD);

  static const double notificationBubbleWidth = 25;
  static const double notificationBubbleHeight = 20;
  static const Color notificationBubbleBackgroundColor = Color(0xffff3347);
  static const BorderRadiusGeometry notificationBubbleBorderRadius =
      BorderRadius.all(Radius.circular(12));
  static const Color notificationBubbleBorderColorLightTheme = Colors.white;
  static const Color notificationBubbleBorderColorDarkTheme = Color.fromARGB(239, 36, 36, 36);
  static BoxBorder notificationBubbleBorder(BuildContext context) {
    return Border.all(
      color: Theme.of(context).brightness == Brightness.light
          ? notificationBubbleBorderColorLightTheme
          : notificationBubbleBorderColorDarkTheme,
      width: 1,
    );
  }

  static const TextStyle notificationBubbleTextStyle = TextStyle(
    fontFamily: 'Inter',
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static TextStyle buttonTextStyle(BuildContext context, bool isSelected) {
    return TextStyle(
      fontFamily: 'Inter',
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : TwakeFabStyle.defaultPrimaryColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    );
  }
}
