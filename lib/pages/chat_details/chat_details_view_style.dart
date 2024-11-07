import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatDetailViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();
  static const double fixedWidth = 360.0;

  // Navigation App Bar
  static const EdgeInsetsGeometry backIconPadding =
      EdgeInsets.symmetric(vertical: 8, horizontal: 4);
  static double toolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 56 : 80;
  static const EdgeInsets navigationAppBarPadding =
      EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0);

  // Informations Content
  static const double minToolbarHeightSliverAppBar = 300.0;
  static const double mediumToolbarHeightSliverAppBar = 344.0;
  static const double maxToolbarHeightSliverAppBar = 394.0;
  static const double groupToolbarHeightSliverAppBar = 360.0;
  static const double avatarSize = 96;
  static double chatDetailsPageViewWebBorderRadius = 16.0;
  static double chatDetailsPageViewWebWidth = 640.0;
  static EdgeInsetsDirectional paddingTabBarView =
      const EdgeInsetsDirectional.only(
    top: 50,
  );
  static const double avatarFontSize = 36;
  static const EdgeInsets groupDescriptionContainerPadding =
      EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0);
  static const double switchButtonHeight = 24.0;
  static const double switchButtonWidth = 38.0;

  static const EdgeInsetsGeometry mainPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 10);

  static const EdgeInsetsGeometry chatInformationPadding = EdgeInsets.symmetric(
    horizontal: 20,
  );

  static BorderRadius borderRadiusButton = const BorderRadius.all(
    Radius.circular(28.0),
  );

  static double addMemberMaxWidth = 156;
}
