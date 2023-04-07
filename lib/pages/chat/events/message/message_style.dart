import 'package:fluffychat/config/app_config.dart';
import 'package:flutter/material.dart';

class MessageStyle {
  static final bubbleBorderRadius = BorderRadius.circular(18);
  static final errorStatusPlaceHolderWidth = 16 * AppConfig.bubbleSizeFactor;
  static final errorStatusPlaceHolderHeight = 16 * AppConfig.bubbleSizeFactor;
  static const double avatarSize = 36;
  static const notSameSenderPadding = EdgeInsets.only(left: 8.0, bottom: 4);

  static const double buttonHeight = 66;
  static List<BoxShadow> boxShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.12),
        offset: Offset(0, 0),
        blurRadius: 2,
      ),
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.16),
        offset: Offset(0, 0),
        blurRadius: 96,
      ),
    ]
        : [];
  }

  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : const Color.fromARGB(239, 36, 36, 36);
  }
}