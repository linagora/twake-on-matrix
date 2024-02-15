import 'dart:math';

import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatBlankStyle {
  static const double minWidth = 200;
  static double width(BuildContext context) =>
      min<double>(MediaQuery.sizeOf(context).width, ChatBlankStyle.minWidth) /
      2;
  static const EdgeInsets elementsPadding =
      EdgeInsets.only(top: 32.0, bottom: 12.0);
  static const double textFontSize = 17.0;
  static const FontWeight textFontWeight = FontWeight.w500;
  static const double iconSize = 20.0;

  static TextStyle? textStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: ChatBlankStyle.textFontSize,
            fontWeight: ChatBlankStyle.textFontWeight,
            color: LinagoraRefColors.material().tertiary[20],
          );
}
