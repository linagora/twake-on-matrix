import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class ContextMenuPosition extends Equatable {
  final Alignment alignment;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  const ContextMenuPosition({
    required this.alignment,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  @override
  List<Object?> get props => [alignment, left, top, right, bottom];
}
