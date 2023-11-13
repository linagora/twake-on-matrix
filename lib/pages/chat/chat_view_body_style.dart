import 'package:fluffychat/config/themes.dart';
import 'package:flutter/material.dart';

class ChatViewBodyStyle {
  static double bottomSheetPadding(BuildContext context) =>
      TwakeThemes.isColumnMode(context) ? 16.0 : 8.0;
}
