import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatDetailsMediaStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static EdgeInsets durationPadding = EdgeInsets.symmetric(
    horizontal: 4.0.w,
    vertical: 2.0.h,
  );

  static int crossAxisCount(BuildContext context) {
    if (responsive.isWebDesktop(context)) {
      return 5;
    } else {
      return 3;
    }
  }

  static Decoration durationBoxDecoration(BuildContext context) =>
      ShapeDecoration(
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
        shape: const StadiumBorder(),
      );

  static TextStyle? durationTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          );

  static const double durationPosition = 10;
}
