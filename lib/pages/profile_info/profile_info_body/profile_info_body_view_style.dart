import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ProfileInfoBodyViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static const EdgeInsetsGeometry profileInformationsTopPadding =
      EdgeInsets.only(
    top: 16.0,
    left: 16.0,
    right: 16.0,
  );

  static const double bigDividerThickness = 4;

  static const EdgeInsetsGeometry actionItemPadding = EdgeInsets.only(
    left: 16.0,
    right: 16.0,
  );

  static const EdgeInsetsGeometry actionsPadding = EdgeInsets.only(
    bottom: 16.0,
  );

  static const EdgeInsetsGeometry copiableRowPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8,
  );

  static const EdgeInsetsGeometry avatarPadding =
      EdgeInsets.symmetric(vertical: 16.0);
}
