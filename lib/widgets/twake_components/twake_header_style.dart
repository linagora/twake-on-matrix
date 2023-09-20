import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class TwakeHeaderStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();
  static const double toolbarHeight = 56.0;
  static const double leadingWidth = 76.0;
  static const double titleHeight = 36.0;
  static const double closeIconSize = 24.0;
  static const double widthSizedBox = 16.0;
  static const double textBorderRadius = 24.0;

  static bool isDesktop(BuildContext context) => responsive.isDesktop(context);

  static AlignmentGeometry alignment(BuildContext context) {
    return isDesktop(context)
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.center;
  }

  static const EdgeInsetsDirectional padding = EdgeInsetsDirectional.only(
    end: 16,
    start: 16,
  );

  static const EdgeInsetsDirectional textButtonPadding =
      EdgeInsetsDirectional.all(8);

  static const EdgeInsetsDirectional closeIconPadding =
      EdgeInsetsDirectional.only(end: 4);
}
