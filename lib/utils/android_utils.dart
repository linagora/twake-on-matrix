import 'package:twake_chat/utils/platform_infos.dart';
import 'package:flutter/widgets.dart';

class AndroidUtils {
  const AndroidUtils._();

  static bool isNavigationButtonsEnabled({
    required EdgeInsets systemGestureInsets,
  }) {
    return PlatformInfos.isAndroid && systemGestureInsets.left == 0;
  }
}
