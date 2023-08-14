import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ContactsTabViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static Size preferredSizeAppBar(BuildContext context) => Size.fromHeight(
        responsive.isMobile(context) ? 120 : 96,
      );
}
