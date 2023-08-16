import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class TwakeHeaderStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();
  static double get toolbarHeight => 56.0;
  static double get leadingWidth => 76.0;
  static double get titleHeight => 36.0;
  static const moreIconSize = 24.0;

  static bool isDesktop(BuildContext context) => responsive.isDesktop(context);
}
