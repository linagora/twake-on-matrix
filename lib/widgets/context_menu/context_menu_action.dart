import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ContextMenuAction extends Equatable {
  final String name;
  final IconData? icon;
  final String? imagePath;
  final Color? colorIcon;
  final double? iconSize;
  final TextStyle? styleName;
  final EdgeInsets? padding;

  const ContextMenuAction({
    required this.name,
    this.icon,
    this.imagePath,
    this.colorIcon,
    this.iconSize,
    this.styleName,
    this.padding,
  });

  @override
  List<Object?> get props => [
        name,
        icon,
        imagePath,
        colorIcon,
        iconSize,
        styleName,
        padding,
      ];
}
