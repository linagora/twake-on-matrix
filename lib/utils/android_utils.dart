import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AndroidUtils {
  const AndroidUtils._();

  static bool isNavigationButtonsEnabled({
    required EdgeInsets systemGestureInsets,
  }) {
    return !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        systemGestureInsets.left == 0;
  }
}
