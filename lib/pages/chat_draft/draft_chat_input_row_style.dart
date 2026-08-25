import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class DraftChatInputRowStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static EdgeInsets inputBarPadding({
    required BuildContext context,
    required bool isKeyboardVisible,
  }) {
    final leftRightPadding = responsive.isMobile(context) ? 8.0 : 16.0;
    double bottomPadding;

    if (responsive.isMobile(context)) {
      bottomPadding = isKeyboardVisible ? 0.0 : 16.0;
    } else {
      bottomPadding = 0.0;
    }

    return EdgeInsets.only(
      left: leftRightPadding,
      right: leftRightPadding,
      bottom: bottomPadding,
    );
  }
}
