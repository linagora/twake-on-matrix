import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class SearchableAppBarStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static Size preferredSize(BuildContext context) =>
      Size.fromHeight(appBarHeight(context));

  static double appBarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 104 : 56;

  static EdgeInsetsDirectional paddingItemAppBar(BuildContext context) =>
      EdgeInsetsDirectional.only(
        top: responsive.isMobile(context) ? 40 : 0,
      );
}
