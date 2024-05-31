import 'package:flutter/material.dart';

class ContextMenuAction {
  String name;
  IconData? icon;
  String? imagePath;
  Color? colorIcon;
  double? iconSize;
  TextStyle? styleName;
  EdgeInsets? padding;

  ContextMenuAction({
    required this.name,
    this.icon,
    this.imagePath,
    this.colorIcon,
    this.iconSize,
    this.styleName,
    this.padding,
  });
}
