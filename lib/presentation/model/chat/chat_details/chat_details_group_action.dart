import 'package:flutter/widgets.dart';

abstract class ChatDetailsGroupAction {
  String getTitle(BuildContext context);
  IconData get icon;
  VoidCallback get onTap;
  void Function(BuildContext context, TapDownDetails details)? get onTapDown;
}
