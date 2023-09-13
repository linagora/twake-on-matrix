import 'package:flutter/material.dart';

extension ValueNotifierExtension<bool> on ValueNotifier {
  void toggle() => value = !value;
}
