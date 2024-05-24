import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatDetailsMediaStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static const durationPadding = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 2,
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
        // TODO: change to colorSurface when its approved
        // ignore: deprecated_member_use
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
        shape: const StadiumBorder(),
      );

  static TextStyle? durationTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          );

  static double durationPaddingAll(BuildContext context) =>
      responsive.isDesktop(context) ? 4 : 10;
}
