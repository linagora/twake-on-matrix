import 'package:flutter/services.dart';

// Refer: https://github.com/flutter/flutter/issues/35435#issuecomment-540582796
extension RawKeyEventExtension on RawKeyEvent {
  bool get isEnter {
    if (this is! RawKeyUpEvent) {
      return false;
    }
    if (logicalKey == LogicalKeyboardKey.enter) {
      return true;
    }
    if (data is RawKeyEventDataWeb) {
      if ((data as RawKeyEventDataWeb).keyLabel == 'Enter') {
        return true;
      }
    }
    if (data is RawKeyEventDataAndroid) {
      if ((data as RawKeyEventDataAndroid).keyCode == 13) {
        return true;
      }
    }
    return false;
  }
}
