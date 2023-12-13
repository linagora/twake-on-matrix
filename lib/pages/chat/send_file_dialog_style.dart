import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SendFileDialogStyle {
  static double dialogBorderRadius = 16.0.r;

  static double dialogWidth = 328.0.w;

  static double imageBorderRadius = 8.0.r;

  static double imageSize = 328.0.w;

  static double buttonBorderRadius = 100.0.r;

  static EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0.w,
    vertical: 10.0.h,
  );

  static EdgeInsets headerPadding = EdgeInsets.all(4.0.w);

  static InputDecoration bottomBarInputDecoration(BuildContext context) =>
      InputDecoration(
        hintText: L10n.of(context)!.enterCaption,
        hintMaxLines: 1,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.merge(
              Theme.of(context).inputDecorationTheme.hintStyle,
            )
            .copyWith(letterSpacing: -0.15),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
      );

  static Widget spaceBwInputBarAndButton = SizedBox(height: 8.0.h);
}
