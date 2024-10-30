import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ContactsAppbarStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();
  static const double iconSize = 24.0;

  static const double textFieldHeight = 56.0;

  static const double textFieldBorderRadius = 24.0;

  static EdgeInsetsDirectional contentPadding = EdgeInsetsDirectional.zero;
  static const EdgeInsets trailingIconPadding = EdgeInsets.only(right: 16.0);

  static EdgeInsets titlePadding(context) => EdgeInsets.only(
        left: responsiveUtils.isMobile(context) ? 0 : 16.0,
      );
  static const EdgeInsets searchFieldPadding = EdgeInsets.only(
    left: 16.0,
    right: 16.0,
    bottom: 8.0,
  );
  static const trailingIconSize = 24.0;
  static const dividerHeight = 1.0;
  static const dividerThickness = 1.0;
}
