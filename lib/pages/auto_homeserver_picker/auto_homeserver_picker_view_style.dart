import 'package:flutter/material.dart';

class AutoHomeserverPickerViewStyle {
  static const double logoWidth = 257;
  static const double logoHeight = 179;
  static const double buttonHeight = 56;
  static const double buttonRadius = 100;

  static const EdgeInsets descriptionPadding =
      EdgeInsets.symmetric(horizontal: 8);

  static const EdgeInsets buttonPadding = EdgeInsets.only(
    bottom: 44,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF8135FE),
      Color(0xFFE8A6FF),
    ],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const Decoration containerDecoration = BoxDecoration(
    color: Colors.white,
  );
}
