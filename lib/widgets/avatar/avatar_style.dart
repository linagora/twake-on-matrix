import 'package:flutter/material.dart';

class AvatarStyle {
  static const double defaultSize = 56.0;
  static const double defaultFontSize = 24.0;
  static const defaultBorderRadius = BorderRadius.all(Radius.circular(28.0));

  static Color? defaultTextColor(bool noPic) {
    return noPic ? Colors.white : null;
  }

  static const String fontFamily = 'SFProRounded';
  static const FontWeight fontWeight = FontWeight.w700;

  static BorderRadius borderRadius(double? size) {
    return BorderRadius.circular((size ?? 56) / 2);
  }

  static BoxBorder defaultBorder = Border.all(color: Colors.transparent);
}
