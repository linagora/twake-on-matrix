import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class DisplayImageInfo with EquatableMixin {
  final Size size;
  final bool hasBlur;

  DisplayImageInfo({
    required this.size,
    required this.hasBlur,
  });

  @override
  List<Object?> get props => [size, hasBlur];
}
