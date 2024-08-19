import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatSearchStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double toolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 64 : 72;

  static const EdgeInsetsGeometry inputPadding =
      EdgeInsetsDirectional.only(start: 8, top: 16, bottom: 16, end: 16);

  static const EdgeInsetsGeometry itemMargin =
      EdgeInsetsDirectional.symmetric(horizontal: 16);

  static const EdgeInsetsGeometry itemPadding =
      EdgeInsetsDirectional.only(end: 8);

  static const EdgeInsetsGeometry avatarPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 16);

  static const EdgeInsetsGeometry searchAppBarPadding =
      EdgeInsetsDirectional.only(top: 16.0);

  static const EdgeInsetsGeometry emptyPadding = EdgeInsetsDirectional.all(16);

  static const double emptyGap = 128.0;

  static const double itemHeight = 90.0;

  static const double itemBorderRadius = 12.0;
}
