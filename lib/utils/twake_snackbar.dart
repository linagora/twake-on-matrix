import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

const Duration _snackBarDefaultDisplayDuration = Duration(milliseconds: 4000);

class TwakeSnackBarStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const EdgeInsetsDirectional snackBarPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 14);

  static double? widthSnackBar(BuildContext context) {
    if (responsiveUtils.isWebDesktop(context)) {
      return 334;
    } else {
      return null;
    }
  }
}

class TwakeSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = _snackBarDefaultDisplayDuration,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: TwakeSnackBarStyle.widthSnackBar(context),
        padding: TwakeSnackBarStyle.snackBarPadding,
        duration: duration,
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  // TODO: change to colorSurface when its approved
                  // ignore: deprecated_member_use
                  color: Theme.of(context).colorScheme.background,
                ),
              ),
            ),
            InkWell(
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Icon(
                Icons.close,
                color: LinagoraSysColors.material().onInverseSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
