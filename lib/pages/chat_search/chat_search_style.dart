import 'package:flutter/material.dart';

class ChatSearchStyle {
  static const EdgeInsetsGeometry inputPadding =
      EdgeInsetsDirectional.only(start: 8, top: 16, bottom: 16, end: 16);

  static const EdgeInsetsGeometry itemMargin =
      EdgeInsetsDirectional.symmetric(horizontal: 8);

  static const EdgeInsetsGeometry itemPadding =
      EdgeInsetsDirectional.only(end: 8, top: 8);

  static const EdgeInsetsGeometry avatarPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 8);

  static const EdgeInsetsGeometry emptyPadding = EdgeInsetsDirectional.all(16);

  static const double emptyGap = 128.0;

  static const double itemHeight = 80.0;

  static const double itemBorderRadius = 12.0;
}
