import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class ContactsAppbarStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static EdgeInsetsDirectional paddingTitle(BuildContext context) =>
      EdgeInsetsDirectional.only(
        start: 16.0,
        top: responsive.isMobile(context) ? 56 : 8,
      );
}
