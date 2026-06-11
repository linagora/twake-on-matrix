import 'package:fluffychat/presentation/widget_keys/widget_keys.dart';
import 'package:flutter/material.dart';

class AdaptiveScaffoldAppBarStyle {
  static ValueKey<String> get adaptiveAppBarKey =>
      NavigationKeys.adaptiveAppBar.valueKey;

  static const EdgeInsetsDirectional appBarPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 30);

  static const double sizeWidthIcTwakeImageLogo = 197.0;
  static const double sizeHeightIcTwakeImageLogo = 33.0;
  static const double toolbarHeight = 64.0;
}
