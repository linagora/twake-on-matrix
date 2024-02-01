import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ContextMenuItemModel with EquatableMixin {
  final String text;

  final String? imagePath;

  final IconData? iconData;

  final Color? color;

  final void Function()? onTap;

  ContextMenuItemModel({
    required this.text,
    this.imagePath,
    this.iconData,
    this.color,
    this.onTap,
  });

  @override
  List<Object?> get props => [
        text,
        imagePath,
        iconData,
        color,
        onTap,
      ];
}
