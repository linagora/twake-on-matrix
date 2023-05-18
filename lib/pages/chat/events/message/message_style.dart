import 'package:fluffychat/config/app_config.dart';
import 'package:flutter/material.dart';

class MessageStyle {
  static final bubbleBorderRadius = BorderRadius.circular(20);
  static final errorStatusPlaceHolderWidth = 16 * AppConfig.bubbleSizeFactor;
  static final errorStatusPlaceHolderHeight = 16 * AppConfig.bubbleSizeFactor;
  static const double avatarSize = 36;
  static const double fontSize = 15;
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

  static int get messageFlexMobile => 7;
  static int get replyIconFlexMobile => 2;

  static TextStyle? displayTime(BuildContext context) 
    => Theme.of(context).textTheme.bodySmall?.merge(
      TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.4,
      )
    );

  static double get forwardContainerSize => 40.0;
  static Color? forwardColorBackground(context) => Theme.of(context).colorScheme.surfaceTint.withOpacity(0.08);
}