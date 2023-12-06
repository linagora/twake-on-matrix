import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PopupMenuItemModel with EquatableMixin {
  final String text;

  final String? imagePath;

  final IconData? iconData;

  final Color? color;

  final void Function({Object? extra})? onTap;

  PopupMenuItemModel({
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
