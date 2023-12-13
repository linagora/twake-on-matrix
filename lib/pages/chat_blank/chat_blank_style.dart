import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatBlankStyle {
  static double minWidth = 200.w;
  static double width(BuildContext context) =>
      (min<double>(MediaQuery.of(context).size.width, ChatBlankStyle.minWidth) /
              2)
          .w;
  static EdgeInsets elementsPadding =
      EdgeInsets.only(top: 32.0.h, bottom: 12.0.h);
  static double textFontSize = 17.0.sp;
  static FontWeight textFontWeight = FontWeight.w500;
  static double iconSize = 20.0.w;

  static TextStyle? textStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: ChatBlankStyle.textFontSize,
            fontWeight: ChatBlankStyle.textFontWeight,
            color: LinagoraRefColors.material().tertiary[20],
          );
}
