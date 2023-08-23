import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class ContactsAppbarStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static Size preferredSizeAppBar(BuildContext context) => Size.fromHeight(
        responsive.isMobile(context) ? 96 : 56,
      );

  static EdgeInsetsDirectional paddingTitle(BuildContext context) =>
      const EdgeInsetsDirectional.symmetric(horizontal: 16.0);
}
