import 'package:fluffychat/config/themes.dart';
import 'package:flutter/material.dart';

class ChatViewBodyStyle {
  static double bottomSheetPadding(BuildContext context) =>
      TwakeThemes.isColumnMode(context) ? 16.0 : 8.0;

  static double chatScreenMaxWidth = 800.0;

  static double dividerSize = 1.0;

  static const EdgeInsets inputBarPadding = EdgeInsets.only(
    left: 8.0,
    right: 16.0,
  );
}
