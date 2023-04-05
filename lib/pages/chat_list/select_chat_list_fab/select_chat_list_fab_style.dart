import 'package:flutter/material.dart';

class SelectChatListFabStyle {
  static const double buttonWidth = 263;
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

  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(32));
  static const EdgeInsets innerPadding = EdgeInsets.symmetric(horizontal: 0, vertical: 8);
  static const double fabButtonSize = 56.0;
}
