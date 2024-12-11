import 'package:flutter/material.dart';

class MediaPickerStyle {
  static const AssetImage cameraIcon = AssetImage("assets/verification.png");

  static const initialChildSize = 0.5;

  static const EdgeInsets gridPadding = EdgeInsets.only(bottom: 150);

  static const EdgeInsets textSelectedCounterPadding = EdgeInsets.only(
    left: 8.0,
    right: 8.0,
    bottom: 12.0,
    top: 16.0,
  );

  static const EdgeInsets itemPickerPadding = EdgeInsets.only(
    top: 8.0,
    bottom: 17.0,
    right: 65,
    left: 65,
  );

  static const EdgeInsets composerPadding = EdgeInsets.only(
    right: 20.0,
    top: 8.0,
    bottom: 8.0,
    left: 4.0,
  );

  static const EdgeInsets sendButtonPadding = EdgeInsets.only(top: 4, left: 12);

  static const BorderRadius sendButtonBorderRadius =
      BorderRadius.all(Radius.circular(100));

  static const double sendButtonSize = 48.0;

  static const double sendIconSize = 40.0;

  static const double counterIconSize = 24.0;

  static const EdgeInsets counterPadding = EdgeInsets.all(1.0);

  static const double borderSideWidth = 1.5;

  static const double minFontSize = 8;

  static double photoPermissionIconSize = 48.0;

  static double photoPermissionFontSize = 16;

  static FontWeight photoPermissionFontWeight = FontWeight.w600;

  static const double expandedWidgetHeight = 50;
}
