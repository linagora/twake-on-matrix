import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension ValueNotifierExtension<bool> on ValueNotifier {
  void toggle() {
    try {
      value = !value;
    } on FlutterError catch (e) {
      Logs().e('ValueNotifierExtension::toggle(): $e');
    }
  }
}
