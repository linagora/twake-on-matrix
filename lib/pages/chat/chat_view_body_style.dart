import 'package:fluffychat/config/themes.dart';
import 'package:flutter/material.dart';

class ChatViewBodyStyle {
  static double bottomSheetPadding(BuildContext context) =>
      TwakeThemes.isColumnMode(context) ? 16.0 : 8.0;

  static double inputMessageWidgetMaxWidth = 800.0;

  static double dividerSize = 1.0;
}
